---
author: 'flynn'
date: 2024-03-12T00:00:00Z
title: |-
  Linkerd Edge Release Roundup: March 2024
url:
  /2024/03/12/linkerd-edge-release-roundup/
thumbnail: '/uploads/2023/06/roundup-clocks-square.png'
featuredImage: '/uploads/2023/06/roundup-clocks-rect.png'
tags: [Linkerd, linkerd, edge, release, roundup]
featured: false
---

{{< fig
  alt="March 2024 Linkerd Edge Release Roundup"
  src="/uploads/2023/06/roundup-clocks-rect.png" >}}

With the changes to Linkerd's release model, edge releases have clearly become
more important! In light of that, we'll be doing these Edge Release Roundup
posts every month, to help keep everyone up to date on the latest and
greatest. Going forward, we'll cover everything since the previous roundup,
but for this first post of the new series, we'll take a longer look back, and
tackle all the edge releases from February to the present.

## Major Process Changes

There have been two significant changes in the edge release process that we
want to highlight.

1. **Automated Edge Releases**

   As of `edge-24.2.5`, we've automated the process of creating edge releases.
   While this is mostly an internal process change, it also means that you may
   see edge releases where the release notes are just a bunch of commit logs
   (especially from `dependabot`). We'll still make additional callouts for
   more significant changes, though.

2. **Helm Chart Release Numbers**

   As of `edge-24.3.1`, we're changing the versioning scheme for our Helm
   charts to match the date-oriented scheme for the edge releases themselves.
   The only difference is that the Helm chart uses a four-digit year number --
   for example, the Helm charts for `edge-24.3.1` has version `2024.3.1`. This
   should simplify things for everyone.

## Community Contributions

We couldn't do what we do without the Linkerd community, and this batch of
releases is definitely no exception. Huge thanks to [Aurel Canciu], [Adam
Toy], [Rui Chen], [Michael Bell], and [Jan Kantert] for their contributions!
You'll find more information about all of these contributions in the
release-by-release details below.

[Aurel Canciu]:https://github.com/relu
[Adam Toy]:https://github.com/atoy3731
[Rui Chen]:https://github.com/chenrui333
[Michael Bell]:https://github.com/mikebell90
[Jan Kantert]:https://github.com/jan-kantert

## Breaking Changes

**There is a breaking change in `edge-24.2.4`.**

Up through `edge-24.2.3`, the `ExternalWorkload` CRD (version `v1alpha1`)
specified the identity that an external workload should use as the `meshTls`
stanza. In `edge-24.2.4`, we updated `ExternalWorkload` to `v1beta1` and
changed the spelling of this stanza to `meshTLS` (note the capitalization) to
better align with the rest of our CRDs. Unfortunately, in the process we also
broke the `v1alpha1` `ExternalWorkload` CRD: anyone using `ExternalWorkload`
in `edge-24.2.3` would find that `edge-24.2.4` didn't honor those
`ExternalWorkload`s.

We don't think that this will have affected anyone in practice, but this
section will list _all_ the breaking changes we know of, whether we think they
could affect anyone or not.

## The Releases

From the feature perspective, recent edge releases have been focused on
automating the edge release process, and on improving mesh expansion. We've
also fixed quite a few things and, of course, each edge release has many
dependency updates.

### [`edge-24.2.1`](https://github.com/linkerd/linkerd2/releases/tag/edge-24.2.1) ([changelog](https://github.com/linkerd/linkerd2/releases/tag/edge-24.2.1))

This edge release improves the performance and stability of the `destination`
controller and the ExternalWorkloads EndpointSlice controller.

- The `destination` controller can ride through outdated Server CRDs in
  Pod-to-Pod multicluster, and it will only
  process Server updates for workloads actually affected by the Server.
- EndpointSlices generated for ExternalWorkloads have better names, and leader
  election is improved for the controller generating them.
- ExternalWorkloads can have at most one IPv4 address and one IPv6 address.

### [`edge-24.2.2`](https://github.com/linkerd/linkerd2/releases/tag/edge-24.2.2) ([changelog](https://github.com/linkerd/linkerd2/releases/tag/edge-24.2.2))

This edge release introduces Helm configuration for liveness and readiness
probe timings (thanks to [Jan Kantert]!), and addresses some issues in the
`destination` controller.

- We fixed a race condition that could panic the `destination` controller
  ([issue 12010](https://github.com/linkerd/linkerd2/issues/12010)).
- Also, when a Server that marks a port as `opaque` no longer selects any
  resource, the resource's opaqueness will correctly revert to the default
  ([issue 11995](https://github.com/linkerd/linkerd2/issues/11995)).

### [`edge-24.2.3`](https://github.com/linkerd/linkerd2/releases/tag/edge-24.2.3) ([changelog](https://github.com/linkerd/linkerd2/releases/tag/edge-24.2.3))

This edge release supports configuring the MutatingWebhookConfig timeout
(thanks, [Michael Bell]!) and fixes a few issues:

- We added a counter of items dropped from the `destination` controller work
  queue, to help identify controller overloading.
- We fixed a spurious `linkerd check` error for container images with digests.
- We fixed a bug where Linkerd wouldn't correctly update policy after deleting
  policy resources.

### [`edge-24.2.4`](https://github.com/linkerd/linkerd2/releases/tag/edge-24.2.4) ([changelog](https://github.com/linkerd/linkerd2/releases/tag/edge-24.2.4))

This edge release introduces the `v1beta1` ExternalWorkload CRD, with the more
correctly named `meshTLS` stanza. **This is a breaking change**;
ExternalWorkload `v1alpha1` is no longer supported. It also updated the proxy
to address some logging and metrics inconsistencies.

### [`edge-24.2.5`](https://github.com/linkerd/linkerd2/releases/tag/edge-24.2.5) ([changelog](https://github.com/linkerd/linkerd2/releases/tag/edge-24.2.5))

This release includes support for Go 1.22 (thanks [Rui Chen]!) and updates the
proxy again.

### [`edge-24.3.1`](https://github.com/linkerd/linkerd2/releases/tag/edge-24.3.1) ([changelog](https://github.com/linkerd/linkerd2/releases/tag/edge-24.3.1))

As noted earlier, this is the release that changes the Helm versioning scheme.
It also adds support for setting `loadBalancerClass` when required (thanks,
[Adam Toy]!).

### [`edge-24.3.2`](https://github.com/linkerd/linkerd2/releases/tag/edge-24.3.2) ([changelog](https://github.com/linkerd/linkerd2/releases/tag/edge-24.3.2))

Last but not least, this release fixes the Helm chart to correctly supporting
setting `repairController` resources ([issue
12100](https://github.com/linkerd/linkerd2/issues/12100) -- thanks, [Aurel
Canciu]!). It additionally moves invalid token logs to `INFO` level (rather
than `DEBUG`).

## Installing the Latest Edge Release

```bash
curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install-edge | sh
```

## How to give feedback

We would be delighted to hear how these releases work out for you! You can
open [a GitHub issue](https://github.com/linkerd/linkerd2/issues/) or
[discussion](https://github.com/linkerd/linkerd2/discussions/), join us on
[Slack](https://slack.linkerd.io), or visit the [Buoyant Linkerd
Forum](https://linkerd.buoyant.io) -- all are great ways to reach us.

Looking forward to hearing from you – happy meshing!!

----

_Linkerd generally does new edge releases weekly; watch this space to keep
up-to-date. Feedback on this blog series is welcome! Just ping `@flynn` on the
[Linkerd Slack](https://slack.linkerd.io)._
