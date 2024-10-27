---
title: |-
  Linkerd Edge Release Roundup: August 2023
date: 2023-08-07T00:00:00Z
slug: linkerd-edge-release-roundup
keywords: [linkerd, edge, release, roundup]
params:
  author: alejandro
  showCover: true
  thumbnail: /2023/06/21/linkerd-edge-roundup/thumbnail.png
  cover: /2023/06/21/linkerd-edge-roundup/cover.png
images: [/2023/06/21/linkerd-edge-roundup/cover.png] # Open graph image
---

Linkerd’s edge releases are a big part of our development process, and there
have been a lot of them - five! - since our last edge-release roundup. The plan
is do these roundups more frequently to keep things manageable, but for this
one, we'll hit some highlights and then do a release-by-release list at the end.

## Community Contributions

We couldn't do what we do without the Linkerd community, and this batch of
releases is definitely no exception. Huge thanks to [@hiteshwani29], [Abhijeet
Gaurav], [Grégoire Bellon-Gervais], [Harsh Soni], [Jean-Charles Legras], and
[Miguel Elias dos Santos] for their contributions across a wide range of areas,
from the Linkerd CLI to host networking! You'll find more information about all
of these contributions in the release-by-release details below.

[@hiteshwani29]: https://github.com/hiteshwani29
[Abhijeet Gaurav]: https://github.com/abhijeetgauravm
[Grégoire Bellon-Gervais]: https://github.com/albundy83
[Harsh Soni]: https://github.com/harsh020
[Jean-Charles Legras]: https://github.com/jclegras
[Miguel Elias dos Santos]: https://github.com/migueleliasweb

## Gateway API

From the feature perspective, our main focus over the last several edge releases
has been improving our Gateway API support, bringing us closer to feature parity
between [HTTPRoutes] and [ServiceProfiles]:

- We added support for the Gateway API's `gateway.networking.k8s.io` APIGroup to
  Linkerd in edge-23.7.1 on July 7th. This is a major step toward conformance
  with the Gateway API's [Mesh profile]. (We're not turning off support for
  `policy.linkerd.io` though, that's still quite a ways away.)

- We added support for HTTPRoutes defined in the namespace from which a route is
  called in edge-23.7.3 on July 28th. The Gateway API calls these [_consumer
  routes_][consumer-routes] since the use case is, usually, doing things like
  overriding the timeout for a workload you're calling. You can learn more about
  this in the [Gateway API Mesh routing documentation][gamma-routing].

- We also made HTTPRoute `parentRefs` port numbers optional in edge-23.7.3, per
  the [HTTPRoute standard].

- Finally, we started adding support for [HTTPRoute filters]:
  `RequestHeaderModifier` and `RequestRedirect` are supported in edge-23.7.2,
  and `ResponseHeaderModifier` is supported in edge-23.7.3 (so edge-23.7.2 added
  header modifications for _requests_, and edge-23.7.3 added header
  modifications for _responses_).

[HTTPRoutes]: https://gateway-api.sigs.k8s.io/api-types/httproute/
[HTTPRoute standard]:
  https://gateway-api.sigs.k8s.io/references/spec/#gateway.networking.k8s.io/v1alpha2.HTTPRoute
[ServiceProfiles]: https://linkerd.io/2.13/features/service-profiles/
[consumer-routes]:
  https://gateway-api.sigs.k8s.io/concepts/glossary/#consumer-route
[gamma-routing]:
  https://gateway-api.sigs.k8s.io/concepts/gamma/#how-the-gateway-api-works-for-service-mesh
[Mesh profile]: https://gateway-api.sigs.k8s.io/geps/gep-1686/
[HTTPRoute filters]:
  https://gateway-api.sigs.k8s.io/references/spec/#gateway.networking.k8s.io/v1beta1.HTTPRouteFilter

## Fixes

Of the many fixes in these five releases, two in particular stand out:

1. In edge-23.7.3, we fixed a race condition where the Linkerd destination
   controller could panic in an environment with high churn of Endpoints or
   Servers. The most common effect here is seeing restarts of the destination
   controller Pods, but it could also result in traffic being sent to the wrong
   destination endpoints.

   This is covered in Linkerd issue [#11163].

2. In edge-23.8.1, we raised the default capacities of the HTTP request queues
   (both inbound and outbound) back to 10,000 after lowering them for Linkerd
   2.13. The effect here is that in situations where a single destination
   workload needed to accept a lot of concurrent traffic, the Linkerd proxies
   would decide that they had too much load, and start shedding it by dropping
   connections. This happened much more agressively in Linkerd 2.13 than in
   Linkerd 2.12; it's fixed in edge-23.8.1.

   This is covered in Linkerd issue [#11055] and PR [#11198].

[#11163]: https://github.com/linkerd/linkerd2/issues/11163
[#11055]: https://github.com/linkerd/linkerd2/issues/11055
[#11198]: https://github.com/linkerd/linkerd2/pull/11198

## Installing the Latest Edge Release

```bash
curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install-edge | sh
```

## How to give feedback

We would be delighted to hear how these releases work out for you! The full
changelogs are at
<https://github.com/linkerd/linkerd2/releases/tag/edge-23.6.3>,
<https://github.com/linkerd/linkerd2/releases/tag/edge-23.7.1>,
<https://github.com/linkerd/linkerd2/releases/tag/edge-23.7.2>,
<https://github.com/linkerd/linkerd2/releases/tag/edge-23.7.3>, and
<https://github.com/linkerd/linkerd2/releases/tag/edge-23.8.1>. We’d love to
hear your feedback on [Slack](https://slack.linkerd.io) or at the new
[Buoyant Linkerd Forum](https://linkerd.buoyant.io). Looking forward to hearing
from you – happy meshing!!

## Release Details

- edge-23.6.3, on June 30th, was all about a couple of community contributions:
  - [@hiteshwani29] added JSONpath output to `linkerd viz tap`.
  - [Jean-Charles Legras] fixed a proxy startup failure that could happen with
    the `config.linkerd.io/admin-port` annotation.
- edge-23.7.1, on July 7th, started our Gateway API theme and also made a couple
  of fixes:
  - We added support for the Gateway API's `gateway.networking.k8s.io` APIGroup
    to Linkerd (a major step toward conformance with the Gateway API's [Mesh
    profile]).
  - We fixed a problem where the ingress-mode proxy wouldn't always correctly
    use ServiceProfiles for destinations with no HTTPRoutes.
  - We added distinguishable version information to the proxy's logs and
    metrics.
- edge-23.7.2, on July 13th, continued the Gateway API theme and pulled in a
  community fix:
  - We added support for HTTPRoute's `RequestHeaderModifier` and
    `RequestRedirect` [filters].
  - [Miguel Elias dos Santos] fixed a `linkerd-cni` chart problem that could
    block the CNI pods from coming up when the injector was broken.
- edge-23.7.3, on July 28th, was our largest edge release: it had a lot of
  Gateway API work and several fixes.
  - We made HTTPRoute `parentRefs` port numbers optional, per the [HTTPRoute
    standard].
  - We added support for Gateway API [_consumer routes_][consumer-routes].
  - We added support for HTTPRoute's `ResponseHeaderModifier`
    [filter][HTTPRoute filters].
  - [Grégoire Bellon-Gervais] fixed a Grafana error caused by an incorrect
    datasource.
  - [Harsh Soni] fixed the linkerd extension CLI commands so that they prefer
    the `--register` flag over the `LINKERD_DOCKER_REGISTRY` environment
    variable, for consistency.
  - We fixed a race condition that could cause the destination controller to
    panic.
  - We added high-availability mode for the multicluster service mirror, and
    further improved control-plane logging.
  - We added support for disabling the network validator security context if
    you're in an environment that defines its own security context.
- Last but not least: edge-23.8.1, on August 3rd, brought in a couple of very
  important bugfixes:
  - [Abhijeet Gaurav] made it possible to use the `linkerd-cni` DaemonSet
    without needing host networking support.
  - We raised the default capacities of the HTTP request queues back to 10,000.

---

_Linkerd generally does new edge releases weekly; watch this space to keep
up-to-date. Feedback on this blog series is welcome! Just ping `@flynn` on the
[Linkerd Slack](https://slack.linkerd.io)._
