---
title: Gateway API support
description:
  Linkerd uses Gateway API resource types to configure certain features.
---

The [Gateway API](https://gateway-api.sigs.k8s.io/) is a set of CRDs in the
`gateway.networking.k8s.io` API group which describe types of traffic in a way
that is independent of a specific mesh or ingress implementation. Recent
versions of Linkerd fully support the
[Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/) as a core
configuration mechanism, and many Linkerd features, including [authorization
policies][auth-policy], [dynamic traffic routing][dyn-routing], and [request
timeouts][timeouts], require these resource types from the Gateway API in order
to be used. (Note that Linkerd does not require these types in order to run, but
these features will not be useable.)

The two primary Gateway API types used to configure Linkerd are:

- [HTTPRoute], which parameterizes HTTP requests
- [GRPCRoute], which parameterizes gRPC requests

Both of these types are used in a variety of ways when configuring Linkerd.

## Checking the existing Gateway API version

The Gateway API may already be installed on your cluster. Check by running:

```bash
kubectl get crds/httproutes.gateway.networking.k8s.io -o "jsonpath={.metadata.annotations.gateway\.networking\.k8s\.io/bundle-version}"
```

If this command returns Not Found error, the Gateway API is not installed.
Otherwise it will return the Gateway API version number. Check that version
against the compatibility table:

| Linkerd versions | Gateway API version compatibility | HTTPRoute version | gRPC version |
| ---------------- | --------------------------------- | ----------------- | ------------ |
| 2.15 - 2.17      | 0.7 - 1.1.1                       | v1beta1           | v1alpha2     |
| 2.18             | 1.1.1 - 1.2.1                     | v1                | v1           |
| 2.19             | 1.1.1 - 1.4.0                     | v1                | v1           |

{{< note >}}

If you are using GRPCRoute, upgrading from Gateway API 1.1.1 to Gateway API
1.2.0 or higher requires extra care. See [the Gateway API 1.2.0 release
notes][GatewayAPI] for more information.

[GatewayAPI]: https://github.com/kubernetes-sigs/gateway-api/releases/tag/v1.2.0

{{< /note >}}

{{< warning >}}

Running Linkerd with an incompatible version of the Gateway API on the cluster
can lead to hard-to-debug issues with your Linkerd installation.

{{< /warning >}}

## Installing the Gateway API

If the Gateway API is not already installed on your cluster, you may install it
by following the
[Gateway API install guide](https://gateway-api.sigs.k8s.io/guides/#installing-gateway-api),
which is often as simple as:

```bash
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.0/standard-install.yaml
```

## Note: Precursors to Gateway API-based configuration

Prior to the complete support of the Gateway API introduced in Linkerd 2.14,
Linkerd provided two earlier variants of configuration:

- A Linkerd-specific `HTTPRoute` CRD provided by Linkerd in the
  `policy.linkerd.io` API group
- [ServiceProfiles], which allowed for configuration of per-route metrics,
  retries, and timeouts prior to the introduction of the Gateway API types.

Both of these earlier configuration mechanisms continue to be supported;
however, newer feature development is focused on the standard Gateway API types.

## Learn More

To get started with the Gateway API types, you can:

- [Configure fault injection](../tasks/fault-injection/)
- [Configure timeouts][timeouts]
- [Configure dynamic request routing][dyn-routing]
- [Configure per-route authorization policy][auth-policy]

[HTTPRoute]: ../reference/httproute/
[GRPCRoute]: ../reference/grpcroute/
[auth-policy]: ../tasks/configuring-per-route-policy/
[dyn-routing]: ../tasks/configuring-dynamic-request-routing/
[timeouts]: ../features/retries-and-timeouts/
[ServiceProfiles]: ../features/service-profiles/
