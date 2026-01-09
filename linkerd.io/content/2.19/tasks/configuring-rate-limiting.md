---
title: Configuring Rate Limiting
description: Using HTTP local rate limiting to protect a service
---

In this guide, we'll walk you through deploying an `HTTPLocalRateLimitPolicy`
resource to rate-limit the traffic to a given service.

For more information about Linkerd's rate limiting check the
[Rate Limiting feature doc](../features/rate-limiting/) and the
[HTTPLocalRateLimitPolicy reference doc](../reference/rate-limiting/).

## Prerequisites

To use this guide you'll only need a Kubernetes cluster running a Linkerd
instance. You can follow the [installing Linkerd Guide](install/).

## Setup

First inject and install the Emojivoto application, then scale-down the vote-bot
workload to avoid it interfering with our testing:

```bash
linkerd inject https://run.linkerd.io/emojivoto.yml | kubectl apply -f -
kubectl -n emojivoto scale --replicas 0 deploy/vote-bot
```

Finally, deploy a workload with an Ubuntu image, open a shell into it and
install curl:

```bash
kubectl create deployment client --image ubuntu -- bash -c "sleep infinity"
kubectl exec -it client-xxx -- bash
root@client-xxx:/# apt-get update && apt-get install -y curl
```

Leave that shell open so we can use it below when
[sending requests](#sending-requests).

## Creating an HTTPLocalRateLimitPolicy resource

We need first to create a `Server` resource pointing to the `web-svc` service.
Note that this `Server` has `accessPolicy: all-unauthenticated`, which means
that traffic is allowed by default and we don't require to declare authorization
policies associated to it:

```yaml
kubectl apply -f - <<EOF
---
apiVersion: policy.linkerd.io/v1beta3
kind: Server
metadata:
  namespace: emojivoto
  name: web-http
spec:
  accessPolicy: all-unauthenticated
  podSelector:
    matchLabels:
      app: web-svc
  port: http
  proxyProtocol: HTTP/1
EOF
```

Now we can apply the `HTTPLocalRateLimitPolicy` resource pointing to that
`Server`. For now, we'll just set a limit of 4 RPS per identity:

```yaml
kubectl apply -f - <<EOF
---
apiVersion: policy.linkerd.io/v1alpha1
kind: HTTPLocalRateLimitPolicy
metadata:
  namespace: emojivoto
  name: web-http
spec:
  targetRef:
    group: policy.linkerd.io
    kind: Server
    name: web-http
  identity:
    requestsPerSecond: 4
EOF
```

## Sending requests

In the Ubuntu shell, issue 10 concurrent requests to `web-svc.emojivoto`:

```bash
root@client-xxx:/# results=$(for i in {1..10}; do curl -s -o /dev/null -w "%{http_code}\n" "http://web-svc.emojivoto" & done; wait)
root@client-xxx:/# echo $results
200 200 200 429 429 429 429 200 429 429
```

We see that only 4 requests were allowed. The requests that got rate-limited
receive a response with a 429 HTTP status code.

### Overrides

The former client had no identity as it was deployed in the default namespace,
where workloads are not injected by default.

Now let's create a new Ubuntu workload in the emojivoto namespace, which will be
injected by default, and whose identity will be associated to the `default`
ServiceAccount in the emojivoto namespace:

```bash
kubectl -n emojivoto create deployment client --image ubuntu -- bash -c "sleep infinity"
kubectl -n emojivoto exec -it client-xxx -c ubuntu -- bash
root@client-xxx:/# apt-get update && apt-get install -y curl
```

Before issuing requests, let's expand the `HTTPLocalRateLimitPolicy` resource,
adding an override for this specific client, that'll allow it to issue requests
up to 6 RPS:

```yaml
kubectl apply -f - <<EOF
---
apiVersion: policy.linkerd.io/v1alpha1
kind: HTTPLocalRateLimitPolicy
metadata:
  namespace: emojivoto
  name: web-http
spec:
  targetRef:
    group: policy.linkerd.io
    kind: Server
    name: web-http
  identity:
    requestsPerSecond: 4
  overrides:
  - requestsPerSecond: 6
    clientRefs:
    - kind: ServiceAccount
      namespace: emojivoto
      name: default
EOF
```

And finally back in the shell we execute the requests:

```bash
root@client-xxx:/# results=$(for i in {1..10}; do curl -s -o /dev/null -w "%{http_code}\n" "http://web-svc.emojivoto" & done; wait)
root@client-xxx:/# echo $results
429 429 429 429 200 200 200 200 200 200
```

We see that now 6 requests were allowed. If we tried again with the former
client, we could verify we would still be allowed to 4 requests only.
