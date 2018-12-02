+++
date = "2018-09-10T12:00:00-07:00"
title = "Architecture"
[menu.l5d2docs]
  name = "Architecture"
  weight = 6
+++

Linkerd is made of three basic components:

1. The CLI, which runs on your local environment (e.g. your laptop).
1. The control plane, which runs on your cluster in a dedicated namespace (e.g. "linkerd").
1. The data plane, which runs on your cluster, as a set of distributed proxies embedded in your services' pods.

Let's take each of those components in turn.

## CLI

The Linkerd CLI, or command-line interface, is run locally on your machine and
is used to interact with the control and data planes. See the [CLI reference
documentation](../cli).

## Control Plane

The Linkerd control plane is a set of services that run in a dedicated
Kubernetes namespace (`linkerd` by default). These services accomplish various
things---aggregating telemetry data, providing a user-facing API, providing
control data to the data plane proxies, etc. Together, they drive the behavior
of the data plane.

The control plane is made up of four components:

- Controller - The controller deployment consists of multiple containers
  (public-api, proxy-api, destination, tap) that provide the bulk of the control
  plane's functionality.

- Web - The web deployment provides the Linkerd dashboard UI.

- Prometheus - All of the metrics exposed by Linkerd are scraped via Prometheus
  and stored here. This is an instance of Prometheus that has been configured to
  work specifically with the data that Linkerd generates. *Note*: this
  Prometheus deployment is intended to supplement, not replace, your existing
  metrics store. [Read more about how to get metrics out of this Prometheus instance](/2/observability/prometheus/#exporting-metrics).

- Grafana - The Grafana component is used to render automatic per-service
  dashboards. You can reach these dashboards via links in the Linkerd dashboard
  UI.

Below is an architecture diagram of the control plane, and how it interacts
with a single proxy instance in the data plane:

{{< fig src="/images/architecture/control-plane.png" title="Architecture" >}}

## Data Plane

The Linkerd data plane is comprised of lightweight proxies, which are deployed
as sidecar containers alongside each instance of your service code. In order to
add a service to the Linkerd service mesh, the pods for that service must be
redeployed to include a data plane proxy in each pod. There are [several ways
to add your service](../adding-your-service) to the data plane.

Linkerd's ultralight transparent proxies are written in
[Rust](https://www.rust-lang.org/).  They receive all incoming traffic for a
pod and intercept all outgoing traffic. This is accomplished via an
`initContainer` that configures `iptables` to forward the traffic correctly.
Because it is a sidecar and intercepts all the incoming and outgoing traffic
for a service, there are no code changes required to the application.

The proxy's features include:

- Transparent, zero-config proxying for HTTP, HTTP/2, and arbitrary TCP
  protocols.
- Automatic Prometheus metrics export for HTTP and TCP traffic.
- Transparent, zero-config WebSocket proxying.
- Automatic, latency-aware, layer-7 load balancing.
- Automatic layer-4 load balancing for non-HTTP traffic.
- Automatic TLS (experimental).
- An on-demand diagnostic tap API.

The proxy supports service discovery via DNS and the
[destination gRPC API](https://github.com/linkerd/linkerd2-proxy-api).


