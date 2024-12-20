---
title: Gateway API HTTPRoutes
description: Reference guide to Gateway API HTTPRoutes resources.
---

<!-- markdownlint-disable-file blanks-around-tables -->
<!-- markdownlint-disable-file table-column-count -->
<!-- markdownlint-disable-file table-pipe-style -->

## Linkerd and Gateway API HTTPRoutes

Linkerd supports the Kubernetes Gateway API alongside its own traffic management
API. The Gateway API serves as the upstream for Linkerd's HTTPRoute resource.
Linkerd automatically installs these CRDs during the installation process unless
the `--set enableHttpRoutes=false` flag or the `enableHttpRoutes=false` Helm
value is explicitly set. By default, Linkerd installs the
`httproutes.gateway.networking.k8s.io/v1beta1` CRDs, which are based on version
0.7 of the Gateway API.

{{< warning >}} Newer versions of the Gateway API may include these CRDs but
might not serve them. This can cause the policy container in Linkerd's
linkerd-destination pods to fail during startup. {{< /warning >}}

Some features in the Gateway API, like timeouts, are not yet stabilized. To
leverage these features, you must use the `policy.linkerd.io` HTTPRoute
resource. Both Linkerd-specific and Gateway API HTTPRoute definitions coexist
within the same cluster and can be used to configure policies for Linkerd.

The table below shows the latest supported versions of the Gateway API and the
features they enable:

| Feature           | HTTPRoute           |
| ----------------- | ------------------- |
| Traffic Splitting | v1.1.1-experimental |
| Header Matching   | v1.1.1-experimental |
| Path Matching     | v1.1.1-experimental |
| Retry Policies    | v1.1.1-experimental |
| Rate Limiting     | -                   |
| Circuit Breaking  | v1.1.1-experimental |
| Authentication    | v1.1.1-experimental |
| Timeouts          | -                   |

To manage rate limiting, you can use Linkerd's rate-limiting functionality, which is configured via HTTPLocalRateLimitPolicy resources. For more information, see [rate limiting](#rate-limiting).

## HTTPRoute Examples

### Header-Based Routing Example

This example demonstrates how an HTTPRoute can route traffic based on a header
value. If the request contains the header `x-faces-user: testuser`, it is
directed to the `smiley2` backend Service. All other requests are routed to the
`smiley` backend Service.

```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: smiley-a-b
  namespace: faces
spec:
  parentRefs:
    - name: smiley
      kind: Service
      group: core
      port: 80
  rules:
    - matches:
        - headers:
            - name: 'x-faces-user'
              value: 'testuser'
      backendRefs:
        - name: smiley2
          port: 80
    - backendRefs:
        - name: smiley
          port: 80
```

### Traffic Splitting Example

This example demonstrates how to split traffic between two backends. A portion
of requests is directed to the `smiley2` backend Service, while the rest go to
the `smiley` backend Service.

```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: smiley-a-b
  namespace: faces
spec:
  parentRefs:
    - name: smiley
      kind: Service
      group: core
      port: 80
  rules:
    - backendRefs:
        - name: smiley
          port: 80
          weight: 40
        - name: smiley2
          port: 80
          weight: 60
```

[Gateway API]: https://gateway-api.sigs.k8s.io/
[ns-boundaries]:
  https://gateway-api.sigs.k8s.io/geps/gep-1426/#namespace-boundaries
