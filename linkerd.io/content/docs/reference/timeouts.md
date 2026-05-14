---
title: Timeouts
description: How Linkerd implements timeouts.
---

Linkerd can be configured with timeouts to limit the maximum amount of time on a
request before aborting.

Timeouts are a client-side behavior, and are therefore performed by the outbound
side of the Linkerd proxy.[^1] Note that timeouts configured in this way are not
retryable -- if these timeouts are reached, the request will not be retried.
Retryable timeouts can be configured as part of [retry configuration](retries/).

## Configuring Timeouts

Timeous are configured by a set of annotations which can be set on a Kubernetes
Service resource or on a HTTPRoute or GRPCRoute which has a Service as a parent.
Client proxies will then fail requests to that Service or route once they exceed
the timeout. If any timeout configuration annotations are present on a route
resource, they override all timeout configuration annotations on the parent
Service.

{{< warning >}}

Timeouts configured in this way are **incompatible with ServiceProfiles**. If a
[ServiceProfile](../features/service-profiles/) is defined for a Service,
proxies will use the ServiceProfile timeout configuration and ignore any timeout
annotations.

{{< /warning >}}

- `timeout.linkerd.io/request`: The maximum amount of time a full
  request-response stream is in flight.
- `timeout.linkerd.io/response`: The maximum amount of time a backend response
  may be in-flight.
- `timeout.linkerd.io/idle`: The maximum amount of time a stream may be idle,
  regardless of its state.

If the
[request timeout](https://gateway-api.sigs.k8s.io/api-types/httproute/#timeouts-optional)
field is set on an HTTPRoute resource, it will be used as the
`timeout.linkerd.io/request` timeout. However, if both the field and the
annotation are specified, the annotation will take priority.

## Examples

```yaml
kind: HTTPRoute
apiVersion: gateway.networking.k8s.io/v1beta1
metadata:
  name: schlep-default
  namespace: schlep
  annotations:
    timeout.linkerd.io/request: 2s
    timeout.linkerd.io/response: 1s
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

[^1]:
    The part of the proxy which handles connections from within the pod to the
    rest of the cluster.
