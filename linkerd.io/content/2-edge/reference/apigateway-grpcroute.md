---
title: Gateway API gRPCRoutes
description: Reference guide to Gateway API gRPCRoutes resources.
---

<!-- markdownlint-disable-file blanks-around-tables -->
<!-- markdownlint-disable-file table-column-count -->
<!-- markdownlint-disable-file table-pipe-style -->

## Linkerd and Gateway API gRPCRoutes

Samelessy than HTTPRoute, Linkerd supports the Kubernetes Gateway API gRPC
resources alongside its own traffic management API. Linkerd automatically
installs these CRDs during the installation process unless the
`--set enableHttpRoutes=false` flag or the `enableHttpRoutes=false` Helm value
is explicitly set. By default, Linkerd installs the
`grpcroutes.gateway.networking.k8s.io/v1alpha2` CRDs, which are based on version
0.7 of the Gateway API.

{{< warning >}} Newer versions of the Gateway API may include these CRDs but
might not serve them. This can cause the policy container in Linkerd's
linkerd-destination pods to fail during startup. {{< /warning >}}

The table below shows the latest supported versions of the Gateway API and the
features they enable:

| Feature           | GRPCRoute |
| ----------------- | --------- |
| Traffic Splitting | v0.7      |
| Header Matching   | v0.7      |
| Path Matching     | v0.7      |
| Rate Limiting     | -         |
| Circuit Breaking  | v0.7      |
| Authentication    | v0.7      |

## GRPCRoute Examples

### Traffic Splitting Example

This example demonstrates how to split traffic between two backends. A portion
of requests is directed to the `smiley2` backend Service, while the rest go to
the `smiley` backend Service.

```yaml
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: GRPCRoute
metadata:
  name: smiley-a-b
  namespace: faces
spec:
  parentRefs:
    - name: smiley
      kind: Service
      group: core
      port: 50051
  rules:
    - backendRefs:
        - name: smiley
          port: 50051
          weight: 40
        - name: smiley2
          port: 80
          weight: 50051
```

[Gateway API]: https://gateway-api.sigs.k8s.io/
[ns-boundaries]:
  https://gateway-api.sigs.k8s.io/geps/gep-1426/#namespace-boundaries
