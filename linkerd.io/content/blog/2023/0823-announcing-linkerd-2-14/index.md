---
date: 2023-08-23T00:00:00+00:00
slug: announcing-linkerd-2.14
title: |-
  Announcing Linkerd 2.14: Improved enterprise multi-cluster, Gateway API
  conformance, and more!
keywords: [linkerd]
params:
  author: william
  showCover: true
---

Over the past 18 months, the adoption of Linkerd has skyrocketed in enterprise
environments, with companies like
[Adidas](https://buoyant.io/case-studies/adidas),
[Microsoft](https://buoyant.io/case-studies/xbox),
[Plaid](https://www.cncf.io/blog/2023/07/17/plaid-pain-free-deployments-at-global-scale/),
and [DB Schenker](https://buoyant.io/case-studies/schenker) deploying Linkerd to
bring security, compliance, and reliability to their mission-critical production
infrastructure. Today, we're happy to announce the release of Linkerd 2.14 with
improved support for multi-cluster deployments on shared flat networks, full
Gateway API conformance, and much more.

The 2.14 release comes just four months after our massive
[Linkerd 2.13 release with circuit breaking and dynamic request routing](https://buoyant.io/blog/announcing-linkerd-2-13-circuit-breaking-dynamic-request-routing-fips),
and continues Linkerd's focus on coupling enterprise-grade power and flexibility
with the best operational model simplicity and lowest TCO of any service mesh.

This release includes a lot of hard work from 25+ contributors. A special thank
you to [Amir Karimi](https://github.com/AMK9978),
[Amit Kumar](https://github.com/amit-62),
[Andre Marcelo-Tanner](https://github.com/kzap),
[Andrew](https://github.com/andrew-gropyus),
[Arnaud Beun](https://github.com/bunnybilou),
[Clement](https://github.com/proxfly), [Dima](https://github.com/krabradosty),
[Grégoire Bellon-Gervais](https://github.com/albundy83),
[Harsh Soni](https://github.com/harsh020),
[Jean-Charles Legras](https://github.com/jclegras),
[Loong Dai](https://github.com/daixiang0),
[Mark Robinson](https://github.com/MarkSRobinson),
[Miguel Elias dos Santos](https://github.com/migueleliasweb),
[Pranoy Kumar Kundu](https://github.com/pranoyk),
[Ryan Hristovski](https://github.com/ryanhristovski),
[Takumi Sue](https://github.com/mikutas),
[Zakhar Bessarab](https://github.com/zekker6),
[hiteshwani29](https://github.com/hiteshwani29),
[pheianox](https://github.com/pheianox), and
[pssalman](https://github.com/pssalman) for all your hard work!

## Multi-cluster support for shared flat networks

Linkerd 2.14 introduces improved multi-cluster support for clusters deployed on
a shared flat network. Increasingly common in enterprise environments, this
network architecture allows pods in different clusters to establish TCP
connections with each other. Linkerd takes advantage of this ability to add a
new "gateway-less" mode for cross-cluster communication. In this mode, Linkerd
establishes cross-cluster connections across clusters without transiting a
multi-cluster gateway. This improves performance by reducing the latency of
cross-cluster calls; it improves security by preserving workload identity in
mTLS calls across clusters; and it reduces cloud spend by reducing the amount of
traffic that is routed through the multi-cluster gateway.

Of course, Linkerd ensures that these cross-cluster connections are established
with all the same guarantees as in-cluster connections: they are fully
transparent to the application with the same security, reliability, and
observability capabilities, including encryption, authentication, and
zero-trust-capable authorization policies. This mode is also purely additive,
and in heterogeneous network environments where flat networks are not possible,
Linkerd's existing gateway-based approach functions as normal.

Importantly, this new multi-cluster support retains a critical aspect to
Linkerd's design: independence of clusters as a way of isolating security and
failure domains. Each cluster runs its own Linkerd control plane, and the
failure of a single cluster cannot take down the service mesh on other clusters.
(And Linkerd provides a set of powerful techniques including
[cross-cluster failover](/2.14/tasks/automatic-failover/) that can be used to
automatically route traffic to the remaining clusters.)

For more details on Linkerd's new support for multi-cluster across flat
networks, see
[Enterprise multi-cluster at scale: supporting flat networks in Linkerd](/2023/07/20/enterprise-multi-cluster-at-scale-supporting-flat-networks-in-linkerd/).

## Gateway API conformance

Starting way back in the Linkerd 2.12 release, Linkerd has been on the forefront
of adopting Kubernetes's new [Gateway API](https://gateway-api.sigs.k8s.io/) as
the core configuration mechanism for Linkerd, including for features such as
[zero trust authorization policy](https://linkerd.io/2.13/features/server-policy/)
and
[dynamic request routing](https://linkerd.io/2.13/features/request-routing/).
Adopting the Gateway API has a whole host of benefits for users, from providing
standardized mechanisms for configuring complex resources such as classes of
HTTP requests to providing a uniform API across ingress and service meshes
to—most importantly for Linkerd's philosophy of minimalism—reduction of
additional configuration surface area, since the Gateway configuration resources
that already live on the cluster.

In the Linkerd 2.14 release we're happy to report that Linkerd is now fully
conformant with the mesh profile of the Gateway API. This means that Linkerd now
uses the core gateway.networking.k8s.io types, and that features like retries,
timeouts, and progressive delivery are now fully configurable via these types
without the requirement to use the earlier ServiceProfile resources.

The Linkerd team has been co-leading the GAMMA initiative to adapt the Gateway
API to service mesh use cases, and we're looking forward to watching this
standard evolve over time.

## And lots more!

Linkerd 2.14 also has a tremendous list of other improvements, performance
enhancements, and bug fixes, including:

- A new `-o json` flag for the linkerd multicluster gateways command
- A new `logFormat` value to the multicluster Link Helm Chart (thanks
  @bunnybilou!)
- New leader-election capabilities to the service-mirror controller
- A new high-availability (HA) mode for the multicluster service-mirror
- A new `outbound_http_balancer_endpoints` metric
- A fix for missing route\_ metrics for requests with ServiceProfiles
- A fix for proxy startup failure when using the `config.linkerd.io/admin-port`
  annotation.
- The `linkerd diagnostics policy` command now displays outbound policy when the
  target resource is a Service
- A fix for HA validation checks when Linkerd is installed with Helm.
- A fix for the `linkerd viz check` command so that it will wait until the viz
  extension becomes ready
- A new `-o jsonpath` flag to linkerd viz tap to allow filtering output fields
- Tolerations and nodeSelector support in extensions namespace-metadata Jobs
- Build improvements for multi-arch build artifacts. Thanks @MarkSRobinson!!

And more. See the
[full release notes](https://github.com/linkerd/linkerd2/releases/tag/stable-2.14.0)
for details.

## What's next?

Last year was a banner year for Linkerd—the
[number of stable Kubernetes clusters running Linkerd doubled in 2022](https://linkerd.io/2022/12/28/service-mesh-2022-recap-ebpf-gateway-api/),
and the project gained
[multi-cluster failover](https://linkerd.io/2022/03/09/announcing-automated-multi-cluster-failover-for-kubernetes/)
and
[full L7 authorization policy based on the Gateway API](https://buoyant.io/blog/announcing-linkerd-2-12).
In 2023, with Linkerd 2.13 and 2.14 already under our belts, we're off to a
great pace. We have some amazing features and ideas up our sleeves that we can't
wait to unveil later this year. Stay tuned!

## Linkerd is for everyone

Linkerd is a graduated project of the
[Cloud Native Computing Foundation](https://cncf.io/). Linkerd is
[committed to open governance.](/2019/10/03/linkerds-commitment-to-open-governance/)
If you have feature requests, questions, or comments, we'd love to have you join
our rapidly-growing community! Linkerd is hosted on
[GitHub](https://github.com/linkerd/), and we have a thriving community on
[Slack](https://slack.linkerd.io/), [Twitter](https://twitter.com/linkerd), and
the [mailing lists](/community/get-involved/). Come and join the fun!

(Photo by
[drmakete lab](https://unsplash.com/@drmakete?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText)
on
[Unsplash](https://unsplash.com/photos/hsg538WrP0Y?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText))
