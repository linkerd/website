---
title: |-
  Linkerd Edge Release Roundup: September 2024
description: |-
  What you need to know about the most recent Linkerd edge releases, September
  2024 edition!
date: 2024-09-06T00:00:00Z
slug: linkerd-edge-release-roundup
keywords: [linkerd, edge, release, roundup]
params:
  author: flynn
  showCover: true
  cover: /2023/06/21/linkerd-edge-roundup/cover.png
images: [social.png] # Open graph image
---

Welcome to the September 2024 Edge Release Roundup post, where we dive into the
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
releases is definitely no exception. Huge thanks to [@mozemke] for their
contributions! You'll find more information about all of these contributions in
the release-by-release details below.

[@mozemke]: https://github.com/mozemke

## Recommendations and breaking changes

All these releases are recommended for general use. Happily, there are no
breaking changes here.

## The releases

August's edge releases look small, but [`edge-24.8.1`] and [`edge-24.8.2`]
provided the finishing touches for [Linkerd 2.16], which shipped on August 13!
Of course, each edge release has bugfixes and _many_ dependency updates; we
won't list them all here, but you can find them in the release notes for each
release.

One thing to be aware of here: as of [`edge-24.8.1`], the GRPCRoute CRD is
_optional_; if you don't install it before installing Linkerd, Linkerd will run
without GRPCRoute support, and you'll need to restart the Linkerd control plane
if you add the GRPCRoute CRD after installing Linkerd.

[`edge-24.8.1`]: https://github.com/linkerd/linkerd2/releases/tag/edge-24.8.1
[`edge-24.8.2`]: https://github.com/linkerd/linkerd2/releases/tag/edge-24.8.2
[Linkerd 2.16]: https://linkerd.io/2024/08/13/announcing-linkerd-2.16/index.html

### [`edge-24.8.3`](https://github.com/linkerd/linkerd2/releases/tag/edge-24.8.3) (August 29, 2024)

This release starts the Linkerd 2.17 development cycle, with two fixes for
Linkerd Viz: it correctly supports setting the group ID using the `linkerd-viz`
Helm chart (thanks, @mozemke!) and it cleans up font downloading to avoid WAF
errors.

### [`edge-24.8.2`](https://github.com/linkerd/linkerd2/releases/tag/edge-24.8.2) (August 5, 2024)

This final touch for Linkerd 2.16 makes certain that Linkerd won't attempt to
bind to IPv6 addresses at all unless IPv6 is enabled.

### [`edge-24.8.1`](https://github.com/linkerd/linkerd2/releases/tag/edge-24.8.1) (August 2, 2024)

This release makes GRPCRoute optional: if you don't have the GRPCRoute CRD
installed when Linkerd starts, Linkerd will run without any GRPCRoute
functionality rather than failing to start. (If you add the GRPCRoute CRD after
Linkerd is running, you'll need to restart the Linkerd control plane to enable
GRPCRoute support.)

[`edge-24.8.1`] also improves the `status` text when an HTTPRoute is incorrectly
configured with `parentRef` pointing to a headless service, to make this
situation easier to debug, and makes certain that trace-level logs honor
`proxy.logHTTPHeaders`.

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
