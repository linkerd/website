+++
aliases = ["/features/routing"]
description = "Linkerd enables dynamic request routing and rerouting, allowing you to set up staging services, canaries, blue-green deploys, cross-DC failover, and dark traffic with a minimal amount of configuration."
title = "Dynamic request routing"
weight = 4
[menu.docs]
parent = "features"
weight = 19

+++
Dynamic request routing is one of Linkerd's more powerful and flexible features.
When Linkerd receives a request, it must somehow determine where to route that
request.  It does this by assigning a service name to the request and then
applying [dtab]({{% ref "/1/advanced/dtabs.md" %}}) rewrites to it.

This introduces a distinction between the service destination (e.g., the `foo`
service) and the concrete destination (e.g., the staging version of the `foo`
service running in the East Coast datacenter).  By having applications only
address requests with a service name, they can be completely agnostic to the
environment.

## Traffic Shifting

By modifying the dtab, we can adjust the mapping from service name to concrete
name.  This lets you shift traffic from staging to production, from one version
of a service to another, or from one datacenter to another.  These changes can
be applied to a percentage of traffic, allowing you to shift traffic in an
incremental and controlled way.  This kind of traffic shifting enables things
like blue-green deploys, canary, and cross-DC failover.

Using [namerd]({{% ref "/1/advanced/namerd.md" %}}) enables the ability to make
these dtab changes at runtime, without needing to restart Linkerd.

## Per-Request Routing

Additional dtab rules can be specified on a per-request basis and will only be
applied to that request.  Any dtab rules in the `l5d-dtab` HTTP header will be
appended to the dtab used for routing that request.  Since later rules have
higher precedence, this allows you to override the destination of the request.

If your application forwards the
[recommended HTTP headers]({{% linkerdconfig "http-headers" %}}), the additional
dtab rules will propagate with the request.  This allows you to test staging
versions of services (even services deep within the application topology)
without affecting production traffic.

For more information on the special headers that Linkerd reads, see the
[HTTP header documentation]({{% linkerdconfig "http-headers" %}}).
For a more detailed description of how Linkerd routes requests, see the
[in-depth routing documentation]({{% ref "/1/advanced/routing.md" %}}).
