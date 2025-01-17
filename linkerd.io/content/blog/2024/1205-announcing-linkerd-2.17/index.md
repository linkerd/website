---
date: 2024-12-05T00:00:00Z
slug: announcing-linkerd-2.17
title: |-
  Announcing Linkerd 2.17: Egress, Rate Limiting, and Federated Services
keywords: [linkerd, "2.17", features]
params:
  author: william
  showCover: true
---

Today we're happy to announce the release of Linkerd 2.17, a new version of
Linkerd that introduces several major new features to the project: egress
traffic visibility and control; rate limiting; and _federated services,_ a
powerful new multicluster primitive that combines services running in multiple
clusters into a single logical service. This release also updates Linkerd to
support OpenTelemetry for distributed tracing.

Linkerd 2.17 is our first major release since our
[announcement of Linkerd's sustainability in October](/2024/10/23/making-linkerd-sustainable/).
Not unrelatedly, it is one of the first Linkerd releases in years to introduce
multiple significant features at once. Despite this, we worked hard to stay true
to Linkerd's core design principle of _simplicity_. For example, these new
features are designed to avoid configuration when possible; and when not
possible, to make it minimal, consistent, and principled. After all, Linkerd's
simplicity—our rejection of the status quo that says, "the service mesh is
complex and must be complex"—is key to its popularity, and it's our duty to live
up to that reputation in this and every release.

Read on for more!

## Egress visibility and control

Linkerd 2.17 introduces visibility and control for egress traffic leaving the
Kubernetes cluster from meshed pods. Kubernetes itself provides no mechanisms
for understanding egress traffic, and only rudimentary ones for restricting it,
limited to IP ranges and ports. With the 2.17 release, Linkerd now gives you
full L7 (i.e. application-layer) visibility and control of all egress traffic:
you can view the source, destination, and traffic levels of all traffic leaving
your cluster, including the hostnames, and, with configuration, the full HTTP
paths or gRPC methods. You also can deploy _egress security policies_ that allow
or disallow that traffic with that same level of granularity, allowing you to
allowlist or blocklist egress by DNS domain rather than IP range and port.

Linkerd's egress functionality does not require changes from the application and
only minimal configuration to get started. For more advanced usage, egress
configuration is built on Gateway API resources, allowing you to configure
egress visibility and policies with the same extensible and Kubernetes-native
configuration primitives used for almost every other aspect of Linkerd,
including dynamic traffic routing, zero trust authorization policies, and more.

For example, enabling basic egress metrics across the entire cluster is as
simple as adding this configuration:

```yaml
apiVersion: policy.linkerd.io/v1alpha1
kind: EgressNetwork
metadata:
  namespace: linkerd-egress
  name: all-egress-traffic
spec:
  trafficPolicy: Allow
```

See [egress docs](/2.17/features/egress/) for more.

## Rate limiting

Rate limiting is a reliability mechanism that protects services from being
overloaded. In contrast to
[Linkerd's circuit breaking feature](/2/reference/circuit-breaking/), which is
client-side behavior designed to protect clients from failing services, rate
limiting is server-side behavior: it is enforced by the service receiving the
traffic and designed to protect it from misbehaving clients.

Just as with egress, Linkerd's rate limiting feature is designed to require
minimal configuration, while still being flexible and configurable to a wide
variety of scenarios. For example, a basic rate limit of 100 requests per second
for a Server named "web-http" can be enabled with this configuration:

```yaml
apiVersion: policy.linkerd.io/v1alpha1
kind: HTTPLocalRateLimitPolicy
metadata:
  namespace: emojivoto
  name: web-rlpolicy
spec:
  targetRef:
    group: policy.linkerd.io
    kind: Server
    name: web-http
  total:
    requestsPerSecond: 100
```

Linkerd's rate limiting feature also provides _per-client_ rate limit policies
that allow you to ensure rate limits are distributed "fairly" across multiple
clients. Combined with retries, timeouts, circuit breaking, latency-aware load
balancing, and dynamic traffic routing, rate limiting extends Linkerd's already
wide arsenal of in-cluster distributed system reliability features.

See [rate limiting docs](/2.17/features/rate-limiting/) for more.

## Federated services

In Linkerd 2.17 we've shipped an exciting new multicluster feature: _federated
services_. A federated service is a logical union of the replicas of the same
service across multiple clusters. Meshed clients talking to a federated service
will automatically load balance across all endpoints in all clusters, taking
full advantage of Linkerd's best-in-class latency-aware load balancing.

With federated services, not only is application code decoupled from cluster
deployment decisions—service _Foo_ talking to service _Bar_ needs only to call
"Bar", not to specify which cluster(s) it is on—but failure handling is
transparent and automatic as well. Linkerd will transparently handle a wide
variety of situations, including:

- An entire cluster is down
- A cluster is up but the service on that cluster is down, or failing in some
  way (including L7 failures, e.g. returning 5xx response codes)
- A cluster is slow, or the service is slow

In all these cases, Linkerd will automatically load balance across all service
endpoints on all clusters, using its default latency-aware (latency EWMA)
balancing to send individual requests to the best endpoint.

Federated services were designed to capture a recent trend we see in
multicluster Kubernetes adoption: _planned large-scale multicluster_ Kubernetes.
Linkerd's original multicluster functionality, released in the good ol' days of
Linkerd 2.8, was designed for the ad-hoc, pair-to-pair connectivity that was
common at the time. However, modern Kubernetes platforms are often much more
intentional in their multicluster usage, sometimes ranging into the hundreds or
thousands of clusters. Federated services join features such as
[flat network / pod-to-pod multicluster](/2/tasks/pod-to-pod-multicluster/)
(introduced in Linkerd 2.14) in the toolbox for this new class of Kubernetes
adoption.

See [federated services docs](/2.17/features/multicluster/#federated-services)
for more.

## Linkerd Day at Kubecon London

We're delighted to report that
[the CNCF is hosting Linkerd Day](https://events.linuxfoundation.org/kubecon-cloudnativecon-europe/co-located-events/linkerd-day/)
at Kubecon London next April! Many of the Linkerd maintainers will be in
attendance, and we're expecting a great lineup of Linkerd talks as well as
plenty of Linkerd users. Come see us in London!

## How to get Linkerd 2.17

The
[edge-24.11.8](https://github.com/linkerd/linkerd2/releases/tag/edge-24.11.8)
release is the corresponding edge release for Linkerd 2.17. See the
[Linkerd releases page](/releases/) for more.

[Buoyant](https://buoyant.io/), the creators of Linkerd, has additionally
released
[Buoyant Enterprise for Linkerd 2.17.0](https://buoyant.io/blog/announcing-linkerd-2-17/)
and published a
[Linkerd 2.17 changelog](https://docs.buoyant.io/release-notes/buoyant-enterprise-linkerd/enterprise-2.17.0/)
with additional guidance and content.

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

Photo by
[Aliaksei Semirski](https://www.pexels.com/photo/racer-balancing-sidecar-motocross-26436389/).
