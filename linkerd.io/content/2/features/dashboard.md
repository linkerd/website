+++
title = "Dashboard and Grafana"
description = "Linkerd provides a web dashboard, as well as pre-configured Grafana dashboards."
+++

In addition to its [command-line interface](/2/cli/), Linkerd provides a web
dashboard and pre-configured Grafana dashboards.

## Linkerd Dashboard

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

{{< gallery-item src="/images/screenshots/grafana-top.png"
    title="Top Line Metrics" >}}

{{< gallery-item src="/images/screenshots/grafana-deployment.png"
    title="Deployment Detail" >}}

{{< gallery-item src="/images/screenshots/grafana-pod.png"
    title="Pod Detail" >}}

{{< gallery-item src="/images/screenshots/grafana-health.png"
    title="Linkerd Health" >}}

{{< /gallery >}}
