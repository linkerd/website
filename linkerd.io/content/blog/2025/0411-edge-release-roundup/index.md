---
date: 2025-04-11T00:00:00Z
slug: linkerd-edge-release-roundup
title: |-
  Linkerd Edge Release Roundup: April 2025
description: |-
  What you need to know about the most recent Linkerd edge releases,
  April 2025 edition!
keywords: [linkerd, edge, release, roundup]
params:
  author: flynn
  showCover: true
images: [social.jpg] # Open graph image
---

Welcome to the April 2025 Edge Release Roundup post, where we dive into the
most recent edge releases to help keep everyone up to date on the latest and
greatest! As you may have noticed, this Roundup is overdue -- there was a
_lot_ going on for the start of 2025, leading up to KubeCon, so we have
quite a lot to cover before getting back to a proper monthly cadence.

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

We couldn't do what we do without the Linkerd community, and this batch of
releases is definitely no exception. Huge thanks to [Joakim Roubert], [Maxime
 Brunet], [Nathan Mehl], [Scott Brenner], [Shane Starcher], [Stephen Muth],
[Takumi Sue], [Tuomo], [Vishal Tewatia], and [omer2500] for their
contributions! You'll find more information about all of these contributions
in the release-by-release details below.

[Joakim Roubert]: https://github.com/joakimr-axis
[Maxime Brunet]: https://github.com/maxbrunet
[Nathan Mehl]: https://github.com/n-oden
[Scott Brenner]: https://github.com/ScottBrenner
[Shane Starcher]: https://github.com/sstarcher
[Stephen Muth]: https://github.com/smuth4
[Takumi Sue]: https://github.com/mikutas
[Tuomo]: https://github.com/tjorri
[Vishal Tewatia]: https://github.com/vishu42
[omer2500]: https://github.com/omer2500

## Recommendations and breaking changes

Since this is the April 2025 Roundup, we would normally stop with the last
release in March 2025 -- but for this Roundup in particular we're going to
break with tradition and go ahead and include [edge-25.4.1] in the list,
because it's most likely the one you want to be running. Unusually, many of
the releases in this Roundup are _not_ recommended for everyone: only
[edge-25.4.1], [edge-25.2.1], and [edge-25.1.2] are unreservedly recommended
for all users. So if you're looking at features in any of these ten(!!!) edge
releases, you should almost certainly just go straight to [edge-25.4.1].

We also have several breaking changes to note, as we continue down the road to
Linkerd 2.18:

* First, Linkerd's approach to the Gateway API CRDs is changing. Previously,
  we would install these CRDs for you unless you said otherwise. This isn't
  what Gateway API recommends these days, since the Gateway API CRDs often
  have to be shared between multiple projects in a cluster.

  Therefore, starting with [edge-25.3.1], Linkerd will not install Gateway API
  CRDs for you unless you specifically ask for them and they're not already on
  your cluster.

  * **If you are upgrading** from an earlier version of Linkerd,
  you shouldn't need to take any action -- Linkerd can tell that you have the
  CRDs installed and do the right thing for you.

  * **For new installations**, though, you'll need to install the Gateway API
  CRDs before starting, or you'll need to set `installGatewayAPI` to true when
  installing. **In production**, we recommend installing the Gateway API CRDs
  yourself rather than having Linkerd manage it for you. Check out the
  [Gateway API and Linkerd] documentation for more information.

  Also, when Linkerd does install the Gateway API CRDs for you, it will
  install Gateway API v1.1.1 experimental (starting with [edge-25.2.3]), and
  it will annotate them the CRDs with `helm.sh/resource-policy: keep` so that
  Helm won't delete them during upgrades.

* Continuing the Gateway API theme, as of [edge-25.3.4] the Gateway API CRDs
  are mandatory. Older versions could run with restricted functionality if the
  Gateway API CRDs weren't present, but that is no longer the case.

* Linkerd multicluster is changing to be more GitOps-friendly. This starts
  with [edge-25.3.3], when the `linkerd multicluster link` command is
  deprecated in favor of the new `linkerd multicluster link-gen` command.
  There are actually a lot of changes under the hood here, so we encourage
  checking out the [multicluster documentation] (and keeping an eye out for an
  upcoming [Service Mesh Academy]!) if you use multicluster.

* Starting in [edge-25.3.2], all communications between two meshed proxies are
  multiplexed on port 4143 by default, rather than using the original
  destination port of the traffic. (This is configurable, though we don't
  expect it to need to be disabled in most cases.)

* Starting in [edge-25.2.4], it's possible to use the `appProtocol` field of a
  Service to declaratively specify what protocol will be used for requests,
  meaning that Linkerd can skip protocol detection for that port.

* Starting in [edge-25.2.2], the default tracing protocol is OpenTelemetry
  instead of OpenCensus.

Check out the releases below for more on the status of each release!

[multicluster documentation]: /2-edge/features/multicluster/
[Gateway API and Linkerd]: /2-edge/features/gateway-api/
[Service Mesh Academy]: https://buoyant.io/service-mesh-academy
[edge-25.1.1]: https://github.com/linkerd/linkerd2/releases/tag/edge-25.1.1
[edge-25.1.2]: https://github.com/linkerd/linkerd2/releases/tag/edge-25.1.2
[edge-25.2.1]: https://github.com/linkerd/linkerd2/releases/tag/edge-25.2.1
[edge-25.2.2]: https://github.com/linkerd/linkerd2/releases/tag/edge-25.2.2
[edge-25.2.3]: https://github.com/linkerd/linkerd2/releases/tag/edge-25.2.3
[edge-25.2.4]: https://github.com/linkerd/linkerd2/releases/tag/edge-25.2.4
[edge-25.3.1]: https://github.com/linkerd/linkerd2/releases/tag/edge-25.3.1
[edge-25.3.2]: https://github.com/linkerd/linkerd2/releases/tag/edge-25.3.2
[edge-25.3.3]: https://github.com/linkerd/linkerd2/releases/tag/edge-25.3.3
[edge-25.3.4]: https://github.com/linkerd/linkerd2/releases/tag/edge-25.3.4
[edge-25.4.1]: https://github.com/linkerd/linkerd2/releases/tag/edge-25.4.1

## The releases

Broadly speaking, these releases are all about the features that make up
Linkerd 2.18. Of course, each edge release includes _many_ dependency updates
which we won't list here, but you can find them in the release notes for each
release.

### edge-25.4.1 (April 02, 2025)

_This release is recommended for all users, and is probably the one you should
run if you're reading this post._

edge-25.4.1 _requires_ the Gateway API CRDs, so you must either install them
before installing Linkerd, or you must explicitly set `installGatewayAPI=true`
when installing Linkerd. It also correctly configures Prometheus to scrape the
new multicluster mirror controllers, adds the `--only-controller` flag to the
now-deprecated `linkerd mc unlink` command to help migrating to the new
multicluster world, and you can set
`LINKERD2_PROXY_INBOUND_AUTHORITY_LABELS=unsafe` in the proxy's environment to
restore the `authority` labels for inbound metrics. It also introduces a new
`control_dns_resolutions_total` metric and correctly propagates span context
into proxy debug log messages to make it easier to understand what caused
things.

### edge-25.3.4 (March 27, 2025)

_This release has a CLI bug that prevents it from installing the Gateway API
CRDs even if requested. As such, we recommend [edge-25.4.1] instead, though
Helm is functional in this release._

This release restores correct IPv6 support and multicluster permissions, as
well as introducing the new `linkerd multicluster link-gen` command (which
deprecates `link` and `unlink`) and a CLI check to warn of any older mirror
controllers that haven't yet been replaced. It supports setting
`proxy.metrics.hostnameLabels` true when installing Linkerd to include
hostname labels in outbound metrics, supports excluding labels and annotations
from federated and mirrored services, fixes a bug that could result in stale
Service resources when mirroring services, fixes support for ExternalWorkloads
that don't explicitly declare the Linkerd proxy port (4143) in their
manifests, and mitigates a thundering herd effect where proxies could
unnecessarily load the DNS server. Finally, `linkerd viz tap` no longer relies
on the obsolete `authority` pseudo-resource (thanks, [Stephen Muth]!).

### edge-25.3.3 (March 20, 2025)

_This release is **not recommended** since it unintentionally switched the
multicluster mirror controller to use ClusterRole permissions rather than Role
permissions, and doesn't correctly support IPv6. We recommend using
[edge-25.4.1] instead._

This edge release integrates the service-mirroring controllers into the
Linkerd multicluster extension, allowing better GitOps management of the new
Link `v1alpha3` CRs and credential Secrets. Additionally, when using federated
Services, the metadata of the federated Service will be kept in sync with the
Service with the oldest Link, the `proxy.cores` Helm chart value has been
replaced with a more flexible `proxy.runtime.workers` structure, it's now
possible to set an environment variable to reenable outbound hostname metrics,
and - last but not least! - we will correctly honor custom debug container
annotations (thanks, [Vishal Tewatia]!)

### edge-25.3.2 (March 14, 2025)

_This release does not correctly support IPv6. We recommend [edge-25.4.1]
instead, though IPv4 sites can use this release._

This release includes a change to the way protocol detection happens: if the
client closes the connection without writing any data, the proxy doing
protocol detection will treat it as a read failure, which a client making
unusual use of half-open connections _might_ see as a behavioral change. If
you have such a client, you may need to mark the connection as opaque.

Additionally, edge-25.3.2 is where, by default, traffic between meshed proxies
flows on port 4143 rather than using the original destination port. If you
need to, you can set `outbound-transport-mode` to `transparent` to restore the
previous behavior.

This release also fixes a bug where installing with Helm could install Gateway
API CRDs even when `enableHttpRoutes`, `enableTcpRoutes`, or `enableTlsRoutes`
were set to false, and improves metrics around protocol declarations and
protocol detection (especially when using the `transport-header` mode).
Additionally, inbound server metrics now get a `srv_port` label to identify
the specific port used for inbound policy.

### edge-25.3.1 (March 06, 2025)

_This release is **not recommended** due to a bug installing the Gateway API
CRDs and a bug with IPv6 support; use [edge-25.4.1] instead._

This release is where Linkerd's management of the Gateway API CRDs changes for
the first time: the new `installGatewayAPI` setting takes the place of the
previous `enableHttpRoutes`, `enableTcpRoutes`, and `enableTlsRoutes`
settings; `linkerd install --crds` will no longer install Gateway API CRDs if
any are already present; and any Gateway API CRDs installed by Linkerd will be
annotated such that Helm will not uninstall them during an upgrade.

Additionally, this version adds support for Linkerd _protocol declaration_,
bypassing protocol detection if you set `appProtocol` in a Service `port`
definition (for example, setting `appProtocol` to `http` or
`kubernetes.io/h2c` will skip protocol detection and do HTTP). It also
supports setting `outbound-transport-mode` to `transport-header` when
installing Linkerd to multiplex all traffic between meshed proxies on port
4143 rather than using the original destination port. Finally, the
documentation for `proxy-wait-before-exit-seconds` has been updated to match
the website (thanks, [Takumi Sue]!).

### edge-25.2.3 (February 27, 2025)

_This release does not correctly support IPv6. We recommend [edge-25.4.1]
instead, though IPv4 sites can use this release._

Starting in this release, if you allow Linkerd to manage Gateway API CRDs for
you, this release will upgrade your Gateway API CRDs to version 1.1.1
experimental. Also, you can now use `appProtocol: linkerd.io/opaque` in a
Service `port` definition to mark a port as opaque.

### edge-25.2.2 (February 20, 2025)

_This release does not correctly support IPv6. We recommend [edge-25.4.1]
instead, though IPv4 sites can use this release._

Starting in this release, the default tracing protocol is OpenTelemetry
instead of OpenCensus, and the policy controller now retries errors in lease
handling. We've also enabled additional runtime metrics around Kubernetes
watches, and finally, in the unlikely event of overlapping Server resources,
we order the resources by creation time and name (as we do for Routes).

### edge-25.2.1 (February 12, 2025)

_This release is recommended for all users._

Starting with this release, the `hostname` label for inbound HTTP and TLS metrics will always have an empty value, and the `authority` label has been removed.

This release markedly improves Linkerd's OpenTelemetry compatibility by
supporting the `OTEL_RESOURCE_ATTRIBUTES` environment variable, correctly
propagating OpenTelemetry trace attributes from the client side of a request,
and better supporting OpenTelemetry trace attributes (including the pod UID
and container name). It adds a new `issuer_cert_ttl_seconds` gauge metric to
expose the time remaining until the identity issuer certificate expires
(thanks, [Nathan Mehl]!), removes the `authority` label on inbound HTTP
metrics, and disables the `hostname` label for inbound HTTP and TLS metrics
(it will be present with an empty value). It also fixes a bug that could
result in HTTPRoutes with no `port` specified ending up with stale policy
information, and allows `linkerd install` to work without the Gateway API CRDs
installed at all. Last but certainly not least, labels on mirrored `Service`s
are propagated to their mirrored versions (thanks, [Maxime Brunet]!) and CI
got an improved `codeql` workflow (thanks, [Scott Brenner]!).

### edge-25.1.2 (January 23, 2025)

_This release is recommended for all users._

This release changes the format of the Link resource's `probeSpec.period`,
which means that Links created by [edge-25.1.1] will not work with
edge-25.1.2. Additionally, the ability to query by `authority` in `linkerd viz
stat` has been removed.

This release updates OpenTelemetry trace labels to follow current [HTTP
semantic conventions], reduces load on the Kubernetes API server when a
multicluster setup mirrors a lot of Services, and allows the CNI
`updateStrategy` to be configured (thanks, [Shane Starcher]!), fixing [issue
13031]. It also requires the Link resource's `probeSpec.period` to be a
[GEP-2257] duration string, which means that Links created by [edge-25.1.1]
will not work as of this release: if you try to edit or redeploy those Links,
you'll get a validation error if you don't fix the `probeSpec.period`.

[HTTP semantic conventions]: https://opentelemetry.io/docs/specs/semconv/http/http-spans/
[issue 13031]: https://github.com/linkerd/linkerd2/issues/13031
[GEP-2257]: https://gateway-api.sigs.k8s.io/geps/gep-2257/

### edge-25.1.1 (January 16, 2025)

_This release is **not recommended** due to a bug creating Link resources; use
[edge-25.1.2] or [edge-25.4.1] instead._

This release requires that the Kubernetes API server be able to use TLS v1.3;
since this has been supported since Kubernetes v1.19, it shouldn't be an issue
for anyone. It also validates that `proxy.runAsRoot` be set if
`proxyInit.closeWaitTimeoutSecs` is set -- this was a functional requirement
anyway, but we now validate it at install time.

Additionally, this first release of 2025 adds proper iptables support for RHEL
nodes, allows Linkerd to talk to running Pods which haven't passed readiness
checks yet (thanks, [Tuomo]!), and allows specifying both `podAnnotations` per
deployment (thanks, [Takumi Sue]!) and labels for the Viz dashboard (thanks,
[omer2500]!). It also correctly handles proxy log levels with quotes, cleans
up CLI output of port forwarding errors, adds the pod UID and proxy container
name to the environment, fixes a bug with installing extensions with Helm in
IPv6 clusters, and removes some unneeded CNI configuration values. Finally,
thanks to [Joakim Roubert] for cleaning up some development shell scripting!

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
our rapidly-growing community! Linkerd is hosted on
[GitHub](https://github.com/linkerd/), and we have a thriving community on
[Slack](https://slack.linkerd.io/), [Twitter](https://twitter.com/linkerd), and
in [mailing lists](/community/get-involved/). Come and join the fun!

---

_Linkerd generally does new edge releases weekly; watch this space to keep
up-to-date. Feedback on this blog series is welcome! Just ping `@flynn` on the
[Linkerd Slack](https://slack.linkerd.io)._
