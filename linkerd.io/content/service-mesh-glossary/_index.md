---
title: "Service Mesh Glossary"
weight: 30
enableFAQSchema: true
summary: "This glossary covers the most important service mesh concepts. Whether latency, sidecar proxy, or success rate, you'll find a succinct definition for each term."
faqs:
  - question: What is an API gateway?
    answer: 
      An API gateway sits in front of an app and is designed to solve business 
      problems like authentication and authorization, rate limiting, and 
      providing a common access point for external consumers. A service mesh, 
      in contrast, is focused on providing operational logic between 
      components of the app.
  - question: What is a service mesh control plane?
    answer:
      The control plane of a service mesh provides the command and control
      signals required for the [data plane](#data-pane) to operate. The control
      plane controls the data plane and provides the UI and API that operators
      use to configure, monitor, and operate the mesh.
  - question: What is a data plane?
    answer:
      The data plane of a service mesh comprises the deployment of its
      [sidecar proxies](#sidecar-proxy) that intercept in-mesh application
      traffic. The data plane is responsible for gathering metrics, observing
      traffic, and applying policy.
  - question: What is distributed tracing?
    answer: 
      In a microservices-based system, an individual request from a client 
      typically triggers a series of requests across a number of services. 
      Distributed tracing is the practice of "tracing", or following, these 
      requests as they move through the distributed system for reasons of 
      performance monitoring or debugging.
  - question: What are golden metrics?
    answer: 
      Golden metrics, or golden signals, are the core metrics of application
      health. The set of golden metrics is generally defined as
      [latency](#latency), traffic volume, error rate, and saturation. Linkerd's
      golden metrics omit saturation.
  - question: What is latency?
    answer:
      Latency refers to the time it takes an application to do something (e.g.,
      processing a request, populating data, etc.) In service mesh terms, this
      is measured at the response level, i.e. by timing how long the application
      takes to respond to a request.
  - question: What is Linkerd?
    answer:
      Linkerd was the first service mesh and the project that defined the term 
      "service mesh" itself. First released 2016, Linkerd is designed to be the 
      fastest, lightest-weight service mesh possible for Kubernetes. Linkerd 
      is a Cloud Native Computing Foundation (CNCF) incubating project.
  - question: What is load balancing?
    answer:
      Load balancing is the act of distributing work across a number of 
      equivalent endpoints. Kubernetes, like many systems, provides load 
      balancing at the connection level. A service mesh like Linkerd improves 
      this by performing load balancing at the request level.
  - question: What is multi-cluster?
    answer:
      In the context of Kubernetes, multi-cluster usually refers to running 
      an application "across" multiple Kubernetes clusters. Linkerd's 
      multi-cluster support provides seamless and secured communication 
      across clusters, in a way that's secure even across the open Internet.
  - question: What is a service mesh?
    answer:
      A service mesh is a tool for adding observability, security, and
      reliability features to applications by inserting these features at the
      platform layer rather than the application layer. Service meshes are
      implemented by adding [sidecar proxies](#sidecar-proxy) that intercept all
      traffic between applications.
  - question: What is a sidecar proxy?
    answer:
      A sidecar proxy is a proxy that is deployed alongside the applications in
      the mesh. (In Kubernetes, as a container within the application's pod.)
      The sidecar proxy intercepts network calls to and from the applications
      and is responsible for implementing any [control plane](#control-plane)’s
      logic or rules. 
  - question: What is the Success rate?
    answer:
      Success rate refers to the percentage of requests that our application
      responds to successfully. For HTTP traffic, for example, this is measured
      as the proportion of 2xx or 4xx responses over total responses. 
---

## API Gateway

An API gateway sits in front of an application and is designed to solve business
problems like authentication and authorization, rate limiting, and providing a
common access point for external consumers. A service mesh, in contrast, is
focused on providing operational (not business) logic between components of the
application.

## Control Plane

The control plane of a service mesh provides the command and control signals
required for the [data plane](#data-pane) to operate. The control plane controls
the data plane and provides the UI and API that operators use to configure,
monitor, and operate the mesh.

## Data Plane

The data plane of a service mesh comprises the deployment of its
[sidecar proxies](#sidecar-proxy) that intercept in-mesh application traffic.
The data plane is responsible for gathering metrics, observing traffic, and
applying policy.

## Distributed tracing

In a microservices-based system, an individual request from a client typically
triggers a series of requests across a number of services. Distributed tracing
is the practice of "tracing", or following, these requests as they move
through the distributed system for reasons of performance monitoring or
debugging. It is typically achieved by modifying the services to emit tracing
information, or "spans," and aggregating them in a central store.

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

## Load balancing
Load balancing is the act of distributing work across a number of equivalent
endpoints. Kubernetes, like many systems, provides load balancing at the
connection level. A service mesh like Linkerd improves this by performing
load balancing at the request level, which allows it to take into account
factors such as the performance of individual endpoints.

Load balancing at the request level also allows Linkerd to effectively
load balance requests for systems that use gRPC (and HTTP/2 more generally),
which multiplex requests across a single connection—Kubernetes itself
cannot effectively load balance these systems because there is typically
only one connection ever made.

Load balancing algorithms decide which endpoint will serve a given request.
The most common is "round-robin," which simply iterates across all endpoints.
More advanced balancing algorithms include "least loaded," which distributes
load based on the number of outstanding requests for each endpoint.
Linkerd itself uses a sophisticated latency-aware load balancing algorithm
called EWMA (exponentially-weighted moving average), to distribute load
based on endpoint latency while being responsive to rapid changes in the
latency profile of individual endpoints.

## Multi-cluster

In the context of Kubernetes, multi-cluster usually refers to running
an application "across" multiple Kubernetes clusters. Linkerd's multi-cluster
support provides seamless and secured communication across clusters, in a
way that's secure even across the open Internet, and is fully transparent
to the application itself.

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
