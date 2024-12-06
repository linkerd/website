---
date: 2024-06-06T00:00:00Z
slug: linkerd-edge-release-roundup
title: |-
  Linkerd Edge Release Roundup: June 2024
description: |-
  What you need to know about the most recent Linkerd edge releases, June 2024
  edition!
keywords: [linkerd, edge, release, roundup]
params:
  author: flynn
  showCover: true
  thumbnail: /2023/06/21/linkerd-edge-roundup/thumbnail.png
  cover: /2023/06/21/linkerd-edge-roundup/cover.png
images: [/2023/06/21/linkerd-edge-roundup/cover.png] # Open graph image
---

Welcome to the June 2024 Edge Release Roundup post, where we dive into the most
recent edge releases to help keep everyone up to date on the latest and
greatest!

## How to give feedback

Remember, edge releases are a snapshot of our current development work on
`main`; by definition, they always have the most recent features but they may
have incomplete features, features that end up getting rolled back later, or
(like all software) even bugs. That said, edge releases _are_ intended for
production use, and go through a rigorous set of automated and manual tests
before being released.

We would be delighted to hear how these releases work out for you! You can open
[a GitHub issue](https://github.com/linkerd/linkerd2/issues/) or
[discussion](https://github.com/linkerd/linkerd2/discussions/), join us on
[Slack](https://slack.linkerd.io), or visit the
[Buoyant Linkerd Forum](https://linkerd.buoyant.io) -- all are great ways to
reach us.

## Community contributions

We couldn't do what we do without the Linkerd community, and this batch of
releases is definitely no exception. Huge thanks to [knowmost], [Marwan Ahmed],
and [Nico Feulner] for their contributions! You'll find more information about
all of these contributions in the release-by-release details below.

[knowmost]: https://github.com/knowmost
[Marwan Ahmed]: https://github.com/marwanad
[Nico Feulner]: https://github.com/nico151999

## Recommendations and breaking changes

We recommend `edge-24.5.5` for anyone considering an `edge-24.5.*` release; it
has important fixes for the Linkerd CNI plugin on GKE. `edge-24.5.1` is
specifically **not** recommended for users of GKE, due to a bug with the default
Linkerd configuration in that release.

Starting in `edge-24.5.1`, the `patchs` metric introduced in `edge-24.3.4` is
renamed to `patches`.

Finally, starting in `edge-24.5.2`, Linkerd will install the GRPCRoute CRD in
the `gateway.networking.k8s.io` API group, in preparation for later GRPCRoute
support. (You can disable this by setting `enableHttpRoutes` to `false` when
installing, which will also prevent Linkerd from installing the HTTPRoute CRD in
the `gateway.networking.k8s.io` API group.)

## The releases

This group of releases has focused on IPv6 support - delivered in
`edge-24.5.2`! - and finalizing fixes for some edge cases in the way Linkerd
handles EndpointSlices and HTTPRoutes. Of course, each edge release has _many_
dependency updates; we won't list them all here, but you can find them in the
release notes for each release.

### [`edge-24.5.5`](https://github.com/linkerd/linkerd2/releases/tag/edge-24.5.5) (May 31, 2024)

This release switches IPv6 off by default for the entire control plane,
including the Linkerd CNI plugin. Set `disableIPv6` to `false` to enable IPv6.

### [`edge-24.5.4`](https://github.com/linkerd/linkerd2/releases/tag/edge-24.5.4) (May 23, 2024)

_We recommend [`edge-24.5.5`] instead of this release. In this release, IPv6
support is off by default for most of the control plane, but it is mistakenly on
by default for the Linkerd CNI plugin._

This release adds support for JSON output to the `linkerd inject`,
`linkerd uninject` and `linkerd profile` commands, and a `--token` flag to
`linkerd diagnostics policy` that allows specifying the context token to use so
that you can see how specific clients will see policies. It also adds support
for setting the group ID for the control plane (thanks, [Nico Feulner]!),
switches IPv6 to off by default for the control plane, adds support for several
proxy settings to the `linkerd-control-plane` chart, allows overriding how many
cores control-plane components can use, correctly supports Gateway API producer
routes, fixes a race conditions around EndpointSlice updates, and fixes
intermittent routing failures with HTTPRoute ([issue 12610]).

[`edge-24.5.5`]: https://github.com/linkerd/linkerd2/releases/tag/edge-24.5.5
[Nico Feulner]: https://github.com/nico151999
[issue 12610]: https://github.com/linkerd/linkerd2/issues/12610

### [`edge-24.5.3`](https://github.com/linkerd/linkerd2/releases/tag/edge-24.5.3) (May 15, 2024)

_If you use the Linkerd CNI plugin on GKE, you will need to disable IPv6 or use
[`edge-24.5.5`] instead._

This release removes an internal limit on the number of concurrent gRPC streams
to the control plane, leaving available memory as the only constraint.

### [`edge-24.5.2`](https://github.com/linkerd/linkerd2/releases/tag/edge-24.5.2) (May 13, 2024)

_If you use the Linkerd CNI plugin on GKE, you will need to disable IPv6 or use
[`edge-24.5.5`] instead._

This release adds support for IPv6. It defaults to enabled: set `disableIPv6` to
`true` when installing to disable it. It also correctly sets the
`backend_not_found` status on HTTPRoutes with no backends. Finally, it adds the
Gateway API GRPCRoute resource (in the `gateway.networking.k8s.io` API group) as
part of continued work on support for GRPCRoutes, although this edge release
doesn't attach any functionality to the CRD.

To prevent Linkerd from installing any CRDs into `gateway.networking.k8s.io`,
set `enableHttpRoutes` to `false` when installing.

### [`edge-24.5.1`](https://github.com/linkerd/linkerd2/releases/tag/edge-24.5.1) (May 2, 2024)

_We recommend [`edge-24.5.5`] instead of this release due to a bug that prevents
Linkerd from functioning on GKE with the default configuration. Additionally,
this release has one breaking change: the `patchs` metric introduced in
[`edge-24.3.4`] is now correctly named `patches`._

This release adds configurable HTTP/2 server keepalives, fixes CLI issues and
opaque-port issues when using native sidecars ([issue #12395]), restores Server
v1beta1 to ease migrations after it was mistakenly removed in [`edge-24.1.2`],
fixes an issue that could cause the endpoints gauge to report incorrect numbers
of endpoints, and continues ongoing work on upcoming IPv6 support.

Additionally, it avoids unnecessary cleanup of headless endpoint mirrors during
garbage collection (thanks, [Marwan Ahmed]!) and cleans up some documentation in
the code (thanks, [knowmost]!).

[issue #12395]: https://github.com/linkerd/linkerd2/issues/12395
[`edge-24.3.4`]: https://github.com/linkerd/linkerd2/releases/tag/edge-24.3.4
[`edge-24.1.2`]: https://github.com/linkerd/linkerd2/releases/tag/edge-24.1.2
[Marwan Ahmed]: https://github.com/marwanad
[knowmost]: https://github.com/knowmost

## Installing the latest edge release

Installing the latest edge release needs just a single command.

```bash
curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install-edge | sh
```

You can also
[install edge releases with Helm](https://linkerd.io/2.15/tasks/install-helm/).

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
