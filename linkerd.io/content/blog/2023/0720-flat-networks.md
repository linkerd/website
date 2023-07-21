---
author: 'william'
date: 2023-07-20T00:00:00Z
title: |-
  Enterprise multi-cluster at scale: supporting flat networks in Linkerd
thumbnail: '/uploads/2023/07/nasa-_SFJhRPzJHs-unsplash.jpg'
featuredImage: '/uploads/2023/07/nasa-_SFJhRPzJHs-unsplash.jpg'
tags: [Linkerd]
---

{{< fig
  alt="An image of Manhattan at night, shot from the atmosphere"
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

One of the most important new features in the next Linkerd release will be an
improved ability to handle multi-cluster communication in environments with a
shared flat network between clusters. In this blog post, I'll talk about what
that means and why it's important.

## How does Linkerd handle multi-cluster today?

If you're using multiple Kubernetes clusters and want them to communicate with
each other, Linkerd gives you the ability to send traffic across cluster
boundaries that is:

1. **Fully secured**. This means that traffic between clusters is encrypted,
   authenticated, and authorized using mutual TLS, workload identities (not
   network identities!) and Linkerd's fine-grained, [zero-trust authorization
   policies](https://linkerd.io/2/features/server-policy/).
2. **Transparent to the application.** This means that the application is
   totally decoupled from cluster topology, which allows the operator to
   take advantage of powerful networking capabilities such as [dynamically
   failover traffic to other
   clusters](https://linkerd.io/2/tasks/automatic-failover/).
3. **Observable and reliable**. Linkerd's powerful L7 instrospection and
   reliability mechanisms, including golden metrics, retries, timeouts,
   distributed tracing, circuit breaking, and more, are all available to
   cross-cluster traffic just as they are to on-cluster traffic.

Linkerd has supported multi-cluster Kubernetes deployments since the release of
Linkerd 2.8 in 2020. That release introduced [a simple and elegant
design](https://linkerd.io/2.13/features/multicluster/) that involves the
addition of a service mirror component to handle service discovery, and a
multi-cluster gateway component to handle traffic from other clusters.

This gateway design allowed Linkerd's multi-cluster support to be entirely
independent of underlying network topology. Whether your clusters are colocated
in the same datacenter; split across different cloud providers; or deployed in a
hybrid fashion between on-premises and cloud deployments, Linkerd worked the
same way.

This design has worked well! However, as Kubernetes adoption has grown in
enterprise environments, we've seen a growing number of cases where clusters are
deployed in a shared _flat network_. In this situation, we can make some
significant optimizations by removing the gateway.

## Multi-cluster for flat networks

In a shared flat network situation, pods in different Kubernetes clusters can
route traffic directly to each other. In other words, a pod in cluster 1 can
establish a TCP connection to a pod in cluster 2, just using the underlying
network.

If pods are routable, why use Linkerd? For exactly the same reasons you're using
it within the cluster: to provide the security, reliability, and observability
guarantees beyond what a baseline TCP connection provides.

In Linkerd 2.14, we'll introduce an additional mode of multi-cluster
communication designed for shared flat networks: direct pod-to-pod communication
between clusters without the gateway intermediary.

{{< fig
  alt="An architectural diagram comparing hierarchical network mode with the new flat network mode"
  src="/uploads/2023/07/flat_network@2x.png">}}

In this approach, as you might imagine, Linkerd will route communication from a
pod on the source cluster directly to the destination pod on another cluster
without transiting the gateway. This provides several advantages, including:

* **Improved latency** of cross-cluster calls by removing the additional hop
  between client and server.
* **Improved security** by preserving workload identity in mTLS calls across
  clusters, rather than overriding it with the gateway identity.
* **Reduced cloud spend** by reducing the amount of traffic that is routed through the
  multi-cluster gateway, which is often implemented as a cloud loud balancer.

This approach still preserves two critical aspects of Linkerd's multi-cluster
design:

1. **Separation of failure domains.** Each Kubernetes cluster runs its own
   Linkerd control plane, independently of other clusters, and the failure of a
   single cluster cannot take down the service mesh on other clusters.
2. **Standardized, uniform architecture.**. Unlike other solutions that split
   L7 logic between complex proxies operating at different levels and scopes,
   Linkerd's Rust-based "micro-proxy" sidecars are the sole mechanism for
   controlling traffic between pods and clusters, giving you a single
   operational surface area to monitor and manage, with clear isolation of
   failure and security domains.

Finally, this approach improves Linkerd's ability to provide a uniform layer of
authentication across your entire environment, and to enforce granular
authorization policies, aka "micro-segmentation". Because the gateway is no
longer an intermediary, cross-cluster connections retain the workload identity
of the source, and authorization policies can be crafted to take advantage of
these identities directly.

(For Kubernetes experts, note that this implementation is inspired by, and
loosely aligns with, the [Multi-Cluster Services API proposal
(KEP-1645](https://github.com/kubernetes/enhancements/tree/master/keps/sig-multicluster/1645-multi-cluster-services-api)).
While strict conformance with this KEP is not currently a goal, we look forward
to seeing how that proposal evolves.)

## So when do we get this amazing new feature?

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
