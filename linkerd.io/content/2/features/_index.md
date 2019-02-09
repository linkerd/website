+++
date = "2018-09-10T12:00:00-07:00"
title = "Features"
[menu.l5d2docs]
  name = "Features"
  weight = 3
+++

{{% sectiontoc "cli" %}}

## Dashboard

The Linkerd dashboard provides a high level view of what is happening with your
services in real time. It can be used to view the "golden" metrics (success
rate, requests/second and latency), visualize service dependencies and
understand the health of specific service routes. One way to pull it up is by
running `linkerd dashboard` from the command line.

{{< fig src="/images/architecture/stat.png" title="Top Line Metrics">}}

## Grafana

As a component of the control plane, Grafana provides actionable dashboards for
your services out of the box. It is possible to see high level metrics and dig
down into the details, even for pods.

The dashboards that are provided out of the box include:

{{< gallery >}}

{{< gallery-item src="/images/screenshots/grafana-top.png" title="Top Line Metrics" >}}

{{< gallery-item src="/images/screenshots/grafana-deployment.png" title="Deployment Detail" >}}

{{< gallery-item src="/images/screenshots/grafana-pod.png" title="Pod Detail" >}}

{{< gallery-item src="/images/screenshots/grafana-health.png" title="Linkerd Health" >}}

{{< /gallery >}}

## Prometheus

Prometheus is a cloud native monitoring solution that is used to collect
and store all the Linkerd metrics. It is installed as part of the control plane
and provides the data used by the CLI, dashboard and Grafana.

The proxy exposes a `/metrics` endpoint for Prometheus to scrape on port 4191.
This is scraped every 10 seconds. These metrics are then available to all the
other Linkerd components, such as the CLI and dashboard.

{{< fig src="/images/architecture/prometheus.svg" title="Metrics Collection" >}}
