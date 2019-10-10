+++
title = "Distributed Tracing"
description = "Linkerd 2.x provides some of the features of distributed tracing, but does not currently emit spans."
+++

Tracing can be an invaluable tool in debugging distributed systems performance,
especially for identifying bottlenecks and understanding the latency cost of
each component in your system.  If you're not already familiar with the idea
behind distributed tracing, [Distributed Tracing for Polyglot
Microservices](/2016/05/17/distributed-tracing-for-polyglot-microservices/)
gives a good overview of the concepts.

Linkerd can be configured to emit trace spans from the proxies, allowing you to
see exactly what time requests and responses spend inside. Unfortunately, unlike
most of the features of Linkerd, both code changes and configuration are
required. You can read up on [Distributed tracing in the service mesh: four
myths](/2019/08/09/service-mesh-distributed-tracing-myths/) for a deep dive into
why this is.

Alternatively, Linkerd also provides some of the features that are often
associated with distributed tracing, including:

* Live service topology and dependency graphs
* Aggregated service health, latencies, and request volumes
* Aggregated path / route health, latencies, and request volumes

These features are provided *automatically*, without requiring changes to the
application or instrumentation with distributed tracing libraries.

For example, Linkerd can display a live topology of all incoming and outgoing
dependencies for a service, without requiring distributed tracing or any other
such application modification:

{{< fig src="/images/books/webapp-detail.png"
    title="The Linkerd dashboard showing an automatically generated topology graph"
>}}

Likewise, Linkerd can provide golden metrics per service and per *route*, again
without requiring distributed tracing or any other such application
modification:

{{< fig src="/images/books/webapp-routes.png"
    title="Linkerd dashboard showing an automatically generated route metrics"
>}}
