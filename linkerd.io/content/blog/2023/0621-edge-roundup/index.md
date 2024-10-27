---
title: |-
  Linkerd Edge Release Roundup: 21 June 2023
date: 2023-06-21T00:00:00Z
slug: linkerd-edge-roundup
keywords: [linkerd, gitops, flux, flagger]
params:
  author: matei
  showCover: true
---

Linkerd’s edge releases are a big part of our development process that we’re
going to start talking more about – and so far in June, we’ve done a couple of
edge releases that we think everyone should definitely know about!

On June 20th, we released edge-23.6.2, which introduces timeout capabilities for
HTTPRoutes following the standard proposed in Gateway API [GEP-1742]. It also
includes a host of small bugfixes and two fixes from community members:

- `linkerd check` won't skip validation checks when Linkerd is installed with HA
  mode using Helm. Thanks [Takumi Sue]!

- Allow specifying the Docker builder to use when building multi-arch Docker
  artifacts. Thanks [Mark Robinson]!

And on June 13th, we released edge-23.6.1. This edge release switched the
Linkerd CNI plugin so that it always runs in chained mode to reduce startup
races, as well as bringing in two more community fixes:

- Topology-aware service routing can now be correctly turned off while still
  under load. Thanks again, [Mark Robinson]!

- Last but not least, support specifying a `logFormat` in the multi-cluster Link
  Helm Chart. Thanks, [Arnaud Beun]!

As always, you can install the latest edge release by running:

```bash
curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install-edge | sh
```

[Takumi Sue]: https://github.com/mikutas
[Mark Robinson]: https://github.com/MarkSRobinson
[Arnaud Beun]: https://github.com/bunnybilou

## GEP-1742 timeout support (edge-23.6.2)

**G**ateway API **E**nhancement **P**roposals - GEPs - are part of the formal
process for modifying the Gateway API, and [GEP-1742] introduces the ability to
specify two kinds of timeouts in an HTTPRoute. Timeouts are an important feature
for reliability, so Linkerd has been following - and participating in - this GEP
with great interest.

Since it’s still in the “Provisional” state at present, it’s possible that we
may need to make changes here before the next stable Linkerd release, but it’s
far enough along (see Gateway API [PR#1997]) that we think it’s worth
implementing to let people try out. Let us know how it works for you!

[GEP-1742]: https://gateway-api.sigs.k8s.io/geps/gep-1742/
[PR#1997]: https://github.com/kubernetes-sigs/gateway-api/pull/1997

## CNI changes (edge-23.6.1)

A big part of what Linkerd has to handle at startup is setting up the network to
allow Linkerd to route within the mesh, which sometimes means using the Linkerd
CNI plugin. CNI plugins are tricky, especially when it comes to ordering (as you
learned if you watched the [Service Mesh Academy episode about startup]!), and
we’ve run across a few situations where race conditions with the CNI plugin
could result in problems.

To combat these race conditions, we’ve switched our CNI plugin to only use
chained mode. Instead of letting the Linkerd CNI plugin create a CNI
configuration if it doesn’t find one, the plugin will now always wait for some
other part of the CNI chain to create the configuration first. This makes it
much less likely that some other CNI plugin will accidentally overwrite
Linkerd’s configuration, regardless of the CNI plugin provider that’s used.

## How to give feedback

We would be delighted to hear how these releases work out for you! The full
changelogs are at <https://github.com/linkerd/linkerd2/releases/tag/edge-23.6.1>
and <https://github.com/linkerd/linkerd2/releases/tag/edge-23.6.2>, and we’d
love to hear your feedback on [Slack](https://slack.linkerd.io) or at the new
[Buoyant Linkerd Forum](https://linkerd.buoyant.io). Looking forward to hearing
from you – happy meshing!!

[Service Mesh Academy episode about startup]:
  https://buoyant.io/service-mesh-academy/what-really-happens-at-startup

---

_Linkerd generally does new edge releases weekly; watch this space to keep
up-to-date. Feedback on this blog series is welcome! Just ping `@flynn` on the
[Linkerd Slack](https://slack.linkerd.io)._
