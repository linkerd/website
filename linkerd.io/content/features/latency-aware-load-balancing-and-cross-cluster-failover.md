---
title: Latency-aware load balancing and cross-cluster failover
description: Instantly add latency-aware load balancing, request retries, timeouts, and blue-green deploys to keep your applications resilient.
layout: feature
top_hero:
  title: Latency-aware load balancing and cross-cluster failover
  icon: /uploads/features/balance.svg
---

One of Linkerd's most important capabilities is its ability to deliver a uniform
layer of platform health metrics to any Kubernetes application. This includes
the "golden metrics" of success rate (or error rate) of requests, the latency
of requests, and the volume of traffic in requests and bytes. It also includes
distributed tracing and system topology graphs.

This level of visibility is critical to modern distributed applications that are
built as multi-service (microservice) architectures. While these systems can be
deployed to Kubernetes as a way of managing scale and complexity, Kubernetes
itself does not provide any visibility into the traffic between systems.

This powerful capability is only possible because Linkerd can rapidly analyze
and proxy L7 traffic including HTTP, HTTP/2, and gRPC traffic. In contrast to
CNIs like Calico and Cilium, which can only operate at L4, Linkerd has access to
 the full request header and body, allowing it to provide per-service metrics
 ("what is the latency of the Foo service"),  per-route metrics ("what is the
 success rate of /bar on Foo"), and per-client metrics (e.g. "what is the rate
 of HTTP calls to Foo from Baz?")

## Observability with Linkerd

{{< youtube up3fKwXdEgc >}}

Best of all, because of Linkerd's ultralight "microproxy" approach, this
critical level of visibility is attainable without application changes, and
without unnecessary resource consumption, and Linkerd's metrics can be combined
with any modern timeseries database that is capable of understanding the
industry standard Prometheus format.

**Learn more:**

- [Linkerd vs Cilium](/)
- [Per-route metrics guide](/)
- [Distributed tracing guide](/)
- [Bring your own prometheus guide](/)
