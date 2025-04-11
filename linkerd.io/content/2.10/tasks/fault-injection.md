---
title: Injecting Faults
description: Practice chaos engineering by injecting faults into services with Linkerd.
---

It is easy to inject failures into applications by using the [Traffic Split
API](https://github.com/deislabs/smi-spec/blob/master/traffic-split.md) of the
[Service Mesh Interface](https://smi-spec.io/). TrafficSplit allows you to
redirect a percentage of traffic to a specific backend. This backend is
completely flexible and can return whatever responses you want - 500s, timeouts
or even crazy payloads.

The [books demo](../books/) is a great way to show off this behavior. The
overall topology looks like:

![Topology](/docs/images/books/topology.png "Topology")
{.center}

In this guide, you will split some of the requests from `webapp` to `books`.
Most requests will end up at the correct `books` destination, however some of
them will be redirected to a faulty backend. This backend will return 500s for
every request and inject faults into the `webapp` service. No code changes are
required and as this method is configuration driven, it is a process that can be
added to integration tests and CI pipelines. If you are really living the chaos
engineering lifestyle, fault injection could even be used in production.

## Prerequisites

To use this guide, you'll need to have Linkerd installed on your cluster, along
with its Viz extension. Follow the [Installing Linkerd Guide](../install/)
if you haven't already done this.

## Setup the service

First, add the [books](../books/) sample application to your cluster:

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
linkerd viz -n booksapp stat deploy
```

The output will end up looking at little like:

```bash
NAME      MESHED   SUCCESS      RPS   LATENCY_P50   LATENCY_P95   LATENCY_P99   TCP_CONN
authors      1/1   100.00%   7.1rps           4ms          26ms          33ms          6
books        1/1   100.00%   8.6rps           6ms          73ms          95ms          6
traffic      1/1         -        -             -             -             -          -
webapp       3/3   100.00%   7.9rps          20ms          76ms          95ms          9
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
`error-injector`. This is done by adding a
[TrafficSplit](https://github.com/deislabs/smi-spec/blob/master/traffic-split.md)
configuration to your cluster:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: split.smi-spec.io/v1alpha1
kind: TrafficSplit
metadata:
  name: error-split
  namespace: booksapp
spec:
  service: books
  backends:
  - service: books
    weight: 900m
  - service: error-injector
    weight: 100m
EOF
```

When Linkerd sees traffic going to the `books` service, it will send 9/10
requests to the original service and 1/10 to the error injector. You can see
what this looks like by running `stat` and filtering explicitly to just the
requests from `webapp`:

```bash
linkerd viz -n booksapp routes deploy/webapp --to service/books
```

Unlike the previous `stat` command which only looks at the requests received by
servers, this `routes` command filters to all the requests being issued by
`webapp` destined for the `books` service itself. The output should show a 90%
success rate:

```bash
ROUTE       SERVICE   SUCCESS      RPS   LATENCY_P50   LATENCY_P95   LATENCY_P99
[DEFAULT]     books    90.08%   2.0rps           5ms          69ms          94ms
```

{{< note >}}
In this instance, you are looking at the *service* instead of the deployment. If
you were to run this command and look at `deploy/books`, the success rate would
still be 100%. The reason for this is that `error-injector` is a completely
separate deployment and traffic is being shifted at the service level. The
requests never reach the `books` pods and are instead rerouted to the error
injector's pods.
{{< /note >}}

## Cleanup

To remove everything in this guide from your cluster, run:

```bash
kubectl delete ns booksapp
```
