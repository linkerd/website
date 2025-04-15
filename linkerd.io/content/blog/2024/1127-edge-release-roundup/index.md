---
date: 2024-11-27T00:00:00Z
slug: linkerd-edge-release-roundup
title: |-
  Linkerd Edge Release Roundup: November 2024
description: |-
  What you need to know about the most recent Linkerd edge releases, November
  2024 edition!
keywords: [linkerd, edge, release, roundup]
params:
  author: flynn
  showCover: true
images: [social.jpg] # Open graph image
---

Welcome to the November 2024 Edge Release Roundup post, where we dive into the
most recent edge releases to help keep everyone up to date on the latest and
greatest! This month's Roundup is a little late due to KubeCon – we'll cover
the October edge releases here, then pick up again in early December to tackle
the flood of November edge releases that take us up to Linkerd 2.17!

## How to give feedback

Edge releases are a snapshot of our current development work on `main`; by
definition, they always have the most recent features but they may have
incomplete features, features that end up getting rolled back later, or (like
all software) even bugs. That said, edge releases _are_ intended for production
use, and go through a rigorous set of automated and manual tests before being
released.

We would be delighted to hear how these releases work out for you! You can open
[a GitHub issue](https://github.com/linkerd/linkerd2/issues/) or
[discussion](https://github.com/linkerd/linkerd2/discussions/), join us on
[Slack](https://slack.linkerd.io), or visit the
[Buoyant Linkerd Forum](https://linkerd.buoyant.io) -- all are great ways to
reach us.

## Community contributions

We couldn't do what we do without the Linkerd community, and this batch of
releases is definitely no exception. Huge thanks to [Aran Shavit], [Vadim
Makerov], and [@patest-dev] for their contributions! You'll find more
information about all of these contributions in the release-by-release details
below.

[Aran Shavit]: https://github.com/Aransh
[Vadim Makerov]: https://github.com/UsingCoding
[@patest-dev]: https://github.com/patest-dev

## Recommendations and breaking changes

All these releases are recommended for general use. There is one breaking
change, but it's a good breaking change: starting in [edge-24.10.5], a gRPC
request that hits a timeout will correctly return a `DEADLINE-EXCEEDED` gRPC
status rather than an `UNAVAILABLE` gRPC status. This is the way it really
should've always been, but it's still a breaking change.

Additionally, if you're using Linkerd multicluster, you'll probably be best
off jumping straight to [edge-24.10.3] or later: [edge-24.9.3] introduced a
change to the Link CRD that's not compatible with previous versions, and that
situation isn't fully resolved until [edge-24.10.3].

[edge-24.9.3]: https://github.com/linkerd/linkerd2/releases/tag/edge-24.9.3
[edge-24.10.1]: https://github.com/linkerd/linkerd2/releases/tag/edge-24.10.1
[edge-24.10.2]: https://github.com/linkerd/linkerd2/releases/tag/edge-24.10.2
[edge-24.10.3]: https://github.com/linkerd/linkerd2/releases/tag/edge-24.10.3
[edge-24.10.4]: https://github.com/linkerd/linkerd2/releases/tag/edge-24.10.4
[edge-24.10.5]: https://github.com/linkerd/linkerd2/releases/tag/edge-24.10.5

## The releases

October's releases are mostly cleaning up a few things before the final push
for Linkerd 2.17 in November, but there are a couple of new features here as
well! Of course, each edge release includes _many_ dependency updates which we
won't list here, but you can find them in the release notes for each release.

### edge-24.10.5 (October 31, 2024)

[edge-24.10.5] contains the only breaking change in the October releases: as
of this release, a gRPC request that hits a timeout will correctly return a a
`DEADLINE-EXCEEDED` gRPC status, rather than returning an `UNAVAILABLE` gRPC
status as in previous releases. This fix allows gRPC clients to properly
distinguish between a timeout and other errors, so it's an important change.

### edge-24.10.4 (October 24, 2024)

[edge-24.10.4] stops using `automountServiceAccountToken`, switching instead
to using explicitly-configured projected volumes for the ServiceAccountTokens
we need, helping Linkerd comply with current best practices around Kubernetes
security (thanks, [Aran Shavit]!). Additionally, this release updates the
deprecation text for `v1beta1` of the Server CRD; anyone using that version
should go ahead and upgrade to Server `v1beta3` (thanks, [@patest-dev]!).

### edge-24.10.3 (October 17, 2024)

[edge-24.10.3] improves outbound HTTP and gRPC metrics by adding `hostname`
and `zone_locality` labels, providing the hostname and zone used for the
target. It also improves distributed tracing by allowing configuring the
service name for Linkerd's distributed traces (fixing [#11157]) and by fixing
a bug where the `linkerd-jaeger` injector could mistakenly alter annotations
it shouldn't have.

This release also fixes a bug where the CNI plugin would silently fail if the
underlying Node hit the `inotify` limit -- the plugin will now catch the error
and crash, which will surface the problem so the cluster operators notice it
and fix it. Finally, [edge-24.10.3] fully fixes `linkerd multicluster link` so
that it produces YAML that can be applied into clusters running versions prior
to [edge-24.9.3].

[#11157]: https://github.com/linkerd/linkerd2/issues/11157

### edge-24.10.2 (October 10, 2024)

_If you're using Linkerd multicluster, you should consider going straight to
[edge-24.10.3] to avoid compatibility issues with clusters running versions
prior to [edge-24.9.3]._

This release fixes an error in the CLI in order to allow the `linkerd
multicluster` CLI commands to work correctly even when some of the clusters in
a multicluster setup are running releases prior to `edge-24.9.3`.
Additionally, creating a link with `linkerd multicluster link --set
enableNamespaceCreation=true` will allow Linkerd multicluster to create the
namespace into which it mirrors services.

### edge-24.10.1 (October 3, 2024)

_If you're using Linkerd multicluster, you should consider going straight to
[edge-24.10.3] to avoid compatibility issues with clusters running versions
prior to [edge-24.9.3]._

[edge-24.10.1] introduces native OpenTelemetry support in the
(increasing-misnamed) `linkerd-jaeger` extension: use `--set
webhook.collectorTraceProtocol=opentelemetry` when installing `linkerd-jaeger`
to take advantage of that. For now, the default is still to use the OpenCensus
wire protocol, but that's likely to change in the future.

Additionally, the proxy addresses issue [#13023] by setting a 30-second
`TCP_USER_TIMEOUT` on TCP connections to allow Linkerd to do a better job of
cleaning up half-open connections (thanks, [Vadim Makerov]!)

[#13023]: https://github.com/linkerd/linkerd2/issues/13023

## Installing the latest edge release

Installing the latest edge release needs just a single command.

```bash
curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install-edge | sh
```

You can also
[install edge releases with Helm](https://linkerd.io/2/tasks/install-helm/).

## Linkerd is for everyone

Linkerd is a graduated project of the
[Cloud Native Computing Foundation](https://cncf.io/). Linkerd is
[committed to open governance.](/2019/10/03/linkerds-commitment-to-open-governance/)
If you have feature requests, questions, or comments, we'd love to have you join
our rapidly-growing community! Linkerd is hosted on
[GitHub](https://github.com/linkerd/), and we have a thriving community on
[Slack](https://slack.linkerd.io/), [Twitter](https://twitter.com/linkerd), and
in [mailing lists](/community/get-involved/). Come and join the fun!

---

_Linkerd generally does new edge releases weekly; watch this space to keep
up-to-date. Feedback on this blog series is welcome! Just ping `@flynn` on the
[Linkerd Slack](https://slack.linkerd.io)._
