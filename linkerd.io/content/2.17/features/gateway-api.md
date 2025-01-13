---
title: Gateway API support
description: Linkerd uses the Gateway API resource types for much configuration.
---

Recent versions of Linkerd fully support the Kubernetes [Gateway API] and rely
on Gateway API resource types for configuration of many features. Features like
[authorization policies][auth-policy], [dynamic traffic routing][dyn-routing],
and [request timeouts][timeouts] all make heavy use of Gateway API types.

## Managing the Gateway API

The Gateway API comprises several CRDs in the `gateway.networking.k8s.io` API
group, including the [HTTPRoute resource] and the [GRPCRoute resource]. One
complication with using the Gateway API in practice is that many different
packages, not just Linkerd, may provide the Gateway API on your cluster, but
only some Gateway API *versions* are compatible with Linkerd.

In practice, there are two basic approaches to managing the Gateway API with
Linkerd: letting Linkerd manage the Gateway API resources, or using a separate
tool to manage them.

### Option 1: Let Linkerd manage the Gateway API

This is the default for Linkerd, which will create, update, and delete these
resources as required.  Other tools on your system that use Gateway API
resources will be required to use the version of the Gateway API that Linkerd
installs, as described below.

| Linkerd version | Gateway API version installed |
| --------------- | ----------------------------- |
| 2.15            | 0.7                           |
| 2.16            | 0.7                           |
| 2.17            | 0.7                           |

### Option 2: Use another tool for managing the Gateway API

To have a source other than Linkerd manage the Gateway API resources, you will
need to instruct Linkerd *not* to install, update, or delete the Gateway API
resources. To do this, you pass the `--set enableHttpRoutes=false` flag during
the `linkerd install --crds` step, or (if using Helm) set the
`enableHttpRoutes=false` Helm value when installing the `linkerd-crds` Helm
chart.

You will need to ensure that version of the Gateway API installed is compatible
with Linkerd, by following this table:

| Linkerd version | Compatible Gateway API versions | Recommended Gateway API version |
| --------------- | ------------------------------- | ----------------------- |
| 2.14            | 0.7, 0.7.1, 1.1.1-experimental  | 1.1.1-experimental      |
| 2.15            | 0.7, 0.7.1, 1.1.1-experimental  | 1.1.1-experimental      |
| 2.16            | 0.7, 0.7.1, 1.1.1-experimental  | 1.1.1-experimental      |
| 2.17            | 0.7, 0.7.1, 1.1.1-experimental  | 1.1.1-experimental      |

If possible, install the *recommended* Gateway API version in the table above.
(Note that the use of *experimental* Gateway API versions is sometimes necessary
to allow for full functionality; despite the name, these versions are production
capable.)

Note also that running Linkerd with an incompatible version of the Gateway API
on the cluster can lead to hard-to-debug issues with your Linkerd installation.

## Evolution of Linkerd's configuration

Prior to the complete support of the Gateway API introduced in Linkerd 2.14,
Linkerd provided two earlier variants of configuration:

- A Linkerd-specific `HTTPRoute` CRD provided by Linkerd in the
  `policy.linkerd.io` API group
- [ServiceProfiles], which allowed for configuration of per-route metrics,
  retries, and timeouts prior to the introduction of the Gateway API types.

Both of these earlier configuration mechanisms continue to be supported;
however, newer feature development is focused on the standard Gateway API
types.

See the [HTTPRoute reference documentation](../../reference/httproute/) for a
complete description of the HTTPRoute resource.

## Learn More

To get started with the Gateway API types, you can:

- [Configure fault injection](../../tasks/fault-injection/) using an outbound
  HTTPRoute.
- [Configure timeouts][timeouts] using an outbound HTTPRoute.
- [Configure dynamic request routing][dyn-routing] using an outbound HTTPRoute.
- [Configure per-route authorization policy][auth-policy] using an inbound
  HTTPRoute.

[HTTPRoute resource]: https://gateway-api.sigs.k8s.io/api-types/httproute/
[GRPCRoute resource]: https://gateway-api.sigs.k8s.io/api-types/grpcroute/
[Gateway API]: https://gateway-api.sigs.k8s.io/
[Service]: https://kubernetes.io/docs/concepts/services-networking/service/
[Server]: ../../reference/authorization-policy/#server
[auth-policy]: ../../tasks/configuring-per-route-policy/
[dyn-routing]:../../tasks/configuring-dynamic-request-routing/
[timeouts]: ../../tasks/configuring-timeouts/#using-httproutes
[ServiceProfiles]: ../../features/service-profiles/
