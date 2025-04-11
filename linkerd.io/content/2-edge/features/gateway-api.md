---
title: Gateway API support
description: Linkerd uses Gateway API resource types to configure certain features.
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

Linkerd requires that the Gateway API be installed on your cluster before
Linkerd can be installed. In practice, there are three basic approaches to
managing the Gateway API with Linkerd. The Gateway API may already be installed
on your cluster, you can install the Gateway API yourself, or you can have
Linkerd install the Gateway API for you.

### Option 1: The Gateway API is already installed {#gateway-api-compatibility}

The Gateway API may already be installed on your cluster; either because it came
pre-installed on the cluster or because another tool has installed it. You can
check if the Gateway API is installed by running:

```bash
> kubectl get crds/httproutes.gateway.networking.k8s.io -o "jsonpath={.metadata.annotations.gateway\.networking\.k8s\.io/bundle-version}"
```

If this command returns Not Found error, the Gateway API is not installed.
Otherwise it will return the Gateway API version number. Check that version
against the compatibility table:

| Linkerd versions | Gateway API version compatibilty | HTTPRoute version | gRPC version |
| ---------------- | -------------------------------- | ----------------- | ------------ |
| 2.15 - 2.17      | 0.7 - 1.1.1                      | v1beta1           | v1alpha2     |
| 2.18             | 1.1.1 - 1.2.1                    | v1                | v1           |

{{< note >}}

If you are using GRPCRoute, upgrading from Gateway API 1.1.1 to Gateway API
1.2.0 or higher requires extra care. See [the Gateway API 1.2.0 release notes]
for more information.

[the Gateway API 1.2.0 release notes]: https://github.com/kubernetes-sigs/gateway-api/releases/tag/v1.2.0
{{< /note >}}

If the Gateway API is installed at a compatible version, you can go ahead and
install Linkerd as normal. Note that if you are using Helm to install, you must
set `--set installGatewayAPI=false` or specify this in your `values.yml` when
installing the `linkerd-crds` Helm chart. This prevents Linkerd from attempting
to override your existing installation of the Gateway API

{{< warning >}}
Running Linkerd with an incompatible version of the Gateway API
on the cluster can lead to hard-to-debug issues with your Linkerd installation.
{{< /warning >}}

### Option 2: Install the Gateway API yourself

If the Gateway API is not already installed on your cluster, you may install
it yourself by following the [Gateway API install
guide](https://gateway-api.sigs.k8s.io/guides/#installing-gateway-api), which
is often as simple as something like

```bash
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml
```

You will need to ensure the version of the Gateway API that you install is
compatible with Linkerd by checking the above table. In general, we recommend
the latest `Standard` channel release of Gateway API.

Once a compatible version of the Gateway API is installed, you can proceed with
the Linkerd installation as above.

### Option 3: Have Linkerd install the Gateway API

If the Gateway API is not already installed on your cluster, you may have
Linkerd install it bundled with Linkerd's CRDs by setting
`--set installGatewayAPI=true` or specifying this in your `values.yml`. This
applies to the `linkerd install --crds` command or when installing the
`linkerd-crds` Helm chart.

Note that if Linkerd installs the Gateway API like this, then the Gateway API
will also be removed if Linkerd is uninstalled.

| Linkerd versions | Gateway API version installed |
| ---------------- | ----------------------------- |
| 2.15 - 2.17      | 0.7                           |
| 2.18             | 1.1.1                         |

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
[auth-policy]: ../../tasks/configuring-per-route-policy/
[dyn-routing]:../../tasks/configuring-dynamic-request-routing/
[timeouts]: ../../features/retries-and-timeouts/
[ServiceProfiles]: ../../features/service-profiles/
