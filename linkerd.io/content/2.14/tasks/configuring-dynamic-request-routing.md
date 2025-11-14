---
title: Configuring Dynamic Request Routing
description: Configuring HTTPRoute resources to perform dynamic request routing.
---

## Prerequisites

To use this guide, you'll need to have Linkerd installed on your cluster. Follow
the [Installing Linkerd Guide](install/) if you haven't already done this (make
sure you have at least linkerd stable-2.13.0 or edge-23.3.2).

You also need to have the [Helm](https://helm.sh/docs/intro/quickstart/) CLI
installed.

## HTTPRoute for Dynamic Request Routing

With dynamic request routing, you can route HTTP traffic based on the contents
of request headers. This can be useful for performing things like A/B testing
and many other strategies for traffic management.

In this tutorial, we'll make use of the
[podinfo](https://github.com/stefanprodan/podinfo) project to showcase dynamic
request routing, by deploying in the cluster two backend and one frontend
podinfo pods. Traffic will flow to just one backend, and then we'll switch
traffic to the other one just by adding a header to the frontend requests.

## Setup

First we create the `test` namespace, annotated by linkerd so all pods that get
created there get injected with the linkerd proxy:

```bash
kubectl create ns test --dry-run=client -o yaml \
  | linkerd inject - \
  | kubectl apply -f -
```

Then we add podinfo's Helm repo, and install two instances of it. The first one
will respond with the message "`A backend`", the second one with "`B backend`".

```bash
helm repo add podinfo https://stefanprodan.github.io/podinfo
helm install backend-a -n test \
  --set ui.message='A backend' podinfo/podinfo
helm install backend-b -n test \
  --set ui.message='B backend' podinfo/podinfo
```

We add another podinfo instance which will forward requests only to the first
backend instance `backend-a`:

```bash
helm install frontend -n test \
  --set backend=http://backend-a-podinfo:9898/env podinfo/podinfo
```

Once those three pods are up and running, we can port-forward requests from our
local machine to the frontend:

```bash
kubectl -n test port-forward svc/frontend-podinfo 9898 &
```

## Sending Requests

Requests to `/echo` on port 9898 to the frontend pod will get forwarded the pod
pointed by the Service `backend-a-podinfo`:

```bash
$ curl -sX POST localhost:9898/echo \
  | grep -o 'PODINFO_UI_MESSAGE=. backend'

PODINFO_UI_MESSAGE=A backend
```

## Introducing HTTPRoute

Let's apply the following [`HTTPRoute`] resource to enable header-based routing:

```yaml
cat <<EOF | kubectl -n test apply -f -
apiVersion: policy.linkerd.io/v1beta2
kind: HTTPRoute
metadata:
  name: backend-router
  namespace: test
spec:
  parentRefs:
    - name: backend-a-podinfo
      kind: Service
      group: core
      port: 9898
  rules:
    - matches:
      - headers:
        - name: "x-request-id"
          value: "alternative"
      backendRefs:
        - name: "backend-b-podinfo"
          port: 9898
    - backendRefs:
      - name: "backend-a-podinfo"
        port: 9898
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
resource definition. See
[the HTTPRoute reference documentation](../reference/httproute/#linkerd-and-gateway-api-httproutes)
for details.

{{< /note >}}

In `parentRefs` we specify the resources we want this [`HTTPRoute`] instance to
act on. So here we point to the `backend-a-podinfo` Service on the
[`HTTPRoute`]'s namespace (`test`), and also specify the Service port number
(not the Service's target port).

{{< warning >}}

**Outbound [`HTTPRoute`](../features/httproute/)s and
[`ServiceProfile`](../features/service-profiles/)s provide overlapping
configuration.** For backwards-compatibility reasons, a `ServiceProfile` will
take precedence over `HTTPRoute`s which configure the same Service. If a
`ServiceProfile` is defined for the parent Service of an `HTTPRoute`, proxies
will use the `ServiceProfile` configuration, rather than the `HTTPRoute`
configuration, as long as the `ServiceProfile` exists.

{{< /warning >}}

Next, we give a list of rules that will act on the traffic hitting that Service.

The first rule contains two entries: `matches` and `backendRefs`.

In `matches` we list the conditions that this particular rule has to match. One
matches suffices to trigger the rule (conditions are OR'ed). Inside, we use
`headers` to specify a match for a particular header key and value. If multiple
headers are specified, they all need to match (matchers are AND'ed). Note we can
also specify a regex match on the value by adding a `type: RegularExpression`
field. By not specifying the type like we did here, we're performing a match of
type `Exact`.

In `backendRefs` we specify the final destination for requests matching the
current rule, via the Service's `name` and `port`.

Here we're specifying we'd like to route to `backend-b-podinfo` all the requests
having the `x-request-id: alterrnative` header. If the header is not present,
the engine fall backs to the last rule which has no `matches` entries and points
to the `backend-a-podinfo` Service.

The previous requests should still reach `backend-a-podinfo` only:

```bash
$ curl -sX POST localhost:9898/echo \
  | grep -o 'PODINFO_UI_MESSAGE=. backend'

PODINFO_UI_MESSAGE=A backend
```

But if we add the "`x-request-id: alternative`" header they get routed to
`backend-b-podinfo`:

```bash
$ curl -sX POST \
  -H 'x-request-id: alternative' \
  localhost:9898/echo \
  | grep -o 'PODINFO_UI_MESSAGE=. backend'

PODINFO_UI_MESSAGE=B backend
```

### To Keep in Mind

Note that you can use any header you like, but for this to work the frontend has
to forward it. "`x-request-id`" is a common header used in microservices, that
is explicitly forwarded by podinfo, and that's why we chose it.

Also, keep in mind the linkerd proxy handles this on the client side of the
request (the frontend pod in this case) and so that pod needs to be injected,
whereas the destination pods don't require to be injected. But of course the
more workloads you have injected the better, to benefit from things like easy
mTLS setup and all the other advantages that linkerd brings to the table!

[`HTTPRoute`]: ../features/httproute/
