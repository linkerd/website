+++
aliases = ["/tutorials/"]
description = "Provides concrete instructions for setting up and running Linkerd in various environments. Go here for a quick start."
title = "Overview"
weight = 1
[menu.docs]
identifier = "tutorials"
name = "Tutorials"
weight = 6

+++
These tutorials exist to walk you through several sample concepts for practical
application of a service mesh. Linkerd can be used on several platforms but, for
simplicity, this section uses Kubernetes (via GKE or Minikube) so that you can
see how these concepts apply against a real environment.

---

## Introduction

One of the most common questions when getting started with Linkerd is: what
exactly is a service mesh? Why is a service mesh a critical component of cloud
native apps, when environments like Kubernetes provide primitives like service
objects and load balancers?

A service mesh is a layer that manages the communication between apps (or between
parts of the same app, e.g. microservices). In traditional apps, this logic is
built directly into the application itself: retries and timeouts,
monitoring/visibility, tracing, service discovery, etc. are all hard-coded into
each application.

However, as application architectures become increasingly segmented into services,
moving communications logic out of the application and into the underlying
infrastructure becomes increasingly important. Just as applications shouldn’t be
writing their own TCP stack, they also shouldn’t be managing their own load
balancing logic, or their own service discovery management, or their own retry
and timeout logic. (For example, see [Oliver Gould’s MesosCon talk](https://www.youtube.com/watch?v=VGAFFkn5PiE#t=23m47)
for more about the difficulty of coordinating retries and timeouts across multiple
services.)

The Linkerd service mesh provides critical features to multi-service applications
running at scale:

- **Baseline resilience**: retry budgets, deadlines, circuit-breaking.
- **Top-line service metrics**: success rates, request volumes, and latencies.
- **Latency and failure tolerance**: Failure- and latency-aware load balancing
that can route around slow or broken service instances.
- **Distributed tracing** a la [Zipkin](https://github.com/openzipkin/zipkin)
and [OpenTracing](http://opentracing.io/)
- **Service discovery**: locate destination instances.
- **Protocol upgrades**: wrapping cross-network communication in TLS, or
converting HTTP/1.1 to HTTP/2.0.
- **Routing**: route requests between different versions of services, failover
between clusters, etc.

---

The tutorials in this series include:

{{% sectiontoc "tutorials" %}}
