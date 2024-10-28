---
title: |-
  Announcing Linkerd 2.16! Metrics, retries, and timeouts for HTTP and gRPC
  routes; IPv6 support; policy audit mode; and lots more
date: 2024-08-13T00:00:00Z
slug: announcing-linkerd-2.16
keywords: [linkerd, "2.16", features]
params:
  author: william
  showCover: true
---

Today we're happy to announce [Linkerd 2.16](/releases/#linkerd-216), a major
step forward for Linkerd that adds a whole host of new features, including
support for IPv6; an "audit mode" for Linkerd's zero trust security policies; a
new implementation of retries, timeouts, and per-route metrics for HTTPRoute and
GPRCRoute resources; and much more.

## New route metrics, retries, and timeouts

The 2.16 release continues our goal of ensuring Linkerd is the truly
_future-proof service mesh._ We expect the
[Gateway API](https://gateway-api.sigs.k8s.io/) to emerge as the standard for
traffic configuration in the Kubernetes space, and when that happens, Linkerd
users will be ready. (Of course, we're also actively involved in the Gateway API
to ensure the evolving design continues to make sense for Linkerd users!)

To this end, Linkerd 2.16 now publishes metrics for Gateway API HTTPRoute and
GRPCRoute resources, so you can capture granular per-route success rates,
latencies, request volumes, and other metrics without changing any application
code.

Linkerd 2.16 also adds retry and timeout configuration to these same Gateway API
resources, bringing the feature sets for Gateway API and ServiceProfiles to
parity (as
[promised in our February Linkerd 2.15 announcement](https://linkerd.io/blog/announcing-linkerd-2.15/)).
This configuration is backed by a new implementation that improves upon
Linkerd's earlier retry and timeout logic in two key ways:

1. Requests that time out can now be retried; and
2. Retries and timeouts can now be combined with circuit breaking.

Enabling Linkerd's new retry and timeout support is as simple as adding
annotations to Gateway API resources. For example:

```yaml
kind: HTTPRoute
apiVersion: gateway.networking.k8s.io/v1beta1
metadata:
  name: myapp-default-route
  namespace: myns
  annotations:
    retry.linkerd.io/http: 5xx
    retry.linkerd.io/limit: "2"
    retry.linkerd.io/timeout: 300ms
spec:
  parentRefs:
    - name: myapp
      kind: Service
      group: core
      port: 80
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: "/foo/"
```

In short, Linkerd's new implementation of per-route metrics, retries, and
timeouts are now provided in a principled, future-proof way that is composable
with existing features such as circuit breaking, and configured using the
Gateway API resources that we believe are the future of service mesh
configuration.
[Learn more](https://linkerd.io/2/features/retries-and-timeouts/).

## Audit mode for security policies

Linkerd's "zero trust" authorization policies provide a powerful and expressive
mechanism for controlling which network traffic is allowed. They support a wide
variety of approaches to network security, including micro-segmentation and
"deny by default" policies. In contrast to ambient or host-proxy approaches,
Linkerd's sidecar design provides a clear security boundary that fits directly
into the zero trust model, where each pod makes its own authorization decisions
independently, maintains its (and only its) TLS keys, and makes policy decisions
based on cryptographic workload identity, not IP addresses.

However, introducing authorization policy in a live system can be tricky. To
address this, Linkerd 2.16 introduces a new _audit mode_ to policies. In this
mode, policy violations are logged but not enforced. This allows policies to be
rolled out in a lower-risk fashion, as they can now start in audit mode and only
move to enforcement once fully vetted. Audit mode can be enabled cluster-wide,
per-namespace, or on specific Server resources by setting the new `accessPolicy`
field to `audit`, vs its default `deny`.

For example:

```yaml
apiVersion: policy.linkerd.io/v1beta3
kind: Server
metadata:
  namespace: emojivoto
  name: web-http
spec:
  accessPolicy: audit
  podSelector:
    matchLabels:
      app: web-svc
  port: http
  proxyProtocol: HTTP/1
```

Similarly, the `linkerd policy generate` command in Buoyant Enterprise for
Linkerd, which watches live traffic to a system and generates policy scaffolding
that accounts for observed traffic, has been updated to use audit mode by
default.
[Learn more](https://docs.buoyant.io/buoyant-enterprise-linkerd/latest/tasks/generating-policy/).

## IPv6

Linkerd 2.16 adds support for IPv6 on IPv6-only and dual-stack clusters. (When
enabled on dual stack clusters, Linkerd will only use IPv6 endpoints.) For
backwards compatibility, this feature is disabled by default, but enabling it is
a simple boolean. [Learn more](https://linkerd.io/2/features/ipv6/).

## Other noteworthy changes

- Linkerd 2.16 adds HTTP/2 keep-alive messages by default for all meshed
  communication. This helps Linkerd proactively detect connections that have
  been lost by the operating system or underlying network.
- All Linkerd CLI commands that output Kubernetes resources now support JSON
  output.
- To mitigate [CVE-2024-40632](https://nvd.nist.gov/vuln/detail/CVE-2024-40632),
  in which a meshed application that is already vulnerable to an SSRF attack may
  also leave the proxy open to shutdown, the /shutdown endpoint is now disabled
  by default unless explicitly enabled.
- To prevent accidentally logging sensitive information, HTTP headers are no
  longer logged in debug or trace output by default, unless explicitly enabled.
- To remove unnecessary configuration, resource requests for proxy-init now
  simply use those of the proxy.

## Linkerd continues to outperform Istio and Cilium

In May, cloud consultancy [LiveWyre](https://livewyer.io/) published a set of
[service mesh benchmarks](https://livewyer.io/blog/2024/05/08/comparison-of-service-meshes/)
showing that Linkerd resulted in lower latency and less resource consumption
than either Istio or Cilium. This has been the
[consistent result of service mesh benchmarks since 2021](https://linkerd.io/2021/05/27/linkerd-vs-istio-benchmarks/),
and we were happy to see this confirmed by another third party.

## What's next for Linkerd?

Momentum compounds, and Linkerd's momentum is currently at an all-time high.
Since March we've merged 250+ pull requests, revamped our edge release process
to provide
[production-readiness guidance](https://github.com/linkerd/linkerd2/releases)
and
[monthly reviews](https://linkerd.io/2024/08/05/linkerd-edge-release-roundup/),
and published an average of 5 edge releases a month—more than one a week. There
is a lot more great news to report, and early next month we'll publish a deeper
retrospective of the past six months, but in short—it's an incredibly exciting
time to be involved with Linkerd!

We're hard at work on egress functionality, which will provide both visibility
into all traffic leaving the cluster as well as the authorization policies
necessary to control it. Our original plan was to deliver this feature in
Linkerd 2.16, but we ultimately decided some of the features we had already
shipped were too good to delay any longer. Egress is now slated for the upcoming
Linkerd 2.17 release, which should follow relatively quickly after 2.16. After
egress we have our sights on ingress, plus a couple other exciting multi-cluster
features to make managing clusters at scale a lot easier.

We've discussed deprecating ServiceProfiles in the past. Based on the extensive
use within the Linkerd community, we've decided to continue supporting them for
the foreseeable future. However, the new Gateway API retry and timeout logic is
a separate implementation, and that's where our active development will be
focused. We expect the feature gap to grow over time, and encourage you to
migrate to the new types.

## Come see us at KubeCon!

Many of the maintainers will be in attendance at
[KubeCon NA](https://events.linuxfoundation.org/kubecon-cloudnativecon-north-america/)
this November in Salt Lake City, UT, where we have a great lineup of Linkerd
talks as well as many of your fellow Linkerd users. If you're attending the
conference, please stop by the Linkerd booth in the Project Pavilion and say hi!

## Additional content

[Buoyant](https://buoyant.io/), creators of Linkerd, have published a
[release announcement for Buoyant Enterprise for Linkerd 2.16](https://buoyant.io/blog/announcing-linkerd-2-16-ipv6-gateway-api-parity-audit-mode),
and a
[Linkerd 2.16 changelog](https://docs.buoyant.io/release-notes/buoyant-enterprise-linkerd/enterprise-2.16.0/)
with additional guidance and content.

## Linkerd is for everyone

Linkerd is a graduated project of the
[Cloud Native Computing Foundation](https://cncf.io/). Linkerd is
[committed to open governance.](/2019/10/03/linkerds-commitment-to-open-governance/)
If you have feature requests, questions, or comments, we'd love to have you join
our rapidly-growing community! Linkerd is hosted on
[GitHub](https://github.com/linkerd/), and we have a thriving community on
[Slack](https://slack.linkerd.io/), [Twitter](https://twitter.com/linkerd), and
the [mailing lists](/community/get-involved/). Come and join the fun!

## Photo credit

Photo by [Ray Bilcliff](https://www.pexels.com/photo/crashing-waves-1494707/) on
[Pexels](https://pexels.com/).
