---
title: Managing egress traffic
---

In this guide, we'll walk you through an example of
[egress traffic management](../features/egress): visualizing, applying policies
and implementing advanced routing configuration for traffic that is targeted to
destinations that reside outside of the cluster.

{{< warning >}}

No service mesh can provide a strong security guarantee about egress traffic by
itself; for example, a malicious actor could bypass the Linkerd sidecar - and
thus Linkerd's egress controls - entirely. Fully restricting egress traffic in
the presence of arbitrary applications thus typically requires a more
comprehensive approach.

{{< /warning >}}

## Visualizing egress traffic

In order to be able to capture egress traffic and apply policies to it we will
make use of the `EgressNetwork` CRD. This CRD is namespace scoped - it applies
to clients in the local namespace unless it is created in the globally
configured egress namespace. For now, let's create an `egress-test` namespace
and add a single `EgressNetwork` to it.

```bash
kubectl create ns egress-test
kubectl apply -f - <<EOF
apiVersion: policy.linkerd.io/v1alpha1
kind: EgressNetwork
metadata:
  namespace: egress-test
  name: all-egress-traffic
spec:
  trafficPolicy: Allow
EOF
```

This is enough to visualize egress traffic going through the system. In order to
do so, you can deploy a simple curl container and start hitting an external to
the cluster service:

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: client
  namespace: egress-test
  annotations:
    linkerd.io/inject: enabled
    config.linkerd.io/proxy-metrics-hostname-labels: "true"
spec:
  containers:
  - name: client
    image: curlimages/curl
    command:
      - "sh"
      - "-c"
      - "sleep infinity"
EOF
```

Now SSH into the client container and start generating some external traffic:

```bash
kubectl -n egress-test exec -it client -c client -- sh
$ while sleep 1; do curl -s http://httpbin.org/get ; done
```

In a separate shell, you can use the Linkerd diagnostics command to visualize
the traffic.

```bash
linkerd dg proxy-metrics -n egress-test po/client | grep outbound_http_route_request_statuses_total

outbound_http_route_request_statuses_total{
  parent_group="policy.linkerd.io",
  parent_kind="EgressNetwork",
  parent_namespace="egress-test",
  parent_name="all-egress-traffic",
  parent_port="80",
  parent_section_name="",
  route_group="",
  route_kind="default",
  route_namespace="",
  route_name="http-egress-allow",
  hostname="httpbin.org",
  http_status="200",
  error=""
} 697
```

{{< note >}}

Outbound metrics do not include the hostname by default. See
[Hostnames in metrics](#hostnames-in-metrics) for details and how to include
them like in the example above.

{{< /note >}}

Notice that these raw metrics allow you to quickly identify egress traffic
targeted towards different destinations simply by querying for `parent_kind` of
type `EgressNetwork`. For now all traffic is allowed and we are simply observing
it. We can also observe that because our `EgressNetwork` default traffic policy
is set to `Allow`, the default http route is named as `http-egress-allow`. This
is a placeholder route that is being populated automatically by the Linkerd
controller.

### Hostnames in metrics

By default, outbound metrics do not include the hostname in the `hostname`
label, both for cluster-local and egress traffic. This is a safe default for
workloads that address a large number of discrete destination hostnames to
prevent high cardinality in outbound metrics.

If this isn't a concern for your workloads, the hostname metrics can be enabled
on a per-workload or per-namespace basis by setting the
`config.linkerd.io/proxy-metrics-hostname-labels` annotation to `true` on a
single pod or namespace, respectively.

Hostname metrics can also be enabled cluster-wide through the values in
`linkerd install`:

```bash
# With a single value
linkerd install --set proxy.metrics.hostnameLabels=true | kubectl apply -f -

# Or ith a values.yaml file
#
# <values.yaml>
proxy:
  metrics:
    hostnameLabels: true

linkerd install --values=values.yaml | kubectl apply -f -
```

{{< note >}}

The rest of the examples on this page assume that the hostname metrics have been
enabled, for clarity.

{{< /note >}}

## Restricting egress traffic

After you have used metrics in order to compose a picture of your egress
traffic, you can start applying policies that allow only some of it to go
through. Let's update our `EgressNetwork` and change its `trafficPolicy` to
`Deny`:

```bash
kubectl patch egressnetwork -n egress-test all-egress-traffic \
  -p '{"spec":{"trafficPolicy": "Deny"}}' --type=merge
```

Now, you should start observing failed requests from your client container.
Furthermore, looking at metrics we can observe the following result:

```bash
outbound_http_route_request_statuses_total{
  parent_group="policy.linkerd.io",
  parent_kind="EgressNetwork",
  parent_namespace="egress-test",
  parent_name="all-egress-traffic",
  parent_port="80",
  parent_section_name="",
  route_group="",
  route_kind="default",
  route_namespace="",
  route_name="http-egress-deny",
  hostname="httpbin.org",
  http_status="403",
  error=""
} 45
```

We can clearly observe now that the traffic targets the same parent but the name
of the route is now `http-egress-deny`. Furthermore, the `http_status` is `403`
or `Forbidden`. By changing the traffic policy to `Deny`, we have forbidden all
egress traffic originating from the local namespace. In order to allow some of
it, we can make use of the Gateway API types. Assume that you want to allow
traffic to `httpbin.org` but only for requests that target the `/get` endpoint.
For that purpose we need to create the following `HTTPRoute`:

```bash
kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: httpbin-get
  namespace: egress-test
spec:
  parentRefs:
    - name: all-egress-traffic
      kind: EgressNetwork
      group: policy.linkerd.io
      namespace: egress-test
      port: 80
  rules:
    - matches:
      - path:
          value: "/get"
EOF
```

We can see that traffic is now flowing again and if we look at metrics we will
be able to see that this happens through the `httpbin-get` route.

```bash
outbound_http_route_request_statuses_total{
  parent_group="policy.linkerd.io",
  parent_kind="EgressNetwork",
  parent_namespace="egress-test",
  parent_name="all-egress-traffic",
  parent_port="80",
  parent_section_name="",
  route_group="gateway.networking.k8s.io",
  route_kind="HTTPRoute",
  route_namespace="egress-test",
  route_name="httpbin-get",
  hostname="httpbin.org",
  http_status="200",
  error=""
} 63
```

Interestingly enough though, if we go back to our client shell and we try to
initiate HTTPS traffic to the same service, it will not be allowed:

```bash
~ $ curl -v https://httpbin.org/get
curl: (35) TLS connect error: error:00000000:lib(0)::reason(0)
```

This is the case because our current configuration only allows plaintext HTTP
traffic to go through the system. We can additionally allow HTTPS traffic, by
using the Gateway API `TLSRoute`:

```bash
kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: TLSRoute
metadata:
  name: tls-egress
  namespace: egress-test
spec:
  hostnames:
  - httpbin.org
  parentRefs:
  - name: all-egress-traffic
    kind: EgressNetwork
    group: policy.linkerd.io
    namespace: egress-test
    port: 443
  rules:
  - backendRefs:
    - kind: EgressNetwork
      group: policy.linkerd.io
      name: all-egress-traffic
EOF
```

This fixes the problem and we can see HTTPS requests to the external service
succeeding reflected in the metrics:

```bash
linkerd dg proxy-metrics -n egress-test po/client | grep outbound_tls_route_open_total

outbound_tls_route_open_total{
  parent_group="policy.linkerd.io",
  parent_kind="EgressNetwork",
  parent_namespace="egress-test",
  parent_name="all-egress-traffic",
  parent_port="443",
  parent_section_name="",
  route_group="gateway.networking.k8s.io",
  route_kind="TLSRoute",
  route_namespace="egress-test",
  route_name="tls-egress",
  hostname="httpbin.org"
} 2
```

This configuration allows traffic to `httpbin.org` only. In order to apply
policy decisions for TLS connections, the proxy parses the SNI extension header
from the `ClientHello` of the TLS session and uses that as the target hostname
identifier. This means that if we try to initiate a request to `github.com` from
our client, we will see the proxy eagerly closing the connection because it is
not forbidden by our current policy configuration:

```bash
linkerd dg proxy-metrics -n egress-test po/client | grep outbound_tls_route_close_total

outbound_tls_route_close_total{
  parent_group="policy.linkerd.io",
  parent_kind="EgressNetwork",
  parent_namespace="egress-test",
  parent_name="all-egress-traffic",
  parent_port="443",
  parent_section_name="",
  route_group="",
  route_kind="default",
  route_namespace="",
  route_name="tls-egress-deny",
  hostname="github.com",
  error="forbidden"
} 1
```

In a similar fashion we can use the other Gateway API route types such as
`GRPCRoute` and TCPRoute to shape traffic that is captured by an `EgressNetwork`
primitive. All these traffic types come with their corresponding set of
route-based metrics that describe how traffic flows through the system and what
policy decisions have been made.

## Redirecting egress traffic back to the cluster

Using the Gateway API route types to model egress traffic allows us to implement
some more advanced routing configurations. Assume that we want to apply the
following rules:

- unencrypted HTTP traffic can only target `httpbin.org/get` an no other
  endpoints
- encrypted HTTPs traffic is allowed to all destinations
- all other unencrypted HTTP traffic need to be redirected to an internal
  service

To begin with, let's create our internal service to which traffic should be
redirected:

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: internal-egress
  namespace: egress-test
spec:
  type: ClusterIP
  selector:
    app: internal-egress
  ports:
  - port: 80
    protocol: TCP
    name: one
---
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: egress-test
  name: internal-egress
spec:
  replicas: 1
  selector:
    matchLabels:
      app: internal-egress
  template:
    metadata:
      labels:
        app: internal-egress
      annotations:
        linkerd.io/inject: enabled
    spec:
      containers:
        - name: legacy-app
          image: buoyantio/bb:v0.0.5
          command: [ "sh", "-c"]
          args:
          - "/out/bb terminus --h1-server-port 80 --response-text 'You cannot go there right now' --fire-and-forget"
          ports:
            - name: http-port
              containerPort: 80
EOF
```

In order to allow the first rule, we need to create an `HTTPRoute` that looks
like this:

```bash
kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: httpbin-get
  namespace: egress-test
spec:
  parentRefs:
    - name: all-egress-traffic
      kind: EgressNetwork
      group: policy.linkerd.io
      namespace: egress-test
      port: 80
  rules:
    - matches:
      - path:
          value: "/get"
EOF
```

To allow all tls traffic, we need the following `TLSRoute`:

```bash
kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: TLSRoute
metadata:
  name: tls-egress
  namespace: egress-test
spec:
  parentRefs:
  - name: all-egress-traffic
    kind: EgressNetwork
    group: policy.linkerd.io
    namespace: egress-test
    port: 443
  rules:
  - backendRefs:
    - kind: EgressNetwork
      group: policy.linkerd.io
      name: all-egress-traffic
EOF
```

Finally to redirect the rest of the plaintext HTTP traffic to the internal
service, we create an `HTTPRoute` with a custom backend being the internal
service:

```bash
kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: unencrypted-http
  namespace: egress-test
spec:
  parentRefs:
    - name: all-egress-traffic
      kind: EgressNetwork
      group: policy.linkerd.io
      namespace: egress-test
      port: 80
  rules:
  - backendRefs:
    - kind: Service
      name: internal-egress
      port: 80
EOF
```

Now let's verify all works as expected:

```bash
# plaintext traffic goes as expected to the /get path
$ curl  http://httpbin.org/get
{
  "args": {},
  "headers": {
    "Accept": "*/*",
    "Host": "httpbin.org",
    "User-Agent": "curl/8.11.0",
    "X-Amzn-Trace-Id": "Root=1-674599d4-77a473943844e9e31844b48e"
  },
  "origin": "51.116.126.217",
  "url": "http://httpbin.org/get"
}

# encrypted traffic can target all paths and hosts
$ curl  https://httpbin.org/ip
{
  "origin": "51.116.126.217"
}


# arbitrary unencrypted traffic goes to the internal service
$ curl http://google.com
{
  "requestUID": "in:http-sid:terminus-grpc:-1-h1:80-190120723",
  "payload": "You cannot go there right now"}
}
```

## Cleanup

In order to clean everything up, simply delete the namespace:
`kubectl delete ns egress-test`.
