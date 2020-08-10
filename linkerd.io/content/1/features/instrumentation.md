+++
aliases = ["/features/instrumentation"]
description = "Linkerd supports both distributed tracing and metrics instrumentation, providing uniform observability across all services."
title = "Instrumentation"
weight = 10
[menu.docs]
parent = "features"
weight = 12

+++
Linkerd provides detailed histograms of communication latency and payload sizes,
as well as success rates and load-balancing statistics, in both human-readable
and machine-parsable formats. This means that even polyglot applications can
have a consistent, global view of application performance. There are hundreds of
counters, gauges, and histograms available, including:

* latency (avg, min, max, p99, p999, p9999)
* request volume
* payload sizes
* success, retry, and failure counts
* failure classification
* heap and GC performance
* load balancing statistics

While Linkerd provides an open telemetry plugin interface for integration with
any metrics aggregator, it includes some common formats out of the box, including
[TwitterServer](https://twitter.github.io/twitter-server/Admin.html#admin-metrics-json),
[Prometheus](https://prometheus.io/), and
[InfluxDB](https://docs.influxdata.com/influxdb/).

## Further reading

For configuring a telemeter such as Prometheus, see the
[Telemetry section of the Linkerd config]({{% linkerdconfig "telemetry" %}}).

For more detail about Metrics instrumentation, see the
[Telemetry section of the Admin guide]({{% ref
"/1/administration/telemetry.md"
%}}).

For configuring your metrics endpoint, see the [Admin section of the Linkerd
config]({{% linkerdconfig "administrative-interface" %}}).

For a guide on setting up an end-to-end monitoring pipeline on Kubernetes, see
[A Service Mesh for Kubernetes, Part I: Top-Line Service Metrics](https://blog.buoyant.io/2016/10/04/a-service-mesh-for-kubernetes-part-i-top-line-service-metrics/).
For DC/OS, see
[Linkerd on DC/OS for Service Discovery and Visibility](https://blog.buoyant.io/2016/10/10/linkerd-on-dcos-for-service-discovery-and-visibility/).
Both of these leverage our out-of-the-box linkerd+prometheus+grafana
setup, [linkerd-viz](https://github.com/linkerd/linkerd-viz).
