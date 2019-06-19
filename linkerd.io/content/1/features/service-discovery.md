+++
aliases = ["/features/service-discovery"]
description = "Linkerd integrates with various service discovery backends, helping you to reduce the complexity of your code by removing ad-hoc service discovery implementations."
title = "Service discovery"
weight = 3
[menu.docs]
parent = "features"
weight = 15

+++
A large part of the complexity inherent in running multi-service applications
stems from service discovery. Unfortunately, as the complexity and scale of the
application increases, service discovery becomes difficult to avoid. Linkerd is
explicitly designed to reduce this complexity by:

1. Abstracting away the specifics of the underlying service discovery
   mechanism.
2. Providing upgrade paths that allow you to choose appropriate service
   discovery endpoints.
3. Encouraging best practices based on years of experience using service
   discovery in production systems.

Linkerd abstracts over service discovery mechanisms to treat them in a simple,
uniform way: as simple data stores that are able to resolve *concrete names*
into a set of addresses.

This minimalist interaction, combined with Linkerd's routing rules, provides
powerful control while reducing complexity. For example, Linkerd is able to use
multiple service discovery endpoints and to express precedence and failover
between them.

Linkerd has the ability to treat service discovery as _authoritative_ or
_advisory_. Authoritative service discovery is configured by default, but can be
toggled via Linkerd's [`enableProbation` load balancer configuration](
{{% linkerdconfig "load-balancer" %}}). In authoritative mode, Linkerd will stop
sending traffic to an instance when it is removed from service discovery.

Advisory service discovery is not appropriate for all environments, so it is not
enabled by default. In many environments, however, advisory service discovery
helps protect against failures in the service discovery backend, including
complete outages and missing or invalid data. In advisory mode, Linkerd may
continue to send traffic to an address after it has been removed from service
discovery, provided the endpoint is still available and serving traffic.

In either authoritative or advisory mode, an instance does not need to be
removed from service discovery to stop receiving traffic. If the instance simply
stops accepting requests, Linkerd's load-balancing algorithms are designed to
handle gracefully instances that become unhealthy or disappear.

Lookups in service discovery are controlled by [dtab rules]( {{% ref
"/1/advanced/dtabs.md" %}}). This means that these lookups comprise part of the
routing logic for a request.
