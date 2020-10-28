+++
aliases = ["/features/distributed-tracing-and-instrumentation"]
description = "Linkerd supports both distributed tracing and metrics instrumentation, providing uniform observability across all services."
title = "Distributed tracing"
weight = 9
[menu.docs]
parent = "features"
weight = 17

+++
As the number and complexity of services increases, uniform observability across
the data center becomes more critical. Linkerd's tracing and metrics
instrumentation is designed to be aggregated, providing broad and granular
insight into the health of all services. Linkerd's role as a service mesh makes
it the ideal data source for observability information, particularly in a
polyglot environment.

As requests pass through multiple services, identifying performance bottlenecks
becomes increasingly difficult using traditional debugging techniques.
Distributed tracing provides a holistic view of requests transiting through
multiple services, allowing for immediate identification of latency issues.

With Linkerd, distributed tracing comes for free. Simply configure Linkerd to
export tracing data to a backend trace aggregator, such as
[Zipkin](http://zipkin.io). This will expose latency, retry, and failure
information for each hop in a request.

## Further reading

If you're ready to start using distributed tracing in your setup, see the
[Tracers section of the Linkerd config]({{% linkerdconfig "tracers" %}}).

For a guide on setting up an end-to-end distributed tracing pipeline, see
[Distributed Tracing for Polyglot Microservices](https://blog.buoyant.io/2016/05/17/distributed-tracing-for-polyglot-microservices/)
on the [Buoyant Blog](https://blog.buoyant.io).
