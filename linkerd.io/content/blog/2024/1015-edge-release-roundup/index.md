---
date: 2024-10-15T00:00:00Z
slug: linkerd-edge-release-roundup
title: |-
  Linkerd Edge Release Roundup: October 2024
description: |-
  What you need to know about the most recent Linkerd edge releases, October
  2024 edition!
keywords: [linkerd, edge, release, roundup]
params:
  author: flynn
  showCover: true
images: [social.jpg] # Open graph image
---

Welcome to the October 2024 Edge Release Roundup post, where we dive into the
most recent edge releases to help keep everyone up to date on the latest and
greatest!

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
releases is definitely no exception. Huge thanks to [Lauri Kuittinen], [Vadim
Makerov], and [@kristjankullerkann-wearemp] for their contributions! You'll find
more information about all of these contributions in the release-by-release
details below.

[Lauri Kuittinen]: https://github.com/lauriku
[Vadim Makerov]: https://github.com/UsingCoding
[@kristjankullerkann-wearemp]: https://github.com/kristjankullerkann-wearemp

## Recommendations and breaking changes

All these releases are recommended for general use. There is one breaking
change: starting in [`edge-24.9.2`], the timestamp in JSON-formatted proxy logs
are now ISO8601 strings (for example, `2024-09-09T13:38:56.919918Z`). This is an
oft-requested feature but, of course, still a breaking change.

Additionally, it's important to realize that [`edge-24.9.3`] introduces a change
to the Link CRD that's not compatible with previous versions of the Linkerd CLI.
If you're using Linkerd multicluster, you'll need to either upgrade every
linkerd cluster to [`edge-24.9.3`] at the same time, or plan to hold off until
[`edge-24.10.2`].

## The releases

September's releases bring in some new improvements to Linkerd statistics and
also some important bugfixes. Of course, each edge release includes _many_
dependency updates which we won't list here, but you can find them in the
release notes for each release.

[`edge-24.9.3`]: https://github.com/linkerd/linkerd2/releases/tag/edge-24.9.3
[`edge-24.9.2`]: https://github.com/linkerd/linkerd2/releases/tag/edge-24.9.2
[`edge-24.10.2`]: https://github.com/linkerd/linkerd2/releases/tag/edge-24.10.2

### edge-24.9.3 (September 27, 2024)

`edge-24.9.3` fixes a panic that would occur if a retried response arrived
before the retried request was complete. This may sound bizarre, but it is
allowed by the HTTP/2 specification, and using `wire-gprc` with retries enabled
tended to trip over this in the real world.

This release also supports configuring the timeout and failure threshold for
health probes for the multicluster gateway, to improve reliability in the face
of networking issues between clusters. A caution with `edge-24.9.3` is that its
CLI will have trouble with linkerd clusters that are running earlier releases
(looking into the future a bit, `edge-24.10.2` fixes this issue).

### edge-24.9.2 (September 12, 2024)

Starting in `edge-24.9.2`, JSON-formatted proxy logs render timestamps as
ISO8601 strings, rather than fractional seconds since proxy startup (fixing
[issue 12505]). For example, you might see a log like

```json {class=disable-copy}
{
  "timestamp": "2024-09-09T13:38:56.919918Z",
  "level": "INFO",
  "fields": { "message": "Using single-threaded proxy runtime" },
  "target": "linkerd2_proxy::rt",
  "threadId": "ThreadId(1)"
}
```

This release also publishes quite a few new [internal metrics] to provide
insight into how the proxy runtime is performing, and publishes the proxy's
current time as a metric, which should make it easier to be sure of when
certificates will need to be rotated. It also allows setting `TCP_USER_TIMEOUT`
for TCP sockets (thanks, [Vadim Makerov]!), updates the Helm documentation to
include recently-added values, and removes some redundant dashes in the identity
controller's Helm templates. Finally, Linkerd Viz in this release supports
reading credentials from a Secret for using Prometheus with HTTP Basic
authentication.

[internal metrics]:
  https://github.com/tokio-rs/tokio-metrics?tab=readme-ov-file#task-metrics
[issue 12505]: https://github.com/linkerd/linkerd2/issues/12505

### edge-24.9.1 (September 6, 2024)

In `edge-24.9.1`, Linkerd Viz gets the new `linkerd viz stat-inbound` and
`linkerd viz stat-outbound` commands, which provide cleaner access from the
command line to the new metrics available based on Gateway API routes, for
example:

```bash {class=disable-copy}
$ linkerd viz stat-outbound -n faces deploy/face
NAME  SERVICE    ROUTE         TYPE       BACKEND     SUCCESS   RPS  LATENCY_P50  LATENCY_P95  LATENCY_P99  TIMEOUTS  RETRIES
face  smiley:80  smiley-route  HTTPRoute               78.36%  6.32         41ms       5886ms       9177ms     0.00%    0.00%
                 ├─────────────────────►  smiley:80    79.34%  5.57         20ms       5725ms       9145ms     0.00%
                 └─────────────────────►  smiley2:80   71.11%  0.75         22ms       6850ms       9370ms     0.00%
face  color:80   color-route   GRPCRoute               80.10%  6.37         25ms         48ms         50ms     0.00%    0.00%
                 ├─────────────────────►  color:80     80.12%  2.68         12ms         24ms         25ms     0.00%
                 └─────────────────────►  color2:80    80.00%  3.67         12ms         24ms         25ms     0.00%
```

In this example, we have traffic splitting set up using GRPCRoutes and
HTTPRoutes.

This release also adds dualstack support for ExternalWorkload, Helm support for
tuning liveness and readiness probe timeouts (thanks
[@kristjankullerkann-wearemp]!), and Helm support for configuring
externalTrafficPolicy for multicluster gateways (thanks [Lauri Kuittinen]!).

## Installing the latest edge release

Installing the latest edge release needs just a single command.

```bash
curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install-edge | sh
```

You can also [install edge releases with Helm](/2.15/tasks/install-helm/).

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
