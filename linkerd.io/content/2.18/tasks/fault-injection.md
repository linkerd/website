---
title: Injecting Faults
description: Practice chaos engineering by injecting faults into services with Linkerd.
---

It is easy to inject failures into applications by using the
[HTTPRoute](../reference/httproute/) resource to redirect a percentage of
traffic to a specific backend. This backend is completely flexible and can
return whatever responses you want - 500s, timeouts or even crazy payloads.

The [books demo](books/) is a great way to show off this behavior. The
overall topology looks like:

![Topology](/docs/images/books/topology.png "Topology")

In this guide, you will split some of the requests from `webapp` to `books`.
Most requests will end up at the correct `books` destination, however some of
them will be redirected to a faulty backend. This backend will return 500s for
every request and inject faults into the `webapp` service. No code changes are
required and as this method is configuration driven, it is a process that can be
added to integration tests and CI pipelines. If you are really living the chaos
engineering lifestyle, fault injection could even be used in production.

## Prerequisites

To use this guide, you'll need a Kubernetes cluster running:

- Linkerd and Linkerd-Viz. If you haven't installed these yet, follow the
  [Installing Linkerd Guide](install/).

## Setup the service

First, add the [books](books/) sample application to your cluster:

```bash
kubectl create ns booksapp && \
  linkerd inject https://run.linkerd.io/booksapp.yml | \
  kubectl -n booksapp apply -f -
```

As this manifest is used as a demo elsewhere, it has been configured with an
error rate. To show how fault injection works, the error rate needs to be
removed so that there is a reliable baseline. To increase success rate for
booksapp to 100%, run:

```bash
kubectl -n booksapp patch deploy authors \
  --type='json' \
  -p='[{"op":"remove", "path":"/spec/template/spec/containers/0/env/2"}]'
```

After a little while, the stats will show 100% success rate. You can verify this
by running:

```bash
linkerd viz -n booksapp stat-inbound deploy
```

The output will end up looking at little like:

```bash
NAME     SERVER          ROUTE      TYPE  SUCCESS   RPS  LATENCY_P50  LATENCY_P95  LATENCY_P99
authors  [default]:4191  [default]        100.00%  0.20          0ms          1ms          1ms
authors  [default]:7001  [default]        100.00%  3.00          2ms         36ms         43ms
books    [default]:4191  [default]        100.00%  0.23          4ms          4ms          4ms
books    [default]:7002  [default]        100.00%  3.60          2ms          2ms          2ms
traffic  [default]:4191  [default]        100.00%  0.22          0ms          3ms          1ms
webapp   [default]:4191  [default]        100.00%  0.72          4ms          5ms          1ms
webapp   [default]:7000  [default]        100.00%  3.25          2ms          2ms         65ms
```

## Create the faulty backend

Injecting faults into booksapp requires a service that is configured to return
errors. To do this, you can start NGINX and configure it to return 500s by
running:

```bash
cat <<EOF | linkerd inject - | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: error-injector
  namespace: booksapp
data:
 nginx.conf: |-
    events {}
    http {
        server {
          listen 8080;
            location / {
                return 500;
            }
        }
    }
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: error-injector
  namespace: booksapp
  labels:
    app: error-injector
spec:
  selector:
    matchLabels:
      app: error-injector
  replicas: 1
  template:
    metadata:
      labels:
        app: error-injector
    spec:
      containers:
        - name: nginx
          image: nginx:alpine
          volumeMounts:
            - name: nginx-config
              mountPath: /etc/nginx/nginx.conf
              subPath: nginx.conf
      volumes:
        - name: nginx-config
          configMap:
            name: error-injector
---
apiVersion: v1
kind: Service
metadata:
  name: error-injector
  namespace: booksapp
spec:
  ports:
  - name: service
    port: 8080
  selector:
    app: error-injector
EOF
```

## Inject faults

With booksapp and NGINX running, it is now time to partially split the traffic
between an existing backend, `books`, and the newly created
`error-injector`. This is done by adding an
[HTTPRoute](../reference/httproute/) configuration to your cluster:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: policy.linkerd.io/v1beta2
kind: HTTPRoute
metadata:
  name: error-split
  namespace: booksapp
spec:
  parentRefs:
    - name: books
      kind: Service
      group: core
      port: 7002
  rules:
    - backendRefs:
      - name: books
        port: 7002
        weight: 90
      - name: error-injector
        port: 8080
        weight: 10
EOF
```

{{< note >}}
Two versions of the HTTPRoute resource may be used with Linkerd:

- The upstream version provided by the Gateway API, with the
  `gateway.networking.k8s.io` API group
- A Linkerd-specific CRD provided by Linkerd, with the `policy.linkerd.io` API
  group

The two HTTPRoute resource definitions are similar, but the Linkerd version
implements experimental features not yet available with the upstream Gateway API
resource definition. See [the HTTPRoute reference
documentation](../reference/httproute/#linkerd-and-gateway-api-httproutes)
for details.
{{< /note >}}

When Linkerd sees traffic going to the `books` service, it will send 9/10
requests to the original service and 1/10 to the error injector. You can see
what this looks like by running `stat-outbound`:

```bash
linkerd viz stat-outbound -n booksapp deploy/webapp
NAME    SERVICE       ROUTE        TYPE       BACKEND              SUCCESS   RPS  LATENCY_P50  LATENCY_P95  LATENCY_P99  TIMEOUTS  RETRIES
webapp  authors:7001  [default]                                     98.44%  4.28         25ms         47ms         50ms     0.00%    0.00%
                      └────────────────────►  authors:7001          98.44%  4.28         15ms         42ms         48ms     0.00%
webapp  books:7002    error-split  HTTPRoute                        87.76%  7.22         26ms         49ms        333ms     0.00%    0.00%
                      ├────────────────────►  books:7002           100.00%  6.33         14ms         42ms         83ms     0.00%
                      └────────────────────►  error-injector:8080    0.00%  0.88         12ms         24ms         25ms     0.00%
```

We can see here that 0.88 requests per second are being sent to the error
injector and that the overall success rate is 87.76%.

## Cleanup

To remove everything in this guide from your cluster, run:

```bash
kubectl delete ns booksapp
```
