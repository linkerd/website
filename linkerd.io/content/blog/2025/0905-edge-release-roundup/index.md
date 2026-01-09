---
date: 2025-09-05T00:00:00Z
slug: linkerd-edge-release-roundup
title: |-
  Linkerd Edge Release Roundup: September 2025
description: |-
  What you need to know about the most recent Linkerd edge releases,
  September 2025 edition!
keywords: [linkerd, edge, release, roundup]
params:
  author: flynn
  showCover: true
images: [social.jpg] # Open graph image
---

Welcome to the September 2025 Edge Release Roundup post, where we dive into the
most recent edge releases to help keep everyone up to date on the latest and
greatest! This post covers edge releases from August 2025.

## How to give feedback

Edge releases are a snapshot of our current development work on `main`; by
definition, they always have the most recent features but they may have
incomplete features, features that end up getting rolled back later, or (like
all software) even bugs. That said, edge releases _are_ intended for production
use, and go through a rigorous set of automated and manual tests before being
released. Once released, we also document whether the release is recommended for
broad use -- and when needed, we go back and update the recommendations.

We would be delighted to hear how these releases work out for you! You can open
[a GitHub issue](https://github.com/linkerd/linkerd2/issues/) or
[discussion](https://github.com/linkerd/linkerd2/discussions/), join us on
[Slack](https://slack.linkerd.io), or visit the
[Buoyant Linkerd Forum](https://linkerd.buoyant.io) -- all are great ways to
reach us.

## Recommendations and breaking changes

All the August edge releases ([edge-25.8.1] through [edge-25.8.5]) are
recommended for everyone, so if you're running an older edge release, now is a
great time to upgrade! This goes double if you're running [edge-25.6.3] or
higher and you're using native sidecars -- there's a fix in [edge-25.8.1] that
you'll definitely want.

As always, we have a couple of breaking changes to note:

- As of [edge-25.8.3], the policy controller is included in the Linkerd
  `controller` image, and we no longer ship a separate `policy-controller`
  image. This should cut down on some image pull traffic, and it means that the
  `policyController.image` Helm value is no longer used.

- As of [edge-25.8.2], we configure routing using the `iptables-nft` command by
  default, rather than with the older `iptables-legacy`. If your nodes don't
  support `iptables-nft`, you can revert to using `iptables-legacy` by setting
  the `iptablesMode` value:

  - If you're using the init container, set `proxyInit.iptablesMode: legacy` in
    the `linkerd2-control-plane` chart.

  - If you're using Linkerd CNI, set `iptablesMode: legacy` in the
    `linkerd2-cni` chart.

- Finally, in [edge-25.8.1], we dropped support for ARMv7 (the 32-bit
  architecture that powered things like the Raspberry Pi 2 and the Beaglebone
  Black). As far as we know, no one is using Linkerd on that architecture -- if
  you are, please let us know!

One other interesting change is that in [edge-25.8.4], the proxy switches to
preferring the post-quantum key exchange algorithm `X25519MLKEM768`. This
shouldn't be a breaking change since we haven't removed support for other
algorithms.

[edge-25.8.5]: https://github.com/linkerd/linkerd2/releases/tag/edge-25.8.5
[edge-25.8.4]: https://github.com/linkerd/linkerd2/releases/tag/edge-25.8.4
[edge-25.8.3]: https://github.com/linkerd/linkerd2/releases/tag/edge-25.8.3
[edge-25.8.2]: https://github.com/linkerd/linkerd2/releases/tag/edge-25.8.2
[edge-25.8.1]: https://github.com/linkerd/linkerd2/releases/tag/edge-25.8.1
[edge-25.6.3]: https://github.com/linkerd/linkerd2/releases/tag/edge-25.6.3

## The releases

As always, each edge release includes _many_ dependency updates which we won't
list here. You can find them in the full release notes for each release.

### edge-25.8.5 (August 27, 2025)

This release adds timeout and gateway error metrics to
`linkerd multicluster check`, to better validate multicluster functionality.

### edge-25.8.4 (August 22, 2025)

This release supports setting `proxy.securityContext` and the `linkerd-proxy`
container, and the `network-validator` container, respectively. It also switches
the proxy to prefer post-quantum key exchange algorithm `X25519MLKEM768`.

### edge-25.8.3 (August 14, 2025)

This release eliminates the separate `policy-controller` image, instead
including the policy controller in the main `controller` image. This means that
the `policyController.image` Helm value is now ignored. It also adds a new
`rustls_info` metric to make visible which cryptographic provider and algorithms
are in use.

### edge-25.8.2 (August 07, 2025)

This release switches the default command for programming the routing table from
`iptables-legacy` to `iptables-nft`.

### edge-25.8.1 (August 01, 2025)

This release fixes an issue ([#14289]) introduced in [edge-25.6.3] where
native-sidecar proxies would land in an error state after the main container
exited. It also correctly sets `app.kubernetes.io/version` label to list
`linkerd/cli` instead of `linkerd/helm` when installing a Linkerd extension
using the CLI, and it removes support for ARMv7, notably including 32-bit
Raspberry Pi platforms.

[#14289]: https://github.com/linkerd/linkerd2/issues/14289

## Installing the latest edge release

Installing the latest edge release needs just a single command.

```bash
curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install-edge | sh
```

You can also [install edge releases with Helm](/2/tasks/install-helm/).

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
