---
title: Retries
description: How Linkerd implements retries.
---

Linkerd can be configured to automatically retry requests when it receives a
failed response instead of immediately returning that failure to the client.
This is valuable tool for improving success rate in the face of transient
failures.

Retries are a client-side behavior, and are therefore performed by the
outbound side of the Linkerd proxy.[^1] If retries are configured on an
HTTPRoute or GRPCRoute with multiple backends, each retry of a request can
potentially get sent to a different backend. If a request has a body larger than
64KiB then it will not be retried.

## Configuring Retries

Retries are configured by a set of annotations which can be set on a Kubernetes
Service resource or on a HTTPRoute or GRPCRoute which has a Service as a parent.
Client proxies will then retry failed requests to that Service or route. If any
retry configuration annotations are present on a route resource, they override
all retry configuration annotations on the parent Service.

{{< warning >}}
Retries configured in this way are **incompatible with ServiceProfiles**. If a
[ServiceProfile](../features/service-profiles/) is defined for a Service,
proxies will use the ServiceProfile retry configuration and ignore any retry
annotations.
{{< /warning >}}

+ `retry.linkerd.io/http`: A comma separated list of HTTP response codes which
should be retried. Each element of the list may be
  + `xxx` to retry a single response code (for example, `"504"` -- remember,
    annotation values must be strings!);
  + `xxx-yyy` to retry a range of response codes (for example, `500-504`);
  + `gateway-error` to retry response codes 502-504; or
  + `5xx` to retry all 5XX response codes.
This annotation is not valid on GRPCRoute resources.
+ `retry.linkerd.io/grpc`: A comma seperated list of gRPC status codes which
should be retried. Each element of the list may be
  + `cancelled`
  + `deadline-exceeded`
  + `internal`
  + `resource-exhausted`
  + `unavailable`
This annotation is not valid on HTTPRoute resources.
+ `retry.linkerd.io/limit`: The maximum number of times a request can be
retried. If unspecified, the default is `1`.
+ `retry.linkerd.io/timeout`: A retry timeout after which a request is cancelled
and retried (if the retry limit has not yet been reached). If unspecified, no
retry timeout is applied. Units must be specified in this value e.g. `5s` or
`200ms`.

## Examples

```yaml
kind: HTTPRoute
apiVersion: gateway.networking.k8s.io/v1beta1
metadata:
  name: schlep-default
  namespace: schlep
  annotations:
    retry.linkerd.io/http: 5xx
    retry.linkerd.io/limit: "2"
    retry.linkerd.io/timeout: 300ms
spec:
  parentRefs:
    - name: schlep
      kind: Service
      group: core
      port: 80
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: "/"
```

```yaml
kind: GRPCRoute
apiVersion: gateway.networking.k8s.io/v1alpha2
metadata:
  name: schlep-default
  namespace: schlep
  annotations:
    retry.linkerd.io/grpc: internal
    retry.linkerd.io/limit: "2"
    retry.linkerd.io/timeout: 400ms
spec:
  parentRefs:
    - name: schlep
      kind: Service
      group: core
      port: 8080
  rules:
    - matches:
        - method:
            type: Exact
            service: schlep.Schlep
            method: Get
```

[^1]: The part of the proxy which handles connections from within the pod to the
    rest of the cluster.
