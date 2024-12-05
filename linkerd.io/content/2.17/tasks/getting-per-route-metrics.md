---
title: Getting Per-Route Metrics
description: Configure per-route metrics for your application.
---

To get per-route metrics, you must create [HTTPRoute] resources. If a route has
a `parent_ref` which points to a **Service** resource, Linkerd will generate
outbound per-route traffic metrics for all HTTP traffic that it sends to that
Service. If a route has a `parent_ref` which points to a **Server** resource,
Linkerd will generate inbound per-route traffic metrcs for all HTTP traffic that
it receives on that Server. Note that an [HTTPRoute] can have multiple
`parent_ref`s which means that the same [HTTPRoute] resource can be used to
describe both outbound and inbound routes.

For a tutorial that shows off per-route metrics, check out the
[books demo](../books/#service-profiles).

{{< note >}}
Routes configured in service profiles are different from [HTTPRoute] resources.
If a [ServiceProfile](../../features/service-profiles/) is defined for a
Service, proxies will ignore any [HTTPRoute] for that Service.
{{< /note >}}

[HTTPRoute]: ../../features/httproute/
