---
title: 'The roadmap for Linkerd2-proxy'
author: 'oliver'
date: 2020-08-01T00:00:00+00:00
thumbnail: /uploads/amit-jain-pQ04riRO9wM-unsplash.jpg
draft: false
tags: [Linkerd]
---

![A long winding road](/uploads/amit-jain-pQ04riRO9wM-unsplash.jpg)

The past few months have seen a continued interest in Linkerd's data plane
"micro-proxy", Linkerd2-proxy. Last month, William Morgan wrote about some of
the[ decisions that went into building a service-mesh-specific proxy in
Rust](https://thenewstack.io/linkerds-little-secret-a-lightning-fast-service-mesh-focused-rust-network-proxy/).
Linkerd maintainer Eliza Weisman then followed up with [a deep dive into
Linkerd2-proxy](https://linkerd.io/2020/07/23/under-the-hood-of-linkerds-state-of-the-art-rust-proxy-linkerd2-proxy/)
and how it handles requests. In this article, I want to look into the future:
what does the roadmap have in store for Linkerd2-proxy?


## Linkerd's secret sauce: a small, speedy, simple micro-proxy 

Building a modern, high-performance Rust network proxy has not been a trivial
undertaking. Especially in the early years, investing in the proxy often meant
spending more time working on the core Rust networking libraries than on the
proxy itself! But we knew that this would be critical to our service mesh
approach: because the data plane scales directly with the application, a
service mesh can _only_ be small and fast if the underlying data plane itself
is small and fast.

Happily, those early investments have paid off. As William wrote in his
article:

> I believe that Linkerd2-proxy represents the state of the art for secure,
modern network programming. It is fully asynchronous and written in a modern
type-safe and memory-safe language. It makes full use of the modern Rust
networking ecosystem, sharing foundations with projects such as Amazon’s
Firecracker. It has native support for modern network protocols such as gRPC,
can load balance requests based on real-time latency, and do protocol detection
for zero-config use. It is fully open source, audited, and widely tested at
scale.

Of course, Linkerd isn't just known for performance and resource usage, it's
known for its _simplicity_. Here, again, Linkerd2-proxy is critical to
Linkerd's approach: because Linkerd2-proxy is designed explicitly for the
sidecar service mesh use case, it's dramatically simpler to operate than a
general-purpose proxy such as NGINX and Envoy. Shedding all the varied
non-service-mesh use cases gives the leeway to design Linkerd2-proxy to "just
work" for the majority of service mesh users without tuning or tweaking,
through features like [protocol
detection](https://linkerd.io/2/features/protocol-detection/) and
[Kubernetes-native service
discovery](https://linkerd.io/2/features/load-balancing/).  In fact,
Linkerd-proxy doesn't even have a config file.

## The future of the Linkerd2-proxy

Today, Linkerd-proxy is fast, simple, and small, and powers the critical
production architecture of organizations around the world. So what's next?

There are a couple notable exciting future features on the docket for
Linkerd2-proxy, ranging from the concrete and near-term to the speculative and
far out, and from the small and well-contained to the big and hairy. This
includes:

1. **mTLS for all TCP connections.** This is a big one. Today, the proxy can
automatically initiate and terminate mutually-authenticated TLS connections,
but only for HTTP/gRPC traffic. Work is already underway to extend this to
non-HTTP protocols, so that they have the same guarantees of workload identity
and confidentiality that Linkerd provides (automatically!) today. As an added
bonus, this feature will also extend Linkerd's [seamless multi-cluster
capabilities](https://linkerd.io/2/features/multicluster/) to non-HTTP traffic. 
2. **Revisiting latency bucketing**. As part of its instrumentation,
Linkerd2-proxy records the latency of all traffic that passes through it and
reports these values in a set of fixed buckets, with a specific latency range
(e.g. 5ms-10ms) per bucket. These bucket windows are fixed and frankly somewhat
arbitrarily-chosen at the moment. Our sense is that this could be improved, but
any kind of dynamic sizing would require coordination between proxies so that
the resulting buckets can be aggregated.
3. **HTTP/3 / QUIC** between proxies. HTTP/2 provides some major benefits over
HTTP/1.x for high-concurrency communication between services, and today,
Linkerd2-proxy already transparently upgrades HTTP/1.1 communication to HTTP/2
when it happens in between proxies. HTTP/3 promises some further benefits in
this direction, and we're eager to extend Linkerd2-proxy to support HTTP/3.
4. **Web assembly plugins.** Today, there's no immediate way of supporting
plugins in the data plane, e.g. to allow for customized routing based on
user-specific headers. We’re exploring proxy WebAssembly (Wasm) as a way to
accomplish this and allow Linkerd to make use of a broad range of
language-agnostic traffic plugins.
5. **Off-cluster support.** While the proxy _can_ run outside of Kubernetes,
there is no packaging that makes this easy, and there several open questions
about how things like mTLS identity should be treated. Nonetheless, apparently
not all software runs on Kubernetes, and we'd like to better support that in
Linkerd.

## Linkerd's design principles 

However we design these features, they will be guided by Linkerd's three
[design principles](https://linkerd.io/2019/04/29/linkerd-design-principles/):

1. **Keep it simple**. Linkerd should be operationally simple with low
cognitive overhead. Operators should find its components clear and its behavior
understandable and predictable, with a minimum of magic.
2. **Minimize resource requirements**. Linkerd should impose as minimal a
performance and resource cost as possible–especially at the data plane layer.
3. **Just work**. Linkerd should not break existing applications, nor should it
require complex configuration to get started or to do something simple.

For proxy work especially, we might add a fourth principle: **Be secure.** At a
minimum, don't decrease the overall security of the system; ideally,
increase it. Security is a primary focus for Linkerd and nowhere is that more
relevant than in the data plane layer, where our users' sensitive data
traverses. Our choice of Rust was in part due to Rust's security-related
guarantees; we need to continue delivering on Linkerd's reputation for security
no matter what.

If any of that sounds interesting to you, get involved in Linkerd! Hop into the
[Linkerd slack](https://slack.linkerd.io), join our monthly [Linkerd Online
Community Meetups](https://www.meetup.com/Linkerd-Online-Community-Meetup/),
and check out our [RFC
process](https://linkerd.io/2020/04/08/introducing-linkerds-rfc-process/) for
the project. Linkerd has a friendly and welcoming community, and we'd love to
have you join us!

## Try it today!

Ready to try Linkerd? Those of you who have been tracking the 2.x branch via our
[weekly edge releases](https://linkerd.io/2/edge) will already have seen these
features in action. Either way, you can download the stable 2.8 release by
running:

```bash
curl https://run.linkerd.io/install | sh
```

Using Helm? See our
[guide to installing Linkerd with Helm](https://linkerd.io/2/tasks/install-helm/).
Upgrading from a previous release? We've got you covered: see our
[Linkerd upgrade guide](https://linkerd.io/2/tasks/upgrade/) for how to use the
linkerd upgrade command.

## Linkerd is for everyone

Linkerd is a community project and is hosted by the
[Cloud Native Computing Foundation](https://cncf.io/). Linkerd is
[committed to open governance.](https://linkerd.io/2019/10/03/linkerds-commitment-to-open-governance/)
If you have feature requests, questions, or comments, we'd love to have you join
our rapidly-growing community! Linkerd is hosted on
[GitHub](https://github.com/linkerd/), and we have a thriving community on
[Slack](https://slack.linkerd.io/), [Twitter](https://twitter.com/linkerd), and
the [mailing lists](https://linkerd.io/2/get-involved/). Come and join the fun!

<i>Image credit: <span>Photo by <a href="https://unsplash.com/@amitjain0106?utm_source=unsplash&amp;utm_medium=referral&amp;utm_content=creditCopyText">Amit Jain</a> on <a href="https://unsplash.com/s/photos/roadmap?utm_source=unsplash&amp;utm_medium=referral&amp;utm_content=creditCopyText">Unsplash</a></span></i>
