---
title: HTTPRoutes
description:
  Linkerd can use the HTTPRoute resource to configure per-route policies.
---

To configure routing behavior and policy for HTTP traffic, Linkerd supports the
[HTTPRoute resource], defined by the Kubernetes [Gateway API].

{{< note >}}

Two versions of the HTTPRoute resource may be used with Linkerd:

- The upstream version provided by the Gateway API, with the
  `gateway.networking.k8s.io` API group
- A Linkerd-specific CRD provided by Linkerd, with the `policy.linkerd.io` API
  group

The two HTTPRoute resource definitions are similar, but the Linkerd version
implements experimental features not yet available with the upstream Gateway API
resource definition. See
[the HTTPRoute reference documentation](../reference/httproute/#linkerd-and-gateway-api-httproutes)
for details.

{{< /note >}}

An HTTPRoute is a Kubernetes resource which attaches to a parent resource, such
as a [Service]. The HTTPRoute defines a set of rules which match HTTP requests
to that resource, based on parameters such as the request's path, method, and
headers, and can configure how requests matching that rule are routed by the
Linkerd service mesh.

## Inbound and Outbound HTTPRoutes

Two types of HTTPRoute are used for configuring the behavior of Linkerd's
proxies:

- HTTPRoutes with a [Service] as their parent resource configure policies for
  _outbound_ proxies in pods which are clients of that [Service]. Outbound
  policy includes [dynamic request routing][dyn-routing], adding request
  headers, modifying a request's path, and reliability features such as
  [timeouts].
- HTTPRoutes with a [Server] as their parent resource configure policy for
  _inbound_ proxies in pods which recieve traffic to that [Server]. Inbound
  HTTPRoutes are used to configure fine-grained [per-route authorization and
  authentication policies][auth-policy].

{{< warning >}}

**Outbound HTTPRoutes and [ServiceProfiles](service-profiles/) provide
overlapping configuration.** For backwards-compatibility reasons, a
ServiceProfile will take precedence over HTTPRoutes which configure the same
Service. If a ServiceProfile is defined for the parent Service of an HTTPRoute,
proxies will use the ServiceProfile configuration, rather than the HTTPRoute
configuration, as long as the ServiceProfile exists.

{{< /warning >}}

## Learn More

To get started with HTTPRoutes, you can:

- [Configure fault injection](../tasks/fault-injection/) using an outbound
  HTTPRoute.
- [Configure timeouts][timeouts] using an outbound HTTPRoute.
- [Configure dynamic request routing][dyn-routing] using an outbound HTTPRoute.
- [Configure per-route authorization policy][auth-policy] using an inbound
  HTTPRoute.
- See the [reference documentation](../reference/httproute/) for a complete
  description of the HTTPRoute resource.

[HTTPRoute resource]: https://gateway-api.sigs.k8s.io/api-types/httproute/
[Gateway API]: https://gateway-api.sigs.k8s.io/
[Service]: https://kubernetes.io/docs/concepts/services-networking/service/
[Server]: ../reference/authorization-policy/#server
[auth-policy]: ../tasks/configuring-per-route-policy/
[dyn-routing]: ../tasks/configuring-dynamic-request-routing/
[timeouts]: ../tasks/configuring-timeouts/#using-httproutes
