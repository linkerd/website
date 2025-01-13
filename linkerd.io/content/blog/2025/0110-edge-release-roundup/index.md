---
date: 2025-01-10T00:00:00Z
slug: linkerd-edge-release-roundup
title: |-
  Linkerd Edge Release Roundup: January 2025
description: |-
  What you need to know about the most recent Linkerd edge releases,
  January 2025 edition!
keywords: [linkerd, edge, release, roundup]
params:
  author: flynn
  showCover: true
images: [social.png] # Open graph image
---

Welcome to the January 2025 Edge Release Roundup post, where we dive into the
most recent edge releases to help keep everyone up to date on the latest and
greatest! In this month's Roundup, we're closing the books on edge releases
from 2024, culminating in the release of Linkerd 2.17.0 -- as such, we have
several releases with several new features to cover here!

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
releases is definitely no exception. Huge thanks to [Brandon Ros], [Derek
Brown], and [Micah See] for their contributions! You'll find more information
about all of these contributions in the release-by-release details below.

[Brandon Ros]: https://github.com/brandonros
[Derek Brown]: https://github.com/DerekTBrown
[Micah See]: https://github.com/MicahSee

## Recommendations and breaking changes

If you're looking at any of the eight(!!) edge releases in our list this
month, candidly you should really just go straight for edge-24.11.8 -- that's
the latest and greatest, corresponding to Linkerd 2.17.0, so there's no reason
you wouldn't choose that one. However, most of these releases are recommended
for general use, and there are no breaking changes in any of them, so if you
want to try an older one, go for it!

The two exceptions here are:

* We don't recommend edge-24.11.6, since [edge-24.11.7] came out literally the
  same day with three nice-to-have fixes.

* We also don't recommend edge-24.11.2, since [edge-24.11.3] includes an
  important fix for the `linkerd diagnostics endpoints` command.

[edge-24.11.7]: https://github.com/linkerd/linkerd2/releases/tag/edge-24.11.7
[edge-24.11.3]: https://github.com/linkerd/linkerd2/releases/tag/edge-24.11.3

## The releases

November's releases are all about landing the features that make up Linkerd
2.17.0. Of course, each edge release includes _many_ dependency updates which
we won't list here, but you can find them in the release notes for each
release.

### edge-24.11.8 (November 26, 2024)

_edge-24.11.8 corresponds to Linkerd 2.17.0._

This release closes out Linkerd 2.17 by updating dependencies to change
Linkerd's logic around Kubernetes leases, in order to make sure that patches
don't get stuck indefinitely.

### edge-24.11.7 (November 25, 2024)

This release removes the initial delay for the policy controller, allowing for
faster control-plane startups. It also quietens the policy controller's
reconciliation logs and adds logging to make it clear which policy-controller
pod is responsible for updating statuses.

### edge-24.11.6 (November 25, 2024)

_edge-24.11.6 is **NOT RECOMMENDED**; it has been superseded by [edge-24.11.7]._

[edge-24.11.7] was released the same day as edge-24.11.6, superseding it.

### edge-24.11.5 (November 22, 2024)

In this release, the proxy emits new `request_frame_size` and
`response_frame_size` metrics with information about TCP frame distributions,
correctly accounts for closed connections in route metrics, and fixes a (rare)
panic for resources in which `managedFields` has no timestamp. Additionally,
`linkerd check` checks to be sure that your Link resources match your CLI
version, keywords in `docker build` now use correct cases (thanks, [Derek
Brown]!). Finally, for this release we started testing Linkerd on Kubernetes
1.31.

### edge-24.11.4 (November 19, 2024)

This release fixes a bug ([issue 13327]) where Linkerd could constantly
re-update the `status` clause of HTTPRoute if another Gateway API controller
was present in the system (thanks [Derek Brown]!), ensures that all of the
proxy-injector's logs are valid JSON when JSON logging is enabled (thanks,
[Micah See]!), and cleans up HTTPRoute validation to make sure that if a
`backendRef` is a Service, it must have a valid port.

[issue 13327]: https://github.com/linkerd/linkerd2/issues/13327

### edge-24.11.3 (November 14, 2024)

This release brings local rate limiting to Linkerd! Using the new
HTTPLocalRateLimitPolicy resource, you can attach rate limits to Servers to
protect workloads from being overwhelmed by excessive traffic. Additionally,
it improves metrics for TCPRoute and TLSRoute egress control, correctly
handles the case where a Route type changes parents (fixing [issue #13280]),
allows `linkerd diagnostics endpoints` to correctly handle workloads with
multiple endpoints, and removes unneeded references to `linkerd-base` from the
`linkerd-control-plane` chart README (thanks, [Brandon Ros]!).

### edge-24.11.2 (November 8, 2024)

_edge-24.11.2 is **NOT RECOMMENDED**, since `linkerd diagnostics endpoints`
may not correctly show all endpoints for federated Services. We recommend
using [edge-24.11.3] instead._

This release brings federated Services to Linkerd multicluster setups! Every
federated Service appears exactly the same from every cluster (rather than
having names like `svc-cluster`) and Linkerd seamlessly handles everything to
gather the relevant endpoints from all clusters, without requiring application
changes or HTTPRoute configuration.

### edge-24.11.1 (November 7, 2024)

This release brings egress monitoring and control to Linkerd! Using the new
EgressNetwork CRD as a `parentRef` for an HTTPRoute, GRPCRoute, TCPRoute, or
TLSRoute, you can see which workloads are making egress calls and set policy
on what's allowed and what isn't.

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
