---
date: 2024-07-01T00:00:00Z
slug: linkerd-edge-release-roundup
title: |-
  Linkerd Edge Release Roundup: July 2024
description: |-
  What you need to know about the most recent Linkerd edge releases, July 2024
  edition!
keywords: [linkerd, edge, release, roundup]
params:
  author: flynn
  showCover: true
  thumbnail: /2023/06/21/linkerd-edge-roundup/thumbnail.jpg
  cover: /2023/06/21/linkerd-edge-roundup/cover.jpg
images: [/2023/06/21/linkerd-edge-roundup/cover.jpg] # Open graph image
---

Welcome to the July 2024 Edge Release Roundup post, where we dive into the most
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
releases is definitely no exception. Huge thanks to [Adrian Callejas] and [John
Howard] for their contributions! You'll find more information about all of these
contributions in the release-by-release details below.

[Adrian Callejas]: https://github.com/acallejaszu
[John Howard]: https://github.com/howardjohn

## Recommendations and breaking changes

All these releases are recommended for general use, but there are two breaking
changes:

- First, as of `edge-24.6.2`, we change the proxy's `/shutdown` endpoint to
  disabled by default. If you want to reenable it, you'll need to set
  `proxy.enableShutdownEndpoint` to `true` on installation or upgrade.

- Second, as of `edge-24.6.4`, it's no longer possible - or necessary! - to
  explicitly set the resource requests for `proxy-init`. There's more
  information on this in the section for `edge-24.6.4`.

## The releases

We've mostly been fixing bugs in these edge releases. Of course, each edge
release has _many_ dependency updates; we won't list them all here, but you can
find them in the release notes for each release.

### [`edge-24.6.4`](https://github.com/linkerd/linkerd2/releases/tag/edge-24.6.4) (June 27, 2024)

This release changes the proxy-init container to always request the same amount
of memory and CPU as the proxy itself, and removes the ability to explicitly set
proxy-init's requests because there's now no need to do so. (This doesn't
increase the resources required for the pod as a whole, because the proxy-init
container completes before the proxy starts, letting the proxy reuse resources
requested by the proxy-init container. For full details, check out
[issue #11320][comment]).

[comment]:
  https://github.com/linkerd/linkerd2/issues/11320#issuecomment-2186383081

It also continues work on upcoming GRPCRoute support. Finally, if
`proxy.logHTTPHeaders` is somehow empty, it correctly defaults to "off".

### [`edge-24.6.3`](https://github.com/linkerd/linkerd2/releases/tag/edge-24.6.3) (June 20, 2024)

`edge-24.6.3` adds the `linkerd.io/control-plane-ns` label to the
`ext-namespace-metadata-linkerd-config` Role, for parity with the other
resources created when installing Linkerd.

### [`edge-24.6.2`](https://github.com/linkerd/linkerd2/releases/tag/edge-24.6.2) (June 14, 2024)

Starting in this release, the proxy's `/shutdown` endpoint is disabled by
default. It can be reenabled by setting `proxy.enableShutdownEndpoint` to `true`
when installing or upgrading. Beyond that, `edge-24.6.2` fixes several bugs:
EndpointSlices with no `hostname` field are supported (thanks, [Adrian
Callejas]!), DNS resolution errors are correctly logged (and the resolver's log
level can be configured), the proxy's administration endpoints function
correctly on systems using IPv4-mapped IPv6, and the init container and CNI
plugin will not attempt to start on systems that configure IPv6 but don't
support `ip6tables`. Finally, it supports controlling whether or not HTTP
headers are logged in debug output (with the default being "not"), JSON output
for the link, unlink, allow, and allow-scrapes CLI commands, and fixes a typo in
the output of `linkerd diagnostics` (thanks, [John Howard]!)

### [`edge-24.6.1`](https://github.com/linkerd/linkerd2/releases/tag/edge-24.6.1) (June 10, 2024)

This release adds support for JSON output to `linkerd install` and related
commands.

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
