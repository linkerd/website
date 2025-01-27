---
date: 2024-08-05T00:00:00Z
slug: linkerd-edge-release-roundup
title: |-
  Linkerd Edge Release Roundup: August 2024
description: |-
  What you need to know about the most recent Linkerd edge releases, August 2024
  edition!
keywords: [linkerd, edge, release, roundup]
params:
  author: flynn
  showCover: true
  cover: /2023/06/21/linkerd-edge-roundup/cover.png
images: [social.png] # Open graph image
---

Welcome to the August 2024 Edge Release Roundup post, where we dive into the
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
releases is definitely no exception. Huge thanks to [@djryanj] for his
contributions! You'll find more information about all of these contributions in
the release-by-release details below.

[@djryanj]: https://github.com/djryanj

## Recommendations and breaking changes

All these releases are recommended for general use. Happily, there are no
breaking changes here.

## The releases

The big story for this month is definitely `edge-24.7.5`: this massive release
brings together a lot of threads of work to provide us the bones of the upcoming
Linkerd 2.16 release. Of course, each edge release has bugfixes and _many_
dependency updates; we won't list them all here, but you can find them in the
release notes for each release.

### [`edge-24.7.5`](https://github.com/linkerd/linkerd2/releases/tag/edge-24.7.5) (July 26, 2024)

This release supports Server-scoped default policy, policy audit mode,
GRPCRoute, and new retry and timeout configuration (including for Gateway API
resources). There's a lot to unpack here:

- **Server-scoped default policy**: you can use the new `accessPolicy` field of
  a Server to override the default inbound policy for that Server. The default
  is `deny`, for backward compatibility.

- **Policy audit mode**: setting the default inbound policy or a Server's
  `accessPolicy` to `audit` allows traffic to flow, but logs anything that would
  be denied.

- **GRPCRoute**: this release includes support for the Gateway API GRPCRoute.
  Remember to set `enableHttpRoutes` to `false` when installing if you don't
  want Linkerd to manage the Gateway API CRDs for you!

- **New retry and timeout configuration**: you can now configure retries and
  timeouts with annotations on Service, HTTPRoute, or GRPCRoute resources, with
  HTTPRoute and GRPCRoute taking precedence over Service if there are overlaps.
  Note that these are _counted_ retries, rather than the _budgeted_ retries
  provided when you configure retries in a Server: you will configure a maximum
  number of retries rather than a percentage of retries.

### [`edge-24.7.4`](https://github.com/linkerd/linkerd2/releases/tag/edge-24.7.4) (July 25, 2024)

This release correctly supports IPv6 in the Linkerd CNI `network-validator` and
`repair-controller` containers.

### [`edge-24.7.3`](https://github.com/linkerd/linkerd2/releases/tag/edge-24.7.3) (July 19, 2024)

This release updates the documentation on what `networkValidator.connectAddr` in
the Helm chart means (thanks, [@djryanj]!).

### [`edge-24.7.2`](https://github.com/linkerd/linkerd2/releases/tag/edge-24.7.2) (July 15, 2024)

This release bumps dependencies but has no functional changes from
`edge-24.7.1`.

### [`edge-24.7.1`](https://github.com/linkerd/linkerd2/releases/tag/edge-24.7.1) (July 4, 2024)

This release removes the empty `shortnames` fields from the ExternalWorkload
CRD.

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
