+++
title = "Service Mesh Glossary"
weight = 30
+++

## API Gateway

An API gateway sits in front of an application and is designed to solve business
problems like authentication and authorization, rate limiting, and providing a
common access point for external consumers. A service mesh, in contrast, is
focused on providing operational (not business) logic between components of the
application.

## Control Pane

The control plane of a service mesh provides the command and control signals
required for the [data plane](#data-pane) to operate. The control plane controls
the data plane and provides the UI and API that operators use to configure,
monitor, and operate the mesh.

## Data Pane

The data plane of a service mesh comprises the deployment of its
[sidecar proxies](#sidecar-proxy) that intercept in-mesh application traffic.
The data plane is responsible for gathering metrics, observing traffic, and
applying policy.

## Golden Metrics

Golden metrics, or golden signals, are the core metrics of application health.
The set of golden metrics is generally defined as [latency](#latency), traffic
volume, error rate, and saturation. Linkerd's golden metrics omit saturation.

## Latency

Latency refers to the time it takes an application to do something (e.g.,
processing a request, populating data, etc.) In service mesh terms, this is
measured at the response level, i.e. by timing how long the application takes to
respond to a request. Latency is typically characterized by the percentiles of a
distribution, commonly including the p50 (or median), the p95 (or 95th
percentile), the p99 (or 99th percentile), and so on.

## Linkerd

Linkerd was the first service mesh and the project that defined the term
"service mesh" itself. First released 2016, Linkerd is designed to be the
fastest, lightest-weight service mesh possible for Kubernetes. Linkerd is a
Cloud Native Computing Foundation (CNCF) incubating project.

## Service mesh

A service mesh is a tool for adding observability, security, and reliability
features to applications by inserting these features at the platform layer
rather than the application layer. Service meshes are implemented by adding
[sidecar proxies](#sidecar-proxy) that intercept all traffic between
applications. The resulting set of proxies forms the service mesh
[data plane](#data-plane) and is managed by the service mesh
[control plane](#control-plane). The proxies funnel all communication between
services and are the vehicle through which service mesh features are introduced.

## Sidecar Proxy

A sidecar proxy is a proxy that is deployed alongside the applications in the
mesh. (In Kubernetes, as a container within the application's pod.) The sidecar
proxy intercepts network calls to and from the applications and is responsible
for implementing any [control plane](#control-pane)’s logic or rules.
Collectively, the sidecar proxies form the service mesh's
[data plane](#data-pane). Linkerd uses a Rust-based "micro-proxy" called
Linkerd2-proxy that is specifically designed for the service mesh use case.
Linkerd2-proxy is significantly lighter and easier to operate than
general-purpose proxies such as Envoy or NGINX. See
[Why Linkerd Doesn't Use Envoy](/2020/12/03/why-linkerd-doesnt-use-envoy/) for
more.

## Success rate

Success rate refers to the percentage of requests that our application responds
to successfully. For HTTP traffic, for example, this is measured as the
proportion of 2xx or 4xx responses over total responses. (Note that, in this
context, 4xx is considered a successful response—the application performed its
jobs—whereas 5xx responses are considered unsuccessful—the application failed to
respond to the request). A high success rate indicates that an application is
behaving correctly.
