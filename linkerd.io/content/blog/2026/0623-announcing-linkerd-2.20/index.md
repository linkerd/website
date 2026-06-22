---
date: 2026-06-23T00:00:00Z
slug: announcing-linkerd-2.20
title: |-
  Announcing Linkerd 2.20: Rate-limit-aware load balancing, reduced memory usage, better inbound metrics, and more
keywords: [linkerd, "2.20", features]
params:
  author: william
  showCover: true
---

Linkerd 2.20 is now available! This release improves circuit breaking and load
balancing to be aware of rate limit responses, significantly improves memory
consumption of the control plane (especially on busy clusters), and improves
Linkerd’s metrics suite for inbound traffic. This release also promotes native
sidecars to the default deployment type for Linkerd’s data plane microproxies.

Linkerd has now seen almost a decade of continuous improvement and evolution.
Our goal is to build a service mesh that our users can rely on for 100 years.
Linkerd 2.20 is the fourth major version since the [announcement of Buoyant's
profitability and Linkerd project
sustainability](https://buoyant.io/blog/linkerd-forever), and continues our
laser focus on operational simplicity: delivering the notoriously complex
service mesh feature set in a way that is manageable, scalable, and performant.

## Related announcements

- [Announcing Buoyant Enterprise for Linkerd 2.20: Automated trust anchor
  rotation, Windows VM support, rate-limit-aware load balancing, and
  more](https://buoyant.io/blog/bel-2-20-automated-trust-anchor-rotation-windows-vm-support-rate-limit-aware-load-balancing/)

## Rate-limit-aware load balancing

Since its inception, one of Linkerd’s most powerful features has been its
latency-aware load balancing. When distributing individual HTTP or gRPC requests
across endpoints, this algorithm weights available endpoints by the
exponentially-weighted moving average (EWMA) of their latency—allowing it to
react quickly to latency spikes—and automatically favors endpoints that are
currently responding the quickest. Load balancing is often paired with another
powerful client-side feature, circuit breaking, which automatically ejects
endpoints that return too many 5xx error responses, preventing Linkerd from
sending traffic to endpoints that are failing, even if they’re failing quickly!

In this release, we’ve extended the logic of both load balancing and circuit
breaking to handle rate-limited services that return HTTP 429 (or gRPC
`RESOURCE_EXHAUSTED`) responses. These services aren’t failing, per se, but they
are explicitly signaling that they aren’t able to handle more traffic. (Note
that these responses may even originate from Linkerd’s rate-limiting feature
running on the service!)

Linkerd can now be configured to respect these response codes, biasing traffic
away from overloaded endpoints or even removing them entirely from the pool.

## Control plane memory improvements

Linkerd’s control plane is the component responsible for, among many other
things, reflecting the state of the Kubernetes clusters in such a way that
Linkerd’s data plane microproxies are up-to-date. One critical part of the
control plane is the destination controller, which maintains a map of everything
on the cluster that a meshed pod might be asked to talk to.

Because it needs to model the state of the cluster, the destination controller
is typically responsible for the majority of Linkerd’s control plane memory
usage, especially in high-scale environments. In Linkerd 2.20, we’ve refactored
the destination controller to optimize its internal state management, cutting
memory usage in some cases by almost 85%. Linkerd users in large or fast-moving
clusters with lots of pod churn should notice a dramatic improvement in
Linkerd’s memory consumption.

## Proxy metrics, tracing, and OpenTelemetry improvements

Linkerd provides a rich set of metrics for all traffic it sees, especially if
that traffic is HTTP (including gRPC). This includes metrics around request
latencies, success rates, and much more.

Historically, these metrics have focused on the “outbound” side of Linkerd:
traffic that leaves the pod. In Linkerd 2.20 we've greatly improved the set of
metrics available for the inbound side of Linkerd (traffic entering the pod),
and brought them up to near parity with the outbound side. This includes new
metrics for the volume and statuses of inbound requests, as well as new
histograms tracking the distribution of request and response durations and frame
sizes (tracked separately for HTTP and gRPC traffic).

In designing these new metrics, we've also continued improving Linkerd’s
compliance with OpenTelemetry semantic conventions as well as making sure
distributed tracing spans get sent to OpenTelemetry regularly, so that operators
can better reason about the traffic on their clusters.

## Other fun stuff

Linkerd 2.20 brings our maximum supported Kubernetes versions up to 1.35 and our
maximum supported Gateway API version up to 1.5.1.

Linkerd 2.20 also promotes native sidecar support to stable and makes it the
default for proxy injection. Native sidecars [fix some of the long-standing
annoyances of using sidecar containers in
Kubernetes](https://buoyant.io/blog/kubernetes-1-28-revenge-of-the-sidecars/),
especially around support for Jobs and race conditions around container startup.
Support for native sidecars was first introduced in Linkerd 2.15, promoted to
beta in 2.19, and has seen extensive use in production.

## Getting your hands on Linkerd 2.20

See our [releases and versions](/releases/) page for how to get ahold of a
Linkerd 2.20 package. Happy meshing!

## Linkerd is for everyone

Linkerd is a graduated project of the
[Cloud Native Computing Foundation](https://cncf.io/). Linkerd is
[committed to open governance.](/2019/10/03/linkerds-commitment-to-open-governance/)
If you have feature requests, questions, or comments, we’d love to have you join
our rapidly-growing community! Linkerd is hosted on
[GitHub](https://github.com/linkerd/), and we have a thriving community on
[Slack](https://slack.linkerd.io/), [Twitter](https://twitter.com/linkerd), and
the [mailing lists](/community/get-involved/). Come and join the fun!

## Photo credit

Photo by [José Pablo
Domínguez](https://unsplash.com/@jdomito?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText)
on
[Unsplash](https://unsplash.com/photos/person-holding-yellow-and-black-coated-wires-0iYBXndHztQ?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText)
