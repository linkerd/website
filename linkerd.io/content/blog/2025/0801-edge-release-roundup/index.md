---
date: 2025-08-01T00:00:00Z
slug: linkerd-edge-release-roundup-202508
title: |-
  Linkerd Edge Release Roundup: August 2025
description: |-
  What you need to know about the most recent Linkerd edge releases,
  August 2025 edition!
keywords: [linkerd, edge, release, roundup]
params:
  author: flynn
  showCover: true
images: [social.jpg] # Open graph image
---

Welcome to the August 2025 Edge Release Roundup post, where we dive into the
most recent edge releases to help keep everyone up to date on the latest and
greatest! This post covers edge releases from June and July 2025.

## How to give feedback

Edge releases are a snapshot of our current development work on `main`; by
definition, they always have the most recent features but they may have
incomplete features, features that end up getting rolled back later, or (like
all software) even bugs. That said, edge releases _are_ intended for
production use, and go through a rigorous set of automated and manual tests
before being released. Once released, we also document whether the release is
recommended for broad use -- and when needed, we go back and update the
recommendations.

We would be delighted to hear how these releases work out for you! You can open
[a GitHub issue](https://github.com/linkerd/linkerd2/issues/) or
[discussion](https://github.com/linkerd/linkerd2/discussions/), join us on
[Slack](https://slack.linkerd.io), or visit the
[Buoyant Linkerd Forum](https://linkerd.buoyant.io) -- all are great ways to
reach us.

## Community contributions

We couldn't do what we do without the Linkerd community, and this batch of
releases is definitely no exception. Huge thanks to [Carlos Martell], [Jonas
Dittrich], [Wim de Groot], and [joedrf] for their contributions! You'll find
more information about all of these contributions in the release-by-release
details below.

[Carlos Martell]: https://github.com/cmartell-at-m42
[Jonas Dittrich]: https://github.com/kakadus
[Wim de Groot]: https://github.com/wim-de-groot
[joedrf]: https://github.com/joedrf

## Recommendations and breaking changes

**We recommend that everyone running an edge release go straight to
[edge-25.7.6].** If you can't run that version for some reason, check out
[edge-25.7.4].

The reason for this unusually blunt recommendation is that [edge-25.7.4] fixes
a bug that could cause Linkerd to use more memory than it should when dealing
with a lot of HTTP/1 connections, and we'd really like everyone to benefit
from that fix... and since [edge-25.7.6] adds some more features on top of
that, we think it's a good idea to go straight to that version.

As always, we have a couple of breaking changes to note:

* As of [edge-25.7.1], Linkerd will refuse connections to a Service port that
  isn't listed in the Service's `spec.ports`, which mirrors Kubernetes's
  behavior without Linkerd and should help avoid surprises.

* In [edge-25.6.3], we changed the histogram buckets for gRPC handling-time
  histograms. The previous buckets were optimized for short-lived streams,
  where Linkerd's controllers typically use much longer-lived streams. The
  updated bucket sizes are much better suited to the longer lifetimes.

* Also in [edge-25.6.3], we updated the port names used in many Linkerd
  deployments to avoid Kubernetes 1.33's new warnings if port names aren't
  unique across all containers in the same pod:

  * In `destination`, `grpc` becomes `dest-grpc` and `admin-http` becomes `dest-admin`
  * In `sp-validator`, `admin-http` becomes `spval-admin`
  * In `policy-controller`, `grpc` becomes `policy-grpc` and `admin-http`
    becomes `policy-admin`
  * In `identity`, `grpc` becomes `ident-grpc` and `admin-http` becomes `ident-admin`
  * In `proxy-injector`, `admin-http` becomes `injector-admin`
  * In `linkerd2-cni`, `admin-http` becomes `repair-admin`

[edge-25.7.6]: https://github.com/linkerd/linkerd2/releases/tag/edge-25.7.6
[edge-25.7.5]: https://github.com/linkerd/linkerd2/releases/tag/edge-25.7.5
[edge-25.7.4]: https://github.com/linkerd/linkerd2/releases/tag/edge-25.7.4
[edge-25.7.3]: https://github.com/linkerd/linkerd2/releases/tag/edge-25.7.3
[edge-25.7.2]: https://github.com/linkerd/linkerd2/releases/tag/edge-25.7.2
[edge-25.7.1]: https://github.com/linkerd/linkerd2/releases/tag/edge-25.7.1
[edge-25.6.4]: https://github.com/linkerd/linkerd2/releases/tag/edge-25.6.4
[edge-25.6.3]: https://github.com/linkerd/linkerd2/releases/tag/edge-25.6.3
[edge-25.6.2]: https://github.com/linkerd/linkerd2/releases/tag/edge-25.6.2
[edge-25.6.1]: https://github.com/linkerd/linkerd2/releases/tag/edge-25.6.1

## The releases

As always, each edge release includes _many_ dependency updates which we won't
list here. You can find them in the full release notes for each release.

### [edge-25.7.6] (July 31, 2025)

_This release is recommended for all users, and is most likely the one you should
run if you're reading this post._

This release supports percentages, as well as integers, when setting the `maxUnavailable` field in the `podDisruptionBudget` in Helm values (thanks, [Wim de Groot]!), cleans up the descriptions for some proxy metrics (thanks, [joedrf]!), produces auditable binaries for the policy controller and proxy, and prefers AES algorithms over ChaCha20 for mTLS. It also correctly performs reproducible builds, fixing issue [#13873].

[#13873]: https://github.com/linkerd/linkerd2/issues/13873

### [edge-25.7.5] (July 23, 2025)

This release contains internal improvements, but no new capabilities over
[edge-25.7.4]. As such, we recommend that you skip it and go straight to
[edge-25.7.6]!

### [edge-25.7.4] (July 17, 2025)

_This release is recommended for all users._

This release contains a fix to reduce the proxy's memory usage when handling
many HTTP/1 connections.

### [edge-25.7.3] (July 15, 2025)

_This release is **not recommended**; use [edge-25.7.4] instead, or just go
straight to [edge-25.7.6]._

This release reintroduces idle timeouts for HTTP/1 connections, and supports
the AES_256_GCM cipher for mTLS. It also fixes an issue ([#14228]) where the
Helm chart could fail to render when upgrading from a previous version.

[#14228]: https://github.com/linkerd/linkerd2/issues/14228

### [edge-25.7.2] (July 11, 2025)

_This release is **not recommended**; use [edge-25.7.4] instead, or just go
straight to [edge-25.7.6]._

This release fixes an issue ([#14176]) where a Server resource with invalid
selectors could prevent other Servers from being used.

[#14176]: https://github.com/linkerd/linkerd2/issues/14176

### [edge-25.7.1] (July 02, 2025)

_This release is **not recommended**; use [edge-25.7.4] instead, or just go
straight to [edge-25.7.6]._

This release will no longer permit connections to a Service IP using a port
that is not listed in the Service's `spec.ports`, in order to fix [#13922] and
to make Linkerd's behavior align with current Kubernetes behavior. It also
removes duplicate metrics keys from the proxy, and removes
`preserveUnknownFields` from the `linkerd-crds` Helm chart's ServiceProfile
template (thanks, [Carlos Martell]!).

[#13922]: https://github.com/linkerd/linkerd2/issues/13922

### [edge-25.6.4] (June 26, 2025)

_This release is **not recommended**; use [edge-25.7.4] instead, or just go
straight to [edge-25.7.6]._

This release allows configuring OpenTelemetry tracing without installing the
`linkerd-jaeger` extension, and fixes an issue where the `caBundle` field in
the Helm chart was not being set correctly when using PEM-encoded CA
certificates (thanks, [Jonas Dittrich]!). It also allows using a named pipe
for SPIRE when running the proxy for Windows mesh expansion, and removes an
unintentionally-added HTTP/1 header read timeout.

### [edge-25.6.3] (June 18, 2025)

_This release is **not recommended**; use [edge-25.7.4] instead, or just go
straight to [edge-25.7.6]._

This release changes the histogram buckets for gRPC handling-time histograms.
The new buckets better line up with the long-lived streams used in Linkerd’s
controllers. It also fixes an issue ([#14103]) where inbound policy couldn't
be applied to the metrics port when using native sidecars, and adds common
gRPC server metrics to the policy controller.

[#14103]: https://github.com/linkerd/linkerd2/issues/14103

Finally, it updates the port names used in many Linkerd deployments for
uniqueness, since Kubernetes 1.33 warns when port names are not unique within
containers in the same pod:

* In `destination`, `grpc` becomes `dest-grpc` and `admin-http` becomes
  `dest-admin`
* In `sp-validator`, `admin-http` becomes `spval-admin`
* In `policy-controller`, `grpc` becomes `policy-grpc` and `admin-http`
  becomes `policy-admin`
* In `identity`, `grpc` becomes `ident-grpc` and `admin-http` becomes
  `ident-admin`
* In `proxy-injector`, `admin-http` becomes `injector-admin`
* In `linkerd2-cni`, `admin-http` becomes `repair-admin`

### [edge-25.6.2] (June 12, 2025)

_This release is **not recommended**; use [edge-25.7.4] instead, or just go
straight to [edge-25.7.6]._

This release contains internal improvements, but no new capabilities over
edge-25.6.1.

### [edge-25.6.1] (June 05, 2025)

_This release is **not recommended**; use [edge-25.7.4] instead, or just go
straight to [edge-25.7.6]._

This release fixes a bug ([#14050]) where turning on retries could cause
failures with HTTP/2 traffic (notably when using gRPC).

[#14050]: https://github.com/linkerd/linkerd2/issues/14050

## Installing the latest edge release

Installing the latest edge release needs just a single command.

```bash
curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install-edge | sh
```

You can also
[install edge releases with Helm](/2/tasks/install-helm/).

## Linkerd is for everyone

Linkerd is a graduated project of the
[Cloud Native Computing Foundation](https://cncf.io/). Linkerd is
[committed to open governance.](/2019/10/03/linkerds-commitment-to-open-governance/)
If you have feature requests, questions, or comments, we'd love to have you join
our rapidly growing community! Linkerd is hosted on
[GitHub](https://github.com/linkerd/), and we have a thriving community on
[Slack](https://slack.linkerd.io/), [Twitter](https://twitter.com/linkerd), and
in [mailing lists](/community/get-involved/). Come and join the fun!

---

_Linkerd generally does new edge releases weekly; watch this space to keep
up-to-date. Feedback on this blog series is welcome! Just ping `@flynn` on the
[Linkerd Slack](https://slack.linkerd.io)._
