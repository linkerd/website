---
date: 2024-02-21T00:00:00Z
slug: announcing-linkerd-2.15
title: Announcing Linkerd 2.15 with mesh expansion, native sidecars, and SPIFFE
keywords: [linkerd, "2.15", features, vault]
params:
  author: william
  showCover: true
---

Today we're happy to announce the release of Linkerd 2.15, which adds support
for workloads outside of Kubernetes. This new "mesh expansion" feature allows
Linkerd users for the first time to bring applications running on VMs, physical
machines, and other non-Kubernetes locations into the mesh, delivering Linkerd's
uniform layer of secure, reliable, and observable connectivity across both
Kubernetes and non-Kubernetes workload alike.

The 2.15 release also introduces support for [SPIFFE](https://spiffe.io), a
standard for workload identity which allows Linkerd to provide cryptographic
identity and authentication to off-cluster workloads, and for native _sidecar
containers_, a new Kubernetes feature that eases some of the long-standing
annoyances of the sidecar model in Kubernetes, especially with Job workloads.

Finally, this release introduces some important changes in the way that we're
publishing Linkerd. While Linkerd will always be open source, as of 2.15, we
will no longer be producing open source stable release artifacts. If you're
running Linkerd in production today, please see the section
[A new model for stable releases](#a-new-model-for-stable-releases) below for
what this means for you.

As usual, the 2.15 release includes a massive list of bugfixes and improvements.
Read on for details!

## Mesh expansion

As [we promised last November](/2023/11/07/linkerd-mesh-expansion/), Linkerd
2.15 introduces _mesh expansion_: the ability to deploy Linkerd's ultralight
Rust microproxies anywhere outside of Kubernetes and connect them to a Linkerd
control plane running on a Kubernetes cluster. This allows Linkerd to handle
non-Kubernetes workloads, upleveling all TCP communication to and from these
workloads secure, reliable, and observable. Non-Kubernetes applications get the
full set of Linkerd features, including mutual TLS, retries, timeouts, circuit
breaking, latency-aware load balancing, dynamic per-request routing, zero trust
authorization policies, and much more.

Mesh expansion is an important part of achieving our goal of making Linkerd the
_universal networking layer for cloud native organizations_. While we love
Kubernetes, we recognize that even the most sophisticated organizations often
still have significant investments in applications that don't run outside of it.
With Linkerd 2.15, regardless of whether your workloads are running on
resource-constrained ARM64 edge devices, legacy "big iron" VMs, or physical
machines in your server closet, Linkerd's uniform layer of security,
reliability, and observability is at your disposal.

This move was made significantly easier by Linkerd's core design of ultralight
microproxies written in the Rust programming language. The use of Rust, which
has the
["ability to prevent memory-related bugs, manage concurrency, and generate small, efficient binaries"](https://github.blog/2023-08-30-why-rust-is-the-most-admired-language-among-developers/#:~:text=Rust's%20minimal%20runtime%20and%20control,%2Dtime%2C%20and%20efficiency%20needs.)
allows Linkerd not just to avoid the memory vulnerabilities that are endemic to
languages like C and C++, but to provide minimal resource footprint and—most
importantly—a minimal operational burden to the user. Linkerd's Rust
microproxies are key to its simplicity-first approach, and our ability to
deliver small, static binaries which can be compiled for a wide variety of
architectures and platforms was key to unlocking Linkerd's new mesh expansion
capabilities.

## SPIFFE support

One major challenge in mesh expansion is how to generate _workload identities_
for non-Kubernetes workloads. To solve this, we introduced support for
[SPIFFE](https://spiffe.io), a CNCF graduated project that addresses exactly
that concern.

Workload identity is central to Linkerd's approach to communication security.
Rather than relying on easily-spoofed IP addresses to identify clients and
servers, Linkerd _doesn't trust the network_: it secures communication with
mutual TLS, which not only encrypts the communication and prevents tampering,
but also but cryptographically authenticates the identities of client and server
based on unique workload identities. Mutual TLS is a stricter variation of the
same well-established protocol (TLS) that powers the majority of the Internet
today.

Prior to Linkerd 2.15, Linkerd could simply use the workload's Kubernetes
ServiceAccount to automatically generate a workload identity. Using this
pre-existing identity was central to our "zero config zero trust" approach that
makes dropping mTLS into an existing Kubernetes application trivial, and we
continue to support it in Linkerd 2.15.

For workloads running outside of Kubernetes, however, there are no
ServiceAccounts to rely on: only applications running on machines. To solve
this, we turned to SPIFFE, a standard hosted by the CNCF, and its reference
implementation, SPIRE. These two projects solve the problem of generating secure
workload identity for arbitrary processes on arbitrary machines. Linkerd 2.15
generates SPIFFE ids for non-Kubernetes workloads using SPIRE, and these ids can
be used alongside Linkerd's existing ServiceAccount-based ids as the basis for
Linkerd's zero-trust authorization policies.

With Linkerd 2.15 you can now encrypt all traffic to your VM workloads by
default, and add zero-trust controls over all access right down to the level of
individual HTTP routes and gRPC methods for specific clients.

## Native sidecar support

Linkerd 2.15 adds support for native _sidecar containers_, a new Kubernetes
feature that was introduced in 1.28 and is enabled by default in Kubernetes
1.29. Deploying Linkerd with native sidecars
[fixes some of the long-standing annoyances of using sidecar containers in Kubernetes](https://buoyant.io/blog/kubernetes-1-28-revenge-of-the-sidecars),
especially around support for Jobs and race conditions around container startup.

## A new model for stable releases

In Linkerd 2.15 we're making some significant changes to the way that Linkerd is
delivered.

While Linkerd will always be open source, as of Linkerd 2.15, producing stable
Linkerd releases will be in the hands of the vendor community. This includes not
just Linkerd 2.15.0 but point releases like the upcoming Linkerd 2.15.1, major
releases like the upcoming 2.16.0, and backports like the upcoming Linkerd
2.14.11, all of which will be handled by the vendor community.

We'll continue publishing edge releases to the GitHub repo as usual, which
contain the latest Linkerd code including bugfixes, new features, and more.
These have always served as a valuable mechanism for early testing and vetting
by the community, and we hope to see more of this under this new framework. And,
of course, Linkerd development continues as normal, including feature
development, our security vulnerability response policy, and all the other
activities that go into making Linkerd great.

Buoyant, the creators of Linkerd,
[have announced the release of Buoyant Enterprise for Linkerd 2.15.0 and provided some context behind this change](https://buoyant.io/blog/announcing-linkerd-2-15-vm-workloads-spiffe-identities).

To be clear: Linkerd continues to be, and always will be, open source. This
change is about the release artifacts, not about code, governance, community, or
anything else. We've been open source users, contributors, and advocates since
long before we created Linkerd, and our commitment to a healthy, inclusive,
collaborative, and ever-growing open source Linkerd remains as strong as ever.

## What's next for Linkerd?

You might've noticed that the pace of iteration for Linkerd has increased
substantially. Over the past 6 months alone we've shipped 12 stable releases, 16
edge releases, and merged hundreds and hundreds of branches, while keeping our
quality bar as high as ever—if not higher. Momentum compounds, and we're excited
to tackle the next set of challenges.

First, there are a couple important features that didn't quite make it into
2.15.0 that we're going to address as part of subsequent point releases. This
starts with **extending our support for mesh expansion to include private
networks**, so that customers who don't have a shared flat network spanning
Kubernetes and non-Kubernetes applications can make full use of the new mesh
expansion capabilities.

We're also going to **bring our Gateway API and non-Gateway API interfaces up to
parity** in an upcoming 2.15 point release. Today we have a non-unified set of
APIs across our Gateway API-based configs and our earlier pre-Gateway API
configs, and that causes unnecessary friction for users. While we believe that
the Gateway API is the future, we recognize it's not the present for many users.
We're committed to supporting our users who are using ServiceProfiles and other
pre-Gateway API configuration mechanisms, and bringing these two interfaces into
parity is vital to achieving that goal.

**Support for IPv6** is another short-term priority for Linkerd and we expect to
have some news regarding that in the near future. We've seen increasing demands
for this from our customers and the required changes are reasonably well-scoped.

Beyond those smaller features, we're very excited to work on two big ones in the
short term: **handling ingress traffic** and **adding control over egress
traffic**. These are very common requests from customers who want to extend
Linkerd's comprehensive yet _simple_ layer of traffic control, security, and
visibility to handle traffic in and out of the cluster, and we have some very
exciting ideas for how to deliver this.

Finally, we continue to investigate other ways of delivering Linkerd, including
"ambient" and other approaches. While Linkerd's unique Rust microproxy approach
means it doesn't suffer from the same downsides as Envoy-based service meshes,
we're not religious about our decisions, and continually evaluate the tradeoffs
at hand in the interest of operational simplicity for our customers.

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

Photo by
[redcharlie](https://unsplash.com/@redcharlie?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash)
on
[Unsplash](https://unsplash.com/photos/three-rhinos-walking-on-farm-road-xtvo0ffGKlI?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash)
