---
author: 'william'
date: 2023-07-19T00:00:00Z
title: |-
  Enterprise multi-cluster at scale: supporting flat networks in Linkerd
thumbnail: '/uploads/2023/07/nasa-_SFJhRPzJHs-unsplash.jpg'
featuredImage: '/uploads/2023/07/nasa-_SFJhRPzJHs-unsplash.jpg'
tags: [Linkerd]
---

{{< fig
  alt="An image of Manhattan at night, shot from the atmosphere"
  title="Welcome OSM Users!"
  src="/uploads/2023/07/nasa-_SFJhRPzJHs-unsplash.jpg" >}} <!--_ -->

Linkerd has seen a steady rise in enterprise adoption, with companies like
[Adidas](https://buoyant.io/case-studies/adidas),
[Microsoft](https://buoyant.io/case-studies/xbox),
[Plaid](https://www.cncf.io/blog/2023/07/17/plaid-pain-free-deployments-at-global-scale/),
and [DB Schenker](https://buoyant.io/case-studies/schenker) deploying Linkerd at
scale to bring security, compliance, and reliability to their mission-critical
production infrastructure. Based on feedback from this enterprise audience, the
upcoming Linkerd 2.14 release will introduce a new set of features designed to
handle types of multi-cluster Kubernetes configurations commonly found in
enterprise deployments.

One of the most important new features will be the ability for Linkerd to
_establish mTLS pod-to-pod communication directly across Kubernetes clusters,
without the use of a gateway intermediary_. In this blog post, I'll talk about
what that means, why it's important, and how it relates to trends we've seen in
large-scale enterprise Kubernetes deployments.

## How does Linkerd handle multi-cluster today?

Linkerd has supported multi-cluster Kubernetes deployments since the release of
Linkerd 2.8 in 2020. That release introduced [a simple and elegant
design](https://linkerd.io/2.13/features/multicluster/) that involves the
addition of a service mirror component to handle service discovery, and a
multi-cluster gateway component to handle traffic from other clusters. This
allows Linkerd to provide communication across Kubernetes clusters that is:

1. Fully transparent to the application;
2. Secure across clusters, even across the open internet; and
3. Entirely independent of underlying network topology.

That final point is the salient feature of this design: whether your clusters
are colocated in the same datacenter; split across different cloud providers; or
deployed in a hybrid fashion between on-premises and cloud deployments,
Linkerd's multi-cluster approach provides a uniform way to connect Kubernetes
clusters that offers the same guarantees of secure, transparent, and observable
communication for cross-cluster communication as for in-cluster communication.

This design has worked well for companies that have Kubernetes
deployments that are naturally split into heterogeneous networks. However, as
Kubernetes adoption has grown in the enterprise, we've seen a growing number of
cases where clusters are deployed in a shared _flat network,_ where the
underlying networking infrastructure allows the pods in different clusters to
address and route traffic directly to each other. In these cases, Linkerd's use
of a gateway in between pods is unnecessary.

## Multi-cluster for flat networks

In Linkerd 2.14, we'll introduce an additional mode of multi-cluster
communication designed for flat networks: direct pod-to-pod communication across
Kubernetes clusters.

In this approach, as you might imagine, Linkerd will route communication from a
pod on the source cluster directly to the destination pod on another cluster
without transiting a gateway. This approach solves several key needs for
enterprise adopters and customers who use flat networks, including:

* Improving the latency of cross-cluster calls by removing the additional hop
  between client and server.
* Improving security by preserving workload identity in mTLS calls across
  clusters, rather than overriding it with the gateway identity.
* Improving costs by reducing the amount of traffic that is routed through the
  multi-cluster gateway. (In cloud environments, the gateway typically requires
  a cloud load balancer, which incurs network costs based on the amount of
  traffic the handle.)
* Getting us closer to supporting pod-to-pod protocols like Raft, a requirement
  for supporting modern distributed storage systems that operate across clusters.

This approach also still preserves a critical aspect of Linkerd's multi-cluster
design: separation of failure domains. Each Kubernetes cluster runs its own
Linkerd control plane, independently of other clusters, and the failure of a
single cluster cannot take down the service mesh on other clusters. As usual,
techniques such as [cross-cluster
failover](https://docs.google.com/document/u/0/d/14vN86Ndnq5qRwZpGEbGghTauKwQaiDzJUIGLDO5sjzk/edit)
can be used to automatically route traffic to the remaining clusters.

Finally, this approach actually improves Linkerd's ability to provide a uniform
layer of authentication across your entire environment, and to enforce granular
authorization policies aka "micro-segmentation". Because the gateway is no
longer an intermediary, cross-cluster connections retain the workload identity
of the source, and authorization policies can be crafted to take advantage of
these identities directly.

(For Kubernetes experts, note that this implementation is inspired by, and
loosely aligns with, the [Multi-Cluster Services API proposal
(KEP-1645](https://github.com/kubernetes/enhancements/tree/master/keps/sig-multicluster/1645-multi-cluster-services-api)).
While strict conformance with this KEP is not currently a goal, we look forward
to seeing how that proposal evolves.)

## So when do we get this capability?

Linkerd 2.14 will be shipping next month. With the addition of pod-to-pod
communication, we're confident that Linkerd will continue to be the simplest way
to connect multiple Kubernetes clusters, now including for deployments that can
make use of flat networks.

## Linkerd is for everyone

Linkerd is a [graduated project](/2021/07/28/announcing-cncf-graduation/) of the
[Cloud Native Computing Foundation](https://cncf.io/). Linkerd is [committed to
open
governance.](https://linkerd.io/2019/10/03/linkerds-commitment-to-open-governance/)
If you have feature requests, questions, or comments, we'd love to have you join
our rapidly-growing community! Linkerd is hosted on
[GitHub](https://github.com/linkerd/), and we have a thriving community on
[Slack](https://slack.linkerd.io/), [Twitter](https://twitter.com/linkerd), and
the [mailing lists](https://linkerd.io/2/get-involved/). Come and join the fun!

(*Photo by
[NASA](https://unsplash.com/@nasa?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText)
on
[Unsplash](https://unsplash.com/photos/_SFJhRPzJHs?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText)*)
