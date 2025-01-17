---
title: Gateway API support
description: Linkerd uses the Gateway API resource types for much configuration.
---

The Gateway API is a set of CRDs in the `gateway.networking.k8s.io` API group
which describe types of traffic in a way that is independent of a specific mesh
or ingress implementation. Recent versions of Linkerd fully support the
[Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/) as a core
configuration mechanism, and many Linkerd features, including [authorization
policies][auth-policy], [dynamic traffic routing][dyn-routing], and [request
timeouts][timeouts], rely on resource types from the Gateway API for
configuration.

The two primary Gateway API types used to configure Linkerd are:

- [HTTPRoute], which parameterizes HTTP requests
- [GRPCRoute], which parameterizes gRPC requests

Both of these types are used in a variety of ways when configuring Linkerd.

## Managing the Gateway API

One complication with using the Gateway API in practice is that many different
packages, not just Linkerd, may provide the Gateway API on your cluster, but
only some Gateway API *versions* are compatible with Linkerd.

In practice, there are two basic approaches to managing the Gateway API with
Linkerd. You can let Linkerd manage the Gateway API resources, or you can let a
different tool manage them.

### Option 1: Linkerd manages the Gateway API

This is the default behavior for Linkerd, which will create, update, and delete
Gateway API resources as required. In this approach, any other tools on your
system that use Gateway API resources will be need to be compatible with the
version of the Gateway API that Linkerd installs:

| Linkerd versions | Gateway API version installed | HTTPRoute version | gRPC version |
| ---------------- | ----------------------------- | ----------------- | ------------ |
| 2.15 - 2.17      | 0.7                           | v1beta1           | v1alpha2     |

### Option 2: A different tool manages the Gateway API

Alternatively, you may prefer to have something other than Linkerd manage the
Gateway API resources on your cluster. To do this, you will need to instruct
Linkerd *not* to install, update, or delete the Gateway API resources, by
passing pass the `--set enableHttpRoutes=false` flag during the `linkerd install
--crds` step, or setting the `enableHttpRoutes=false` Helm value when installing
the `linkerd-crds` Helm chart.

You will also need to ensure that version of the Gateway API installed is
compatible with Linkerd:

| Linkerd versions | Compatible Gateway API versions | Recommended Gateway API version |
| ---------------- | ------------------------------- | ------------------------------- |
| 2.15 - 2.17      | 0.7, 0.7.1, 1.1.1-experimental  | 1.1.1-experimental              |

If possible, you should install the *recommended* Gateway API version in the
table above.  (Note that the use of *experimental* Gateway API versions is
sometimes necessary to allow for full functionality; despite the name, these
versions are production capable.)

{{< warning >}}
Running Linkerd with an incompatible version of the Gateway API
on the cluster can lead to hard-to-debug issues with your Linkerd installation.
{{< /warning >}}

## Precursors to Gateway API-based configuration

Prior to the complete support of the Gateway API introduced in Linkerd 2.14,
Linkerd provided two earlier variants of configuration:

- A Linkerd-specific `HTTPRoute` CRD provided by Linkerd in the
  `policy.linkerd.io` API group
- [ServiceProfiles], which allowed for configuration of per-route metrics,
  retries, and timeouts prior to the introduction of the Gateway API types.

Both of these earlier configuration mechanisms continue to be supported;
however, newer feature development is focused on the standard Gateway API
types.

## Learn More

To get started with the Gateway API types, you can:

- [Configure fault injection](../../tasks/fault-injection/)
- [Configure timeouts][timeouts]
- [Configure dynamic request routing][dyn-routing]
- [Configure per-route authorization policy][auth-policy]

[HTTPRoute]: ../../reference/httproute/
[GRPCRoute]: ../../reference/grpcroute/
[Gateway API]: https://gateway-api.sigs.k8s.io/
[Service]: https://kubernetes.io/docs/concepts/services-networking/service/
[Server]: ../../reference/authorization-policy/#server
[auth-policy]: ../../tasks/configuring-per-route-policy/
[dyn-routing]:../../tasks/configuring-dynamic-request-routing/
[timeouts]: ../../features/retries-and-timeouts/
[ServiceProfiles]: ../../features/service-profiles/
