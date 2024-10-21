---
title: 'Mesh expansion and SPIFFE support arriving in the upcoming Linkerd 2.15'
author: 'william'
date: 2023-11-07T00:00:00+00:00
thumbnail: /images/serena-repice-lentini-IgoMDFTKF-U-unsplash.jpg
draft: false
featured: false
slug: linkerd-mesh-expansion
tags: [Linkerd]
---

![A fast-moving clock](/images/serena-repice-lentini-IgoMDFTKF-U-unsplash.jpg)

In the upcoming 2.15 release, I'm happy to report that we'll be shipping both
mesh expansion and support for SPIFFE and SPIRE. We've heard from many Linkerd
adopters over the past 6 months who've let us know that these features are a
priority for them, and we've been working hard to deliver them with all the
simplicity and security that you've come to expect from Linkerd.

This work on Linkerd is jointly sponsored by Buoyant (creators of Linkerd) and
by SUSE, who have [recently announced a partnership on this
topic](https://buoyant.io/blog/suse-rancher-and-buoyant-team-up-to-provide-secure-edge-deployments).

In this blog post I want to describe what these features are, why we're adding
them to Linkerd, and how we tackled some of the design decisions behind the
scenes.

## What is mesh expansion?

Mesh expansion is the ability to run Linkerd's dataplane outside of the
Kubernetes cluster, allowing you to bring non-K8s workloads, including legacy
applications running on VMs, into the mesh. Once in the mesh, all communication
to and from these non-Kubernetes applications get the same security,
reliability, and observability features that Linkerd provides for on-cluster
resources, including encryption, authentication, authorization using true
workload identity (not IP address!), retries, timeouts, latency-aware load
balancing, failover, and more.

In short: mesh expansion means Linkerd will support non-Kubernetes workloads, a
major step forward for the project. And a major challenge for the project as
well.

Happily, Linkerd has one big advantage in tackling mesh expansion, stemming from
an early design decision. In Linkerd, the "dataplane" refers to Linkerd's Rust
_microproxies_, which handle the actual sensitive information traveling between
application components. These microproxies are actually not Kubernetes-specific
at all. They _are_ specific to Linkerd, i.e. they're not general-purpose
proxies, but they don't know anything about Kubernetes; they don't talk to the
Kubernetes API; and they don't have any requirements about being run on a
Kubernetes cluster or even in a container. Linkerd's microproxies are delivered
as static binaries which can be compiled for a variety of architectures and
platforms, meaning that they can run on almost any machine in the world
(including ARM64, which Linkerd has supported for years.)

(This microproxy approach is also what makes Linkerd unique in the service mesh
space, and allows it to deliver all the security and operational benefits of a
sidecar approach without the drawbacks found in other service mesh projects.
I've written a lot about this in [my writeup on eBPF vs
sidecars](https://buoyant.io/blog/ebpf-sidecars-and-the-future-of-the-service-mesh).)

So for Linkerd, at least, running the proxies outside of Kubernetes is easy. But
that is just one small part of a much larger set of requirements for mesh
expansion.

## What does mesh expansion require?

The biggest challenge for mesh expansion is that, as you might expect,
Kubernetes is no longer available to provide the infrastructure we can build on!
In our design process for mesh expansion, we uncovered four key areas to this
problem:

* **Identity.** Linkerd needs to provide a secure workload identity for
  everything in the mesh. Linkerd's security model follows the mantra of "don't
  trust the network" and this means that, unlike the NetworkPolicy approach
  found in CNIs, it cannot rely on IP addresses as a form of identity. (I've
  written about this in [my guide to zero trust network security for
  Kubernetes](https://buoyant.io/resources/zero-trust-in-kubernetes-with-linkerd).)
  In Kubernetes, we can use ServiceAccounts as core identity, but outside of
  Kubernetes we need another solution.
* **Network connectivity.** Inside a Kubernetes cluster, Linkerd can assume we
  have direct connectivity between any proxy and Linkerd's control plane.
  Outside of Kubernetes, we need some guaranteed way to establish a connection
  from the proxy to the control plane.
* **Runtime.** In Kubernetes we can make use of tools like mutating admission
  controllers to automatically inject the sidecar microproxy into workloads that
  need to be meshed, and on init containers (and soon, sidecar containers—see my
  writeup on [Kubernetes's new sidecar container feature and what it
  enables](https://buoyant.io/blog/kubernetes-1-28-revenge-of-the-sidecars)) to
  handle L4 networking setup so that all traffic to the pod is transparently
  routed through the data plane. Outside of Kubernetes, we need some equivalent
  to this functionality.
* **Service discovery**. Inside Kubernetes, we can rely on the built-in DNS
  system to give us information about any service that an application wants to
  connect to. And when the endpoints for a service change, Kubernetes gives us
  ways of keeping up to date with new endpoints and removing old, stale, and
  unhealthy endpoints. Outside of Kubernetes, we're on our own.

Each of these is a distinct and non-trivial challenge, and for Linkerd to have
mesh expansion, each needs to be solved.

For the purposes of this blog post, the most interesting of these challenges to
discuss is the first one: identity. This is because the solution that Linkerd is
embracing involves another CNCF project called SPIFFE.

## What are SPIFFE and SPIRE?

[SPIFFE](https://spiffe.io) is a standard for machine identity, and SPIRE is an
implementation of that standard. What that means is that, if you have an
arbitrary workload on an arbitrary machine, SPIFFE gives you a format for
communicating an identity for that workload that can be used for
security-critical activities such as authentication and authorization. And if
you want to start providing SPIFFE-compatible certificates in a secure way,
SPIRE is a piece of software that will produce these ids for arbitrary
workloads.

The astute reader will notice that this is exactly the identity-related
challenge that Linkerd faces when extending the mesh to non-Kubernetes
workloads. And in fact, SPIFFE is based on X.509 certificates—the exact same
type of credentials used by TLS, including by Linkerd's on-by-default mutual TLS
which forms the basis of many of its security guarantees.

So it's a great fit: Linkerd needs a non-Kubernetes-specific mechanism for
determining workload identities, and SPIRE provides exactly that, using a format
that can be plugged right into Linkerd's existing mTLS infrastructure.

## So what does this mean for me?

In short, if you are a Kubernetes adopter with "legacy" (read: non-Kubernetes)
workloads that run on Linux-based systems, whether VM or bare metal, Linkerd
2.15 will allow you to communicate between those systems and your Kubernetes
applications in a way that's secure, reliable, and observable, all without
requiring changes to your applications.

This means you can extend Linkerd's new model of networking—where every
connection is encrypted and authenticated, and every HTTP and gRPC request
delivered in a reliable and latency-optimized way—to your entire stack, not just
the portion that runs on Kubernetes.

## When will these amazing features be available in Linkerd?

We're already in late-stage prototype and design, and are currently estimating
Linkerd 2.15 will arrive with these features early next year.

If you're at Kubecon NA in Chicago this week, please swing by and meet several
Linkerd maintainers who are in attendance at the Linkerd project pavilion as
well as the Buoyant and SUSE expo hall booths. We'd love to dig into your
requirements for mesh expansion and more, and even just to say hi.

## Linkerd is for everyone

Linkerd is a graduated project of the [Cloud Native Computing
Foundation](https://cncf.io/). Linkerd is [committed to open
governance.](/2019/10/03/linkerds-commitment-to-open-governance/) If you have
feature requests, questions, or comments, we'd love to have you join our
rapidly-growing community! Linkerd is hosted on
[GitHub](https://github.com/linkerd/), and we have a thriving community on
[Slack](https://slack.linkerd.io/), [Twitter](https://twitter.com/linkerd), and
the [mailing lists](/community/get-involved/). Come and join the fun!

_(Photo by [Serena Repice
Lentini](https://unsplash.com/@serenarepice?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash)
on
[Unsplash](https://unsplash.com/photos/brown-octopus-IgoMDFTKF-U?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash).)_
