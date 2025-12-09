---
date: 2025-12-08T00:00:00Z
slug: linkerd-edge-release-roundup
title: |-
  Linkerd Edge Release Roundup: December 2025
description: |-
  What you need to know about the most recent Linkerd edge releases,
  December 2025 edition!
keywords: [linkerd, edge, release, roundup]
params:
  author: flynn
  showCover: true
images: [social.jpg] # Open graph image
---

Welcome to the excessively-large December 2025 Edge Release Roundup
posts, where we dive into the most recent edge releases to help keep
everyone up to date on the latest and greatest! This post covers edge
releases from September through November 2025 (the runup to KubeCon was
hectic around here).

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

## Recommendations and breaking changes

**Spoiler alert**: if you're looking at edge releases from the latter
chunk of 2025, we recommend you skip straight to [edge-25.11.3] to take
full advantage of fixes along the way. However, any RECOMMENDED release
is fair game.

As usual, we have some breaking changes to call out:

* As of [edge-25.11.3], the `proxy-init` image has been merged with the
  `proxy` image to simplify image management. Since we no longer ship a
  separate `proxy-init` image, if you were explicitly referencing that
  image you'll need to update your references to use the `proxy` image
  instead.

* As of [edge-25.10.3], the `ip_port_subscribers` metric has been removed
  and replaced with the lower-cardinality `workload_subscribers` metric.
  This change is intended to reduce the cardinality of metrics and
  improve performance.

* As of [edge-25.10.2], support for the (long-deprecated) OpenCensus
  trace protocol has been removed. The OpenTelemetry protocol is now the
  only supported tracing protocol.

* As of [edge-25.10.1], the `linkerd-jaeger` extension has been removed:
  instead, Linkerd supports directly configuring OpenTelemetry tracing by
  setting `controller.tracing.enable` and
  `controller.tracing.collector.endpoint` when installing Linkerd.

* As of [edge-25.9.4], the `linkerd-crds` Helm chart will no longer
  install the Gateway API CRDs by default. **This change may require
  attention when upgrading**; see below for details.

Also as of [edge-25.10.2], native sidecar support moves to beta, adding
the `config.beta.linkerd.io/proxy-enable-native-sidecar` annotation and
deprecating the alpha annotation (although that will continue to
function).

### Gateway API and Upgrading

As of [edge-25.9.4], the `linkerd-crds` Helm chart will no longer install
the Gateway API CRDs by default. To force the chart to install the
Gateway API CRDs, set `installGatewayAPI=true` when installing the chart.

If you're upgrading from a previous release of Linkerd, and you
originally used the `linkerd-crds` chart to install the Gateway API CRDs,
you _may_ need to take extra action:

* If you're already running Linkerd 2.18/edge-25.4.4 or higher, you're
  good to go. The Gateway API CRDs that you originally installed with Helm
  will stay on the cluster when you do the upgrade.

* If you're running something older, you'll need to set `--reuse-values`
  when upgrading, to make sure that the existing Gateway API CRDs stay
  installed.

[edge-25.11.3]: https://github.com/linkerd/linkerd2/releases/tag/edge-25.11.3
[edge-25.10.7]: https://github.com/linkerd/linkerd2/releases/tag/edge-25.10.7
[edge-25.10.3]: https://github.com/linkerd/linkerd2/releases/tag/edge-25.10.3
[edge-25.10.2]: https://github.com/linkerd/linkerd2/releases/tag/edge-25.10.2
[edge-25.10.1]: https://github.com/linkerd/linkerd2/releases/tag/edge-25.10.1
[edge-25.9.4]: https://github.com/linkerd/linkerd2/releases/tag/edge-25.9.4
[edge-25.8.5]: https://github.com/linkerd/linkerd2/releases/tag/edge-25.8.5

## The releases

As always, each edge release includes _many_ dependency updates which we won't
list here. You can find them in the full release notes for each release.

### edge-25.11.3 (November 27, 2025)

This release merges the `proxy-init` image into the `proxy` image,
simplifying image management and reducing overall image size -- make sure
to update any explicit references to the `proxy-init` image. It also
correctly honors the `timeouts.request` value of HTTPRoutes in the
`gateway.networking.k8s.io` API group, to match the behavior of
`policy.linkerd.io` HTTPRoutes.

### edge-25.11.2 (November 20, 2025)

_This release is **not recommended**; use [edge-25.11.3] instead._

This release fixes broken documentation URLs in CLI commands (thanks,
[beza]!) and corrects a typo in the EgressNetwork and ExternalWorkload
CRD definitions (thanks, [YY]!). Unfortunately, it also fails to
correctly handle SPIRE when using mesh expansion; we recommend using
[edge-25.11.3] instead.

[beza]: https://github.com/bezarsnba
[YY]: https://github.com/yy-ofms

### edge-25.11.1 (November 06, 2025)

This release correctly includes pod metadata in OpenTelemetry traces,
fixes the `workload_subscribers` metric to correctly track the total
number of subscribers across all IP and port combinations (rather than
only the most recent combination), and prevents a task leak when using
federated services.

### edge-25.10.7 (October 29, 2025)

This release includes more guardrails for tracing configuration in the
Helm chart, notably including fixing a possible crash if the tracing
collector endpoint is not set.

### edge-25.10.6 (October 23, 2025)

_This release is **not recommended**; use [edge-25.10.7] instead, or just go
straight to [edge-25.11.3]._

This release includes more guardrails for tracing configuration in the
Helm chart, but we recommend skipping it in favor of [edge-25.10.7] or
[edge-25.11.3] to avoid a possible crash if the tracing collector
endpoint is not set.

### edge-25.10.5 (October 20, 2025)

_This release is **not recommended**; use [edge-25.10.7] instead, or just go
straight to [edge-25.11.3]._

This release includes more guardrails for tracing configuration in the
Helm chart, but we recommend skipping it in favor of [edge-25.10.7] or
[edge-25.11.3] to avoid a possible crash if the tracing collector
endpoint is not set.

### edge-25.10.4 (October 16, 2025)

_This release is **not recommended**; use [edge-25.10.7] instead, or just go
straight to [edge-25.11.3]._

This release prevents a possible crash when tracing isn't configured at
all, but we recommend skipping it in favor of [edge-25.10.7] or
[edge-25.11.3] to avoid a possible crash if the tracing is configured but
the tracing collector endpoint is not set.

It also adds semantic convention labels `user-agent.original`,
`http.request.header.content-length`, `http.request.header.content-type`,
and `http.request.header.l5d-orig-proto` to OpenTelemetry spans.

### edge-25.10.3 (October 13, 2025)

_This release is **not recommended**; use [edge-25.10.7] instead, or just go
straight to [edge-25.11.3]._

This release removes the `linkerd.io/proxy-root-parent` and
`linkerd.io/proxy-root-parent-kind` labels added to injected pods in
[edge-25.10.2], and also fixes a potential deadlock that could result in
leaked tasks and unneeded memory consumption. However, we recommend
skipping it in favor of [edge-25.10.7] or [edge-25.11.3] to avoid a
possible crash if the tracing collector endpoint is not set.

This release includes one breaking change: it removes the
`ip_port_subscribers` metric and replaces it with the lower-cardinality
`workload_subscribers` metric, and it also allows configuring the
destination controller's stream queue capacity. The default remains 100
for the moment; lower values may be better for improving responsiveness
to readiness and liveness issues.

### edge-25.10.2 (October 09, 2025)

_This release is **not recommended**; use [edge-25.10.7] instead, or just go
straight to [edge-25.11.3]._

This release drops support for the (long-deprecated) OpenCensus trace
protocol. Additionally, it adds the `linkerd.io/proxy-root-parent` and
`linkerd.io/proxy-root-parent-kind` labels to injected pods, but this
change was reverted in edge-25.10.3 due to unforeseen issues. We
recommend skipping this release and going straight to [edge-25.10.7] or
[edge-25.11.3].

Additionally, this release adds support for setting OpenTelemetry tracing
values via `resource.opentelemetry.io/<label>` annotations on pods,
making it simpler to customize tracing for specific workloads. Finally,
it also moves native sidecar support to beta, adding the
`config.beta.linkerd.io/proxy-enable-native-sidecar` annotation and
deprecating the alpha annotation (although that will continue to
function).

### edge-25.10.1 (October 02, 2025)

This release drops support for the Linkerd Jaeger extension: instead, it
supports directly configuring OpenTelemetry tracing by setting
`controller.tracing.enable` and `controller.tracing.collector.endpoint`
when installing Linkerd. It also guarantees that OpenTelemetry spans are
flushed regularly, and not just when streams become idle. Finally, it
adds the `inbound_http_request_frame_size_bytes` and
`inbound_grpc_request_frame_size_bytes` histograms to metrics, to allow
better visibility into request body sizes.

### edge-25.9.4 (September 25, 2025)

Starting in this release, the `linkerd-crds` Helm chart will no longer
install the Gateway API CRDs by default. To force the chart to install
the Gateway API CRDs, set `installGatewayAPI=true` when installing the
chart; see the [Gateway API and Upgrading](#gateway-api-and-upgrading)
section above for more details.

This release also fixes an issue where native sidecar proxies could have
stale endpoint data, resulting in problems routing traffic. Additionally,
it correctly supports `ReplacePrefixMatch` in HTTPRoute `RequestRedirect`
filters.

### edge-25.9.3 (September 18, 2025)

This release adds several new metrics: `inbound_requests` gives a count
of the total number of inbound requests received by a proxy,
`inbound_http_response_frame_size_bytes` gives a histogram of inbound
HTTP frame sizes, and `inbound_grpc_response_frame_size_bytes` gives a
histogram of inbound gRPC frame sizes.

### edge-25.9.2 (September 12, 2025)

This release correctly supports the `k8s.pod.ip` attribute in
OpenTelemetry traces, rather than always reporting the literal value
`_pod_ip`.

### edge-25.9.1 (September 04, 2025)

This release bumps dependencies but has no functional changes from [edge-25.8.5].

## Installing the latest edge release

Installing the latest edge release needs just a single command.

```bash
curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install-edge | sh
```

You can also
[install edge releases with Helm](/2/tasks/install-helm/).

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
