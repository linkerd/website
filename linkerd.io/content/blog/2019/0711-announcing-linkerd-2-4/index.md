---
date: 2019-07-11T00:00:00Z
slug: announcing-linkerd-2.4
title: |-
  Announcing Linkerd 2.4: Traffic Splitting and SMI
keywords: [linkerd]
params:
  author: william
  showCover: true
---

Today we're happy to announce the release of
[Linkerd 2.4](https://github.com/linkerd/linkerd2/releases/tag/stable-2.4.0).
This release adds **traffic splitting** and **Service Mesh Interface (SMI)
support**, graduates high-availability support out of experimental status, and
includes a tremendous list of other improvements, performance enhancements, and
bug fixes.

(And did I mention Linkerd recently
[passed its third party security audit](https://twitter.com/wm/status/1144746496807428096)
with flying colors?)

Linkerd's new traffic splitting feature allows users to dynamically control the
percentage of traffic destined for a service. This powerful feature can be used
to implement rollout strategies like canary releases and blue-green deploys by
incrementally shifting request traffic between Kubernetes services.

Support for the [Service Mesh Interface](https://smi-spec.io/) makes it easier
for ecosystem tools to work with Linkerd. This is already paying dividends:
we're happy to report that
[Flagger now supports Linkerd](https://docs.flagger.app/usage/linkerd-progressive-delivery)!
[Flagger](https://github.com/weaveworks/flagger) is a progressive delivery
operator that combines metrics and traffic splitting, and a great example of the
sort of higher-order operations that the service mesh unlocks. (The Linkerd team
is [the largest contributor to SMI](/2019/05/24/linkerd-and-smi/), so we're
excited to see this coming together so nicely.)

Finally, Linkerd 2.4 graduates the high availability (HA) control plane mode out
of experimental status into a fully production-ready feature, and introduces a
host of other improvements, performance enhancements, and fixes, including:

- A new `linkerd edges` command for auditing TLS and identity of connections
  between resources
- A two-phase installation process that splits cluster-level and namespace-level
  privilege requirements, for security-conscious Kubernetes adopters who don't
  let just anyone change things on the cluster.
- A _debug sidecar_ for easier inspection of pod traffic
- A fresh security audit from [Cure53](https://cure53.de/), passed with flying
  colors
- And much, much more--read the full
  [Linkerd 2.4 Release Notes](https://github.com/linkerd/linkerd2/blob/main/CHANGES.md#stable-240)
  for details!

Linkerd 2.4 is our third major release of 2019. Earlier this year,
[Linkerd 2.3](/2019/04/16/announcing-linkerd-2.3/) enabled mutual TLS by
default, making authenticated, confidential communication between meshed
services the norm for all Linkerd users. In February,
[Linkerd 2.2](/2019/02/12/announcing-linkerd-2-2/) introduced automatic retries
and timeouts, adding powerful reliability mechanisms that allow Linkerd users to
automatically recover from many of the partial failures endemic to distributed
systems.

We'll be discussing the fun features in 2.4 and the plans for 2.5 in our
[next Linkerd Online Community Meeting](https://www.meetup.com/Linkerd-Online-Community-Meetup/events/262624182/)
later this month. Be sure to join us there.

Ready to try Linkerd? Those of you who have been tracking the 2.x branch via our
[weekly edge releases](/2-edge/) will already have seen these features in
action. Either way, you can download the stable 2.4 release by running:

```bash
    curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install | sh
```

Linkerd is a community project and is hosted by the
[Cloud Native Computing Foundation](https://cncf.io/). If you have feature
requests, questions, or comments, we'd love to have you join our rapidly-growing
community! Linkerd is hosted on [GitHub](https://github.com/linkerd/), and we
have a thriving community on [Slack](https://slack.linkerd.io/),
[Twitter](https://twitter.com/linkerd), and the
[mailing lists](/community/get-involved/). Come and join the fun!

(_Image credit:
[Robert Couse-Baker](https://www.flickr.com/photos/29233640@N07/)_)
