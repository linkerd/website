+++
date = "2018-11-19T12:00:00-07:00"
title = "Telemetry and Monitoring"
description = "Linkerd automatically collects metrics from all services that send traffic through it."
weight = 7
[menu.l5d2docs]
  name = "Telemetry and Monitoring"
  parent = "features"
+++

Linkerd automatically collects metrics from all services that send traffic
through it. These metrics are aggregated and presented to you in a variety of
ways, including through [Linkerd's CLI](/2/cli/),
[Linkerd's web dashboard](../dashboard/#linkerd-dashboard), and pre-built
[Grafana](../dashboard/#grafana) dashboards.

Note that Linkerd is not designed to be a long-term historical store of
metrics. Thus, metrics data expires after a fixed amount of time (currently, 6
hours).

## Prometheus

Linkerd uses [Prometheus](https://prometheus.io) to aggregate metrics. A small
Prometheus instance is installed as part of the control plane and provides the
data used by the CLI, dashboard and Grafana.
