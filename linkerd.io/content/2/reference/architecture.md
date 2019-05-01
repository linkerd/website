+++
title = "Architecture"
description = "Deep dive into the architecture of Linkerd."
aliases = [
  "/2/architecture/"
]
+++

At a high level, Linkerd consists of a *control plane* and a *data plane*.

The *control plane* is a set of services that run in a dedicated
namespace. These services accomplish various things---aggregating telemetry
data, providing a user-facing API, providing control data to the data plane
proxies, etc. Together, they drive the behavior of the data plane.

The *data plane* consists of transparent proxies that are run next
to each service instance. These proxies automatically handle all traffic to and
from the service. Because they're transparent, these proxies act as highly
instrumented out-of-process network stacks, sending telemetry to, and receiving
control signals from, the control plane.

{{< fig src="/images/architecture/control-plane.png" title="Architecture" >}}

## Control Plane

The Linkerd control plane is a set of services that run in a dedicated
Kubernetes namespace (`linkerd` by default). These services accomplish various
things---aggregating telemetry data, providing a user-facing API, providing
control data to the data plane proxies, etc. Together, they drive the behavior
of the data plane. The CLI can be used to
[install the control plane](/2/getting-started/).

The control plane is made up of five components:

- Controller - The controller deployment consists of multiple containers
  (public-api, proxy-api, destination, tap) that provide the bulk of the control
  plane's functionality.

- Web - The web deployment provides the Linkerd dashboard.

- Prometheus - All of the metrics exposed by Linkerd are scraped via Prometheus
  and stored here. This is an instance of Prometheus that has been configured to
  work specifically with the data that Linkerd generates. There are
  [instructions](/2/observability/exporting-metrics/)
  if you would like to integrate this with an
  existing Prometheus installation.

- Grafana - Linkerd comes with many dashboards out of the box. The Grafana
  component is used to render and display these dashboards. You can reach these
  dashboards via links in the Linkerd dashboard itself.

- Proxy injector - Whenever a pod is created into the cluster, this component
  injects a proxy sidecar into it if the proxy spec has a
  `linkerd.io/inject: enabled` annotation (or if the namespace has it).

## Data Plane

The Linkerd data plane is comprised of lightweight proxies, which are deployed
as sidecar containers alongside each instance of your service code. In order to
“add” a service to the Linkerd service mesh, the pods for that service must be
redeployed to include a data plane proxy in each pod. (The `linkerd inject`
command accomplishes this, as well as the configuration work necessary to
transparently funnel traffic from each instance through the proxy.) You can
[add your service](/2/tasks/adding-your-service/) to the data plane with a
single CLI command, or have the proxy injector do it for you.

These proxies transparently intercept communication to and from each pod, and
add features such as instrumentation and encryption (TLS), as well as allowing
and denying requests according to the relevant policy.

These proxies are not designed to be configured by hand. Rather, their behavior
is driven by the control plane.

### Proxy

An ultralight transparent proxy written in [Rust](https://www.rust-lang.org/),
the proxy is installed into each pod of a service and becomes part of the data
plane. It receives all incoming traffic for a pod and intercepts all outgoing
traffic via an `initContainer` that configures `iptables` to forward the
traffic correctly. Because it is a sidecar and intercepts all the incoming and
outgoing traffic for a service, there are no code changes required and it can
even be added to a running service.

The proxy's features include:

- Transparent, zero-config proxying for HTTP, HTTP/2, and arbitrary TCP
  protocols.

- Automatic Prometheus metrics export for HTTP and TCP traffic.

- Transparent, zero-config WebSocket proxying.

- Automatic, latency-aware, layer-7 load balancing.

- Automatic layer-4 load balancing for non-HTTP traffic.

- Automatic TLS.

- An on-demand diagnostic tap API.

The proxy supports service discovery via DNS and the
[destination gRPC API](https://github.com/linkerd/linkerd2-proxy-api).

## CLI

The Linkerd CLI is run locally on your machine and is used to interact with the
control and data planes. It can be used to view statistics, debug production
issues in real time and install/upgrade the control and data planes.

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

{{< gallery-item src="/images/screenshots/grafana-top.png"
    title="Top Line Metrics" >}}

{{< gallery-item src="/images/screenshots/grafana-deployment.png"
    title="Deployment Detail" >}}

{{< gallery-item src="/images/screenshots/grafana-pod.png"
    title="Pod Detail" >}}

{{< gallery-item src="/images/screenshots/grafana-health.png"
    title="Linkerd Health" >}}

{{< /gallery >}}

## Prometheus

Prometheus is a cloud native monitoring solution that is used to collect
and store all the Linkerd metrics. It is installed as part of the control plane
and provides the data used by the CLI, dashboard and Grafana.

The proxy exposes a `/metrics` endpoint for Prometheus to scrape on port 4191.
This is scraped every 10 seconds. These metrics are then available to all the
other Linkerd components, such as the CLI and dashboard.

{{< fig src="/images/architecture/prometheus.svg" title="Metrics Collection" >}}
