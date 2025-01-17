---
title: Service Profiles
description: Linkerd's service profiles enable per-route metrics as well as retries
  and timeouts.
---

{{< note >}}
[HTTPRoutes](../httproute/) are the recommended method for getting per-route
metrics, specifying timeouts, and specifying retries. Service profiles continue
to be supported for backwards compatibility.
{{< /note >}}

A service profile is a custom Kubernetes resource ([CRD][crd]) that can provide
Linkerd additional information about a service. In particular, it allows you to
define a list of routes for the service. Each route uses a regular expression
to define which paths should match that route. Defining a service profile
enables Linkerd to report per-route metrics and also allows you to enable
per-route features such as retries and timeouts.

{{< note >}}
If working with headless services, service profiles cannot be retrieved. Linkerd
reads service discovery information based off the target IP address, and if that
happens to be a pod IP address then it cannot tell which service the pod belongs
to.
{{< /note >}}

To get started with service profiles you can:

- Look into [setting up service profiles](../../tasks/setting-up-service-profiles/)
  for your own services.
- Glance at the [reference](../../reference/service-profiles/) documentation.

[crd]: https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/
