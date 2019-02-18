+++
date = "2018-11-19T12:00:00-07:00"
title = "Telemetry and Monitoring"
description = "Linkerd automatically collects metrics from all services that send traffic through it."
weight = 7
aliases = [
  "/2/observability/"
]
[menu.l5d2docs]
  name = "Telemetry and Monitoring"
  parent = "features"
+++

One of Linkerd's most powerful features is its extensive set of tooling around
*observability*&mdash;the measuring and reporting of observed behavior in
meshed applications. While Linkerd doesn't have insight directly into the
*internals* of service code, it has tremendous insight into the external
behavior of service code.

Linkerd's telemetry and monitoring features function automatically, without
requiring any work on the part of the developer. These features include:

* Recording of top-line ("golden") metrics (request volume, success rate, and
  latency distributions) for HTTP, HTTP/2, and gRPC traffic.
* Recording of TCP-level metrics (bytes in/out, etc) for other TCP traffic.
* Reporting metrics per service, per caller/callee pair, or per route/path
  (with [Service Profiles](/2/features/service-profiles/)).
* Generating topology graphs that display the runtime relationship between
  services.
* Live, on-demand request sampling.

This data can be consumed in several ways:

* Through the [Linkerd CLI](/2/cli/), e.g. with `linkerd stat` and
  `linkerd routes`.
* Through the [Linkerd dashboard](/2/features/dashboard/), and
  [pre-built Grafana dashboards](/2/features/dashboard/#grafana).
* Directly from Linkerd's built-in Prometheus instance

# Lifespan of Linkerd metrics

Linkerd is not designed as a long-term historical metrics store.  While
Linkerd's control plane does include a Prometheus instance, this instance
expires metrics at a short, fixed interval (currently 6 hours).

Rather, Linkerd is designed to *supplement* your existing metrics store. If
Linkerd's metrics are valuable, you should export them into your existing
historical metrics store.

See [Exporting Metrics](/2/tasks/exporting-metrics/) for more.
