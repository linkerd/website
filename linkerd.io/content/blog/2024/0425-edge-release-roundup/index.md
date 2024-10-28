---
title: |-
  Linkerd Edge Release Roundup: April 2024
description: |-
  What you need to know about the most recent Linkerd edge releases, April 2024
  edition!
date: 2024-04-25T00:00:00Z
slug: linkerd-edge-release-roundup
keywords: [linkerd, edge, release, roundup]
params:
  author: flynn
  showCover: true
  thumbnail: /2023/06/21/linkerd-edge-roundup/thumbnail.png
  cover: /2023/06/21/linkerd-edge-roundup/cover.png
images: [/2023/06/21/linkerd-edge-roundup/cover.png] # Open graph image
---

Welcome to the April 2024 Edge Release Roundup post, where we dive into the most
recent edge releases to help keep everyone up to date on the latest and
greatest! This month, we're covering the releases from `edge-24.4.5` back to
`edge-24.3.3` -- there's a lot here so we'll get right into it.

## How to give feedback

Remember, edge releases are a snapshot of our current development work on
`main`; by definition, they always have the most recent features but they may
have incomplete features, features that end up getting rolled back later, or
(gasp!) even bugs. If you're running edge releases, it's _very_ important that
you send us feedback on how things are going for you!

We would be delighted to hear how these releases work out for you! You can open
[a GitHub issue](https://github.com/linkerd/linkerd2/issues/) or
[discussion](https://github.com/linkerd/linkerd2/discussions/), join us on
[Slack](https://slack.linkerd.io), or visit the
[Buoyant Linkerd Forum](https://linkerd.buoyant.io) -- all are great ways to
reach us.

## Community contributions

We couldn't do what we do without the Linkerd community, and this batch of
releases is definitely no exception. Huge thanks to [Adarsh Jaiswal], [Akshay
Dongaonkar], [Cemal Y. Dalar], [Firas Medini], [Grigoriy Mikhalkin], [hanghuge],
[Heiko Voigt], [Ilia Lazebnik], [Hirotaka Tagawa], and [occupyhabit] for their
contributions! You'll find more information about all of these contributions in
the release-by-release details below.

[hanghuge]: https://github.com/hanghuge
[Grigoriy Mikhalkin]: https://github.com/GrigoriyMikhalkin
[occupyhabit]: https://github.com/occupyhabit
[Firas Medini]: https://github.com/mdnfiras
[Adarsh jaiswal]: https://github.com/Adarsh-jaiss
[Hirotaka Tagawa]: https://github.com/wafuwafu13
[Cemal Y. Dalar]: https://github.com/cdalar
[Ilia Lazebnik]: https://github.com/DrFaust92
[Akshay Dongaonkar]: https://github.com/doubletooth
[Heiko Voigt]: https://github.com/hvoigt

## Breaking changes and recommendations

There are no breaking changes in these releases. However, we have two specific
recommendations:

- We recommend `edge-24.4.4` instead of `edge-24.4.3` due to a metrics-naming
  regression in `edge-24.4.3`.
- We recommend `edge-24.3.4` instead of `edge-24.3.3` since `edge-24.3.4`
  contains an important fix for Gateway API users.

## The releases

Recent edge releases have been mostly focused on upcoming IPv6 support and some
significant bugfixes. Of course, each edge release has _many_ dependency
updates; we won't list them all here, but you can find them in the release notes
for each release.

_(Last Roundup we did these in chronological order, but we're switching this
time to reverse chronological order, starting with the most recent.)_

### [`edge-24.4.5`](https://github.com/linkerd/linkerd2/releases/tag/edge-24.4.5) (April 25, 2024)

This edge release fixes support for native sidecars in the Linkerd CNI plugin,
continues work on upcoming IPv6 support, and allows setting
`revisionHistoryLimit` when installing with Helm to specify how many ReplicaSets
to keep around for rollback purposes (thanks, [Ilia Lazebnik]!)

It also allows setting certain HTTP/2 server parameters using environment
variables in the proxy container (see [proxy PR 2924] if you think you need
this!).

[proxy PR 2924]: https://github.com/linkerd/linkerd2-proxy/pull/2924

### [`edge-24.4.4`](https://github.com/linkerd/linkerd2/releases/tag/edge-24.4.4) (April 18, 2024)

This edge release fixes a metrics naming regression introduced in the previous
release, restoring the `outbound_http_...` metrics to their correct names
instead of duplicating `http`.

### [`edge-24.4.3`](https://github.com/linkerd/linkerd2/releases/tag/edge-24.4.3) (April 18, 2024)

_We recommend `edge-24.4.4` instead of this release due to a metrics-naming
regression in `edge-24.4.3`._

This edge release fixes the second of two issues where where `policy.linkerd.io`
HTTPRoutes could be endlessly patched even when they weren't changing ([issue
12310]).

[issue 12310]: https://github.com/linkerd/linkerd2/issues/12310

### [`edge-24.4.2`](https://github.com/linkerd/linkerd2/releases/tag/edge-24.4.2) (April 11, 2024)

This edge release fixes an issue where the service mirror controller would panic
if it encountered an error listing mirror services while fixing its list of
endpoints, and continues work on upcoming IPv6 support. It also allows correctly
setting policy controller resources via Helm, instead of just defaulting them to
the same as the destination controller (thanks, [Grigoriy Mikhalkin]!), allows
relabeling metrics to customize how high-cardinality metrics get handled
(thanks, [Heiko Voigt]!), and does a little cleanup of documentation in the code
(thanks, [hanghuge]!). Finally, it adds a new `linkerd diagnostics profile`
command which gives low-level visibility into which ServiceProfile is attached
to a given address.

### [`edge-24.4.1`](https://github.com/linkerd/linkerd2/releases/tag/edge-24.4.1) (April 4, 2024)

This edge release continues work on upcoming IPv6 support.

### [`edge-24.3.5`](https://github.com/linkerd/linkerd2/releases/tag/edge-24.3.5) (March 28, 2024)

This edge release adds metrics to the queue of HTTPRoute status updates and
makes the ExternalWorkload resource's status as a subresource, as it always
should have been. It also corrects the scope of the proxy-injector,
tap-injector, and jaeger-injector mutating webhook rules to Namespaced (thanks
[Firas Medini]!), and cleans up some documentation in the code (thanks
[occupyhabit]!).

### [`edge-24.3.4`](https://github.com/linkerd/linkerd2/releases/tag/edge-24.3.4) (March 22, 2024)

This edge release fixes the first of two issues where `policy.linkerd.io`
HTTPRoutes could be endlessly patched even when they weren't changing ([issue
12104]), and another where the destination controller could generate large
numbers of unnecessary endpoint updates when a Server changed. It also adds
default values to generated docs for the `proxy-*-connect-timeout` annotations
(thanks [Akshay Dongaonkar]!), fixes excessive logging in the injector webhook
([issue 12186], thanks [Adarsh Jaiswal]!), and cleans up an unneeded error
message from the destination controller (thanks [Hirotaka Tagawa]!).

Finally, this edge release fixes an issue that could mistakenly turn off local
traffic policy when an endpoint is removed ([issue 12311]), adds a timeout to
HTTPRoute status patches, continues work on upcoming IPv6 support, and stops
unnecessarily checking about injecting the `kube-system` namespace when running
in HA mode.

[issue 12186]: https://github.com/linkerd/linkerd2/issues/12186
[issue 12104]: https://github.com/linkerd/linkerd2/issues/12104
[issue 12311]: https://github.com/linkerd/linkerd2/issues/12311

### [`edge-24.3.3`](https://github.com/linkerd/linkerd2/releases/tag/edge-24.3.3) (March 14, 2024)

_We recommend `edge-24.3.4` instead of this release since `edge-24.3.4` contains
an important fix._

This edge release allows configuring the pod disruption budget via Helm ([issue
11321], thanks [Cemal Y. Dalar]!).

[issue 11321]: https://github.com/linkerd/linkerd2/issues/11321

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
