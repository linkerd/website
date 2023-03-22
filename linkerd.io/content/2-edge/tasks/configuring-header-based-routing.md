+++
title = "Configuring Header-Based Routing"
description = "Configuring HTTPRoute resources to perform header-based routing."
+++

## Prerequisites

To use this guide, you'll need to have Linkerd installed on your cluster. Follow
the [Installing Linkerd Guide](../install/) if you haven't already done this
(make sure you have at least linkerd stable-2.13.0 or edge-23.3.2).

You also need to have the [Helm](https://helm.sh/docs/intro/quickstart/) CLI
installed.

## HTTPRoute for Header-Based Routing

With header-based routing, you can route HTTP traffic based on the contents of
request headers. This can be useful for performing load-balancing, A/B testing
and many other strategies for traffic management.

In this tutorial, we'll make use of the
[podinfo](https://github.com/stefanprodan/podinfo) project to showcase
header-based routing, by deploying in the cluster two backend and one frontend
podinfo pods. Traffic will flow to just one backend, and then we'll switch
traffic to the other one just by adding a header to the frontend requests.

## Set Up

First we create the `test` namespace, annotated by linkerd so all pods that get
created there get injected with the linkerd proxy:

``` bash
kubectl create ns test --dry-run -o yaml \
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

Now we'd like to set up an HTTPRoute resource to have requests sent to the
Service `backend-a-podinfo` be forwarded to the Service `backend-b-podinfo`,
only if the "`x-request-id: alternative`" header is used.

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
to forward it. "`x-request-id`" is a common header used in microservices, that is
explicitly forwarded by podinfo, and that's why we chose it.

Also, keep in mind the linkerd proxy handles this on the client side of the
request (the frontend pod in this case) and so that pod needs to be injected,
whereas the destination pods don't require to be injected. But of course the
more workloads you have injected the better, to benefit from things like easy
mTLS setup and all the other advantages that linkerd brings to the table!
