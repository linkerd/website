---
date: 2025-06-04T00:00:00Z
slug: linkerd-edge-release-roundup
title: |-
  Linkerd Edge Release Roundup: June 2025
description: |-
  What you need to know about the most recent Linkerd edge releases,
  June 2025 edition!
keywords: [linkerd, edge, release, roundup]
params:
  author: flynn
  showCover: true
images: [social.jpg] # Open graph image
---

Welcome to the June 2025 Edge Release Roundup post, where we dive into the
most recent edge releases to help keep everyone up to date on the latest and
greatest! This post covers edge releases from April and May, notably including
[edge-25.4.4], which corresponds to Linkerd 2.18. However, since the lion's
share of 2.18's new functionality was covered in the [April 2025 Roundup]
post, we'll be mostly seeing smaller changes in this Roundup.

## How to give feedback

Edge releases are a snapshot of our current development work on `main`; by
definition, they always have the most recent features but they may have
incomplete features, features that end up getting rolled back later, or (like
all software) even bugs. That said, edge releases _are_ intended for
production use, and go through a rigorous set of automated and manual tests
before being released. Once released, we also document whether the release is
recommended for broad use -- and when needed, we go back and update the
recommendations.

We would be delighted to hear how these releases work out for you! You can open
[a GitHub issue](https://github.com/linkerd/linkerd2/issues/) or
[discussion](https://github.com/linkerd/linkerd2/discussions/), join us on
[Slack](https://slack.linkerd.io), or visit the
[Buoyant Linkerd Forum](https://linkerd.buoyant.io) -- all are great ways to
reach us.

## Community contributions

We couldn't do what we do without the Linkerd community, although this
particular batch of releases makes that a little less obvious than usual. Huge
thanks to [Justin Seiser] for his contributions to Linkerd's
OpenTelemetry support!

[Justin Seiser]: https://github.com/jseiser

## Recommendations and breaking changes

Our [April 2025 Roundup] post covered everything through [edge-25.4.1], so
we'll be picking up from there. As noted earlier, edge releases _are_ meant
for real use, as this batch of releases shows: almost all of them can be
recommended for everyone to use, with the exceptions being two edge releases
that changed internal build processes and updated dependencies, but didn't
make any user-facing changes.

There are definitely some changes to be aware of in recent edge releases, too.
We'll start by reiterating a major point from the [April 2025 Roundup] post:
in Linkerd 2.18, including all of the edge releases covered by this post, the
Gateway API CRDs are _mandatory_, and our recommendation is that you install
them yourself rather than having Linkerd install them for you. You can read
more about this in the [Linkerd Gateway API documentation], and of course the
[April 2025 Roundup] post has more details on breaking changes leading up to
Linkerd 2.18.

Additionally, as of [edge-25.4.3] (and therefore included in Linkerd 2.18!),
the default port for tracing is the OpenTelemetry port (4317) rather than the
OpenCensus port (55678).

[April 2025 Roundup]: ../../../04/11/linkerd-edge-release-roundup/
[Linkerd Gateway API documentation]: https://linkerd.io/2/features/gateway-api/
[edge-25.4.1]: https://github.com/linkerd/linkerd2/releases/tag/edge-25.4.1
[edge-25.4.3]: https://github.com/linkerd/linkerd2/releases/tag/edge-25.4.3
[edge-25.4.4]: https://github.com/linkerd/linkerd2/releases/tag/edge-25.4.4
[edge-25.5.1]: https://github.com/linkerd/linkerd2/releases/tag/edge-25.5.1
[edge-25.5.5]: https://github.com/linkerd/linkerd2/releases/tag/edge-25.5.5

## The releases

The first few edge releases in this Roundup, broadly speaking, are all about
getting to Linkerd 2.18, which corresponds to [edge-25.4.4]. After that, we
have a few releases cleaning up some small issues. Of course, each edge
release includes _many_ dependency updates, which we won't list here, but which
you can find in the release notes for each release.

### edge-25.5.5 (May 29, 2025)

This release adds support for the `k8s.pod.ip` OpenTelemetry trace attribute.
Thanks, [Justin Seiser]!

### edge-25.5.4 (May 22, 2025)

This release correctly supports setting pod antiaffinity for the
`linkerd-multicluster` chart.

### edge-25.5.3 (May 15, 2025)

This release contains internal improvements, but no new capabilities over
[edge-25.5.1] -- as such, we recommend that you skip it and go straight to
[edge-25.5.5]!

### edge-25.5.2 (May 08, 2025)

This release contains internal improvements, but no new capabilities over
[edge-25.5.1] -- as such, we recommend that you skip it and go straight to
[edge-25.5.5]!

### edge-25.5.1 (May 02, 2025)

This edge release adds support for `httproute.gateway.networking.k8s.io` in an
AuthorizationPolicy `targetRef`.

### edge-25.4.4 (April 21, 2025)

With this release, Linkerd 2.18 is complete, and the `version-2.18` tag points
to `edge-25.4.4`!

Services with ports using `appProtocol: linkerd.io/opaque` will now only allow
TCPRoutes to be attached to that port, and any unknown `appProtocol` value
will be treated as `linkerd.io/opaque`. Additionally, both GRPCRoutes and
HTTPRoutes may be attached to  `kubernetes.io/h2c` ports, with GRPCRoutes
taking precedence if both are present. Finally, the
`LINKERD2_PROXY_OUTBOUND_METRICS_HOSTNAME_LABELS` is correctly honored for TLS
hostname labels.

### edge-25.4.3 (April 16, 2025)

This release changes the default port for tracing to the OpenTelemetry port
(4317) rather than the OpenCensus port (55678). Additionally, it tweaks the
CLI to make sure that the `v1` Gateway API resources we rely on are present
and gives a more specific command to install Gateway API CRDs if they're not
found.

### edge-25.4.2 (April 09, 2025)

This release makes it easier to see the message telling you that you need to
install the Gateway API CRDs when they are missing, by not showing all the
usage information for `linkerd install` in that case. It also fixes a bug
where metrics for the final request in a gRPC stream could show an `UNKNOWN`
error rather than a success.

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
our rapidly growing community! Linkerd is hosted on
[GitHub](https://github.com/linkerd/), and we have a thriving community on
[Slack](https://slack.linkerd.io/), [Twitter](https://twitter.com/linkerd), and
in [mailing lists](/community/get-involved/). Come and join the fun!

---

_Linkerd generally does new edge releases weekly; watch this space to keep
up-to-date. Feedback on this blog series is welcome! Just ping `@flynn` on the
[Linkerd Slack](https://slack.linkerd.io)._
