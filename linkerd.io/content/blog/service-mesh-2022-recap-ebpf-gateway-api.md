---
title: "Service mesh 2022 recap: Linkerd adoption doubled, and what we learned about eBPF, the Gateway API, and more"
author: 'william'
date: 2022-12-28T00:00:00+00:00
thumbnail: /images/pan-xiaozhen-ydew6pvUlHc-unsplash.jpg
featured: false
slug: service-mesh-2022-recap-ebpf-gateway-api
tags: [Linkerd]
---

![A road behind a car through a sideview mirror](/images/pan-xiaozhen-ydew6pvUlHc-unsplash.jpg
)

It's been a good year for Linkerd. Although much of the software industry has
struggled through an economic downturn, Linkerd adoption has only been growing.
In fact, log metrics show that **the number of stable Kubernetes clusters
running Linkerd doubled in 2022**. Linkerd may be the only service mesh to
achieve graduation status from the CNCF, but it's certainly not slowing down!

Where did this growth come from, and why now? Based on conversations with new
adopters throughout the year, our theory is this: the service mesh got a bad rap
early on, thanks to extreme levels of hype coupled with the relative immaturity
and complexity of the most-hyped projects. Early adopters decided to hold off
until the dust settled. Now they're back—and seeing what happened the first
time, they're looking for an option that won't leave them holding the proverbial
bag of operational complexity.

Naturally they turn to Linkerd, which is unique in the service mesh space for
its simplicity. Much of Linkerd's advantage comes down to its data plane.
Linkerd is the only service mesh to eschew Envoy and focus instead on a
dedicated sidecar "micro-proxy". In 2018, this was a controversial decision; in
2022, this approach continued to pay off in spades. While other projects spent
time building workarounds for the complexity and resource consumption of their
data plane, Linkerd instead focused on shipping powerful features like
[multi-cluster
failover](https://linkerd.io/2022/03/09/announcing-automated-multi-cluster-failover-for-kubernetes/)
and [full L7 authorization policy based on the Gateway
API](https://buoyant.io/blog/announcing-linkerd-2-12).

But 2022 also didn't turn out exactly how we thought it would. Even us grizzled
service mesh veterans can still learn some lessons, and we navigated some real
surprises through the year. Here are a few the things that surprised us in 2022.

## Surprise #1: Kubernetes's Gateway API is a great match for the service mesh

By far our biggest surprise of the year was the Gateway API, which actually
caused us to change our plans mid-course. The Gateway API hit beta in Kubernetes
mid-year just as we were finalizing Linkerd's L7 authorization feature. When we
took a deeper look at the project, we realized a couple things:

1. It already solved a major problem we were tackling in Linkerd 2.12: how do
   you describe a class of HTTP traffic (e.g. "everything starting with /foo/"
   or "everything with this header") in a comprehensive, composable, yet
   Kubernetes-y way?
2. Unlike the CRDs we had reluctantly planned to add to Linkerd to do this, the
   Gateway API resources were already part of Kubernetes.
3. Its design was good. Really good. While it was originally designed to handle
   ingress configuration, the core primitives were flexible and composable
   enough that it actually worked for the service mesh use case as well.

So we scuttled our original plans and pivoted to [adopt the Gateway API as the
core configuration mechanism for Linkerd's authorization
policies](https://buoyant.io/blog/linkerd-and-the-gateway-api). Even though this
would delay the 2.12 release by a few months, we knew this was the right thing
for Linkerd's adopters.

The decision is paying off already. In the upcoming 2.13 release, we are
leveraging Gateway API resource types for features like header-based routing and
configurable circuit-breaking. Linkerd is also participating in the [GAMMA
initiative](https://gateway-api.sigs.k8s.io/contributing/gamma/), a project in
the Gateway API to better capture the service mesh use cases.

Further reading: [Linkerd and the Gateway
API](https://buoyant.io/blog/linkerd-and-the-gateway-api).

## Surprise #2: eBPF was an optimization but not a game changer

When the buzz around eBPF for service meshes came to a head early in the year,
we decided to take a deeper look. What we found was less compelling than we
hoped. While eBPF can streamline some basic service mesh tasks such as
forwarding raw TCP connections, its fundamental inability to handle HTTP/2,
mTLS, or other L7 tasks without a userspace component meant that it would not
provide a radical change—even with eBPF, a service mesh would still need L7
proxies somewhere on the cluster.

The much-touted "sidecar-free eBPF service mesh" model, especially, felt like [a
major step backwards in operability and
security](https://buoyant.io/blog/ebpf-sidecars-and-the-future-of-the-service-mesh).
By shifting that logic into per-host Envoy proxies that mix both networking
concerns and TLS key material for everything on the node, they defeat much of
the point of why we're containerizing things in the first place. Nothing about
eBPF requires a per-host approach, and we were disappointed to see marketing
material conflating the two.

In the future we do plan on investigating eBPF as a way to streamline Linkerd's
L4 featureset, though the prospect of shifting critical code into the kernel,
where it is significantly harder to debug, observe, and reason about, makes us
antsy. (Not to mention the [new and exciting attack vectors that eBPF
introduces](https://pentera.io/blog/the-good-bad-and-compromisable-aspects-of-linux-ebpf/).)

Overall, we left our eBPF investigation not really convinced about eBPF, but
more convinced than ever that _sidecars_ continued to be the best model for the
service mesh for both operational and security reasons.

Further reading: [eBPF, sidecars, and the future of the service
mesh](https://buoyant.io/blog/ebpf-sidecars-and-the-future-of-the-service-mesh).

## Surprise #3: The ambient mesh

Sidecar-free eBPF service meshes were soon joined by Istio's sidecar-free
"ambient mesh" mode, which uses a combination of per-host and per-service
proxies. Diving into this approach was another learning experience for us, and
we were heartened to see that here, at least, the security story was better: for
example, the TLS key material for separate identities was maintained in separate
processes.

However, the tradeoff for removing sidecars was steep: a lot of new machinery is
required, and the result had [non-trivial
limitations](https://github.com/istio/istio/tree/experimental-ambient#limitations)
as well as significant consequences for performance.

Overall, the vedict was that the improvements in lifecycle management and
resource consumption don't add up in Linkerd's case. Our sense is that ambient
mesh is more a solution to the problem of running Envoy at scale than anything
else.

## Non-surprise #1: container ordering continues to be a weak point for Kubernetes

In addition to surprises, we saw some non-surprises in 2022. As in previous
years, Linkerd adopters continued to struggle with Kubernetes's perennial
bugbear—lack of control over container ordering.  This manifested in a variety
of ways:

* Sidecar containers that require network access need a way to run after the
  linkerd-init container
* Jobs that terminate need a way to signal this termination to their proxy
  component
* Nodes that restart or are added to an existing cluster need a way to pause
  Linkerd's network initialization until after the CNI layer has initialized
* And so on.

Each of these is solvable in specific situations, but the general class of
problem continues to be a nuisance for service mesh adopters and the most
egregious violation of our principle that the service mesh should be transparent
to the application. With the infamous [sidecar
KEP](https://github.com/kubernetes/enhancements/issues/753) gone the way of the
dodo, however, we may have to suffer through a bit longer.

Although, rumors swirl about another KEP...

{{< tweet user="La_Rainette" id="1591198130049257473" >}}

Further reading: [What really happens at startup: Linkerd, init containers, the
CNI, and
more](https://linkerd.io/2022/12/01/what-really-happens-at-startup-linkerd-init-containers-the-cni-and-more/).

## Non-surprise #2: Security continues to be a top driver of Linkerd adoption

As in previous years, the primary driver of Linkerd adoption continued to be
security. Linkerd's [zero-config mutual
TLS](https://linkerd.io/2.12/features/automatic-mtls/) has always been a major
draw for the project and the introduction of [L7 authorization
policy](https://buoyant.io/blog/announcing-linkerd-2-12) this year rounded out
Linkerd's zero trust featureset.

We were also heartened to see signs of growing maturity in the market. A few
years ago, "we need encryption in transit" was the primary justification for
adopting mTLS. In 2022, we heard many adopters instead say, "yes we need
encryption in transit, but also authentication with true workload identity, and
zero-trust authorization at every pod". It's no secret that zero trust is
gaining real traction, and the [sidecar-based service mesh is nothing if not a
direct implementation of zero trust
principles](https://buoyant.io/resources/zero-trust-in-kubernetes-with-linkerd).
Score another point for the sidecar model!

As usual, we also try to keep our house clean, and Linkerd [completed its annual
security audit with flying
colors](https://linkerd.io/2022/06/27/announcing-the-completion-of-linkerds-2022-security-audit/).

### What's coming up for service meshes in 2023?

Next year promises to be another banner year for Linkerd. We've got some
incredibly exciting things planned, ranging from the upcoming 2.13 release with
header-based routing and circuit breaking to a few other killer ideas we're
keeping under wraps for now.  As always, we'll stay laser-focused on keeping
Linkerd simple, light, and secure.

Want to get involved with the CNCF's first and only graduation-tier service
mesh? It's a great time to join the project.

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

(*Photo by [Pan Xiaozhen](https://unsplash.com/@zhenhappy?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText)
on
[Unsplash](https://unsplash.com/?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText).*)
