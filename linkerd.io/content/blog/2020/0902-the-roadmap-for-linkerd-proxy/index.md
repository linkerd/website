---
date: 2020-09-02T00:00:00-08:00
slug: the-road-ahead-for-linkerd2-proxy
title: The road ahead for Linkerd2-proxy, and how you can get involved
keywords: [linkerd]
params:
  author: oliver
  showCover: true
---

The past few months have seen a continued interest in Linkerd's data plane
"micro-proxy", [Linkerd2-proxy](https://github.com/linkerd/linkerd2-proxy).
Last month, William Morgan wrote about some of the [decisions that first went
into building a service-mesh-specific proxy in
Rust](https://thenewstack.io/linkerds-little-secret-a-lightning-fast-service-mesh-focused-rust-network-proxy/).
Eliza Weisman then followed up with [a deep dive into
Linkerd2-proxy](/2020/07/23/under-the-hood-of-linkerds-state-of-the-art-rust-proxy-linkerd2-proxy/)
and how it handles requests. In this article, I want to look into the future:
what do the upcoming months and years have in store for Linkerd's proxy? And
how can you get involved?

## Linkerd's secret sauce: a small, speedy, simple micro-proxy

Building a modern, high-performance Rust network proxy has not been a trivial
undertaking. Especially in the early years, investing in the proxy often meant
spending more time working on the core Rust networking libraries than on the
proxy itself! But we knew that this would be critical to our service mesh
approach: because the data plane scales directly with the application, a
service mesh can _only_ be small and fast if the underlying data plane itself
is small and fast.

Happily, those early investments have paid off. As William wrote:

> I believe that Linkerd2-proxy represents the **state of the art** for secure,
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
sidecar service mesh use case, it's dramatically simpler to operate than
general-purpose proxies such as NGINX and Envoy. This is not a knock on those
proxies; it's simply a reflection that by shedding all the non-service-mesh use
cases, Linkerd2-proxy gains the leeway to "just work" without tuning or
tweaking, through features like [protocol
detection](/2/features/protocol-detection/) and
[Kubernetes-native service
discovery](/2/features/load-balancing/). In fact, at this
point Linkerd-proxy doesn't even have a config file.

## The future of the Linkerd2-proxy

Today, Linkerd-proxy is fast, simple, and small, and powers the critical
production architecture of organizations around the world. So what's next?

There are a couple notable exciting future features on the docket, ranging from
the concrete and near-term to the speculative and far out, and from the small
and well-contained to the big and hairy. These include:

1. **mTLS for all TCP connections.** This is a big one. Today, the proxy can
automatically initiate and terminate mutually-authenticated TLS connections
without any configuration, but only for HTTP/gRPC traffic. We're already
working on extend this to non-HTTP protocols, so that they have the same
guarantees of workload identity and confidentiality that Linkerd provides for
HTTP traffic today. As an added bonus, this feature will also extend Linkerd's
[seamless multi-cluster
capabilities](/2/features/multicluster/) to non-HTTP traffic.
2. **Revisiting latency bucketing**. As part of its instrumentation,
Linkerd2-proxy records the latency of all traffic that passes through it and
reports these values in a set of fixed buckets, with a specific latency range
(e.g. 5ms-10ms) per bucket. These bucket windows are fixed and frankly somewhat
arbitrarily-chosen at the moment. We'd like to improve this, but any kind of
dynamic sizing would probably require coordination between proxies so that the
resulting buckets can be aggregated.
3. **HTTP/3 / QUIC** between proxies. HTTP/2 provides some major benefits over
HTTP/1.x for high-concurrency communication between services, and today,
Linkerd2-proxy already transparently upgrades HTTP/1.1 communication to HTTP/2
when it happens in between proxies. HTTP/3 promises further benefits in
this direction, and we're eager to extend Linkerd2-proxy to support HTTP/3.
4. **Web assembly plugins.** Today, there's no immediate way of supporting
plugins in the data plane, e.g. to allow for customized routing based on
user-specific headers. We’re exploring proxy WebAssembly (Wasm) as a way to
accomplish this and allow Linkerd to make use of a broad range of
language-agnostic traffic plugins. There may even be a way to use the same
plugins developed for Envoy, which could open up some very interesting
possibilities.
5. **Off-cluster support.** While the proxy _can_ run outside of Kubernetes
(it's just a binary, after all), there is no packaging today that makes this
easy to do, and there several open questions about how things like mTLS
identity should be treated. Nonetheless, it has come to our attention that
apparently not all software in the universe runs on Kubernetes, and we'd like
to better support that in Linkerd.

Some of those features, like mTLS for TCP, are well-scoped and work is already
underway. Others, like HTTP/3, are still in idea phase. But they're all
strategic and important for the proxy.

## How can I get involved?

If any of those features sound interesting, or if the thought of working on a
state-of-the-art open source Rust networking project that powers production
systems around the world is exciting, then the good news is that you can
get involved! Linkerd2-proxy is fully open source, open governance, and hosted
by the Cloud Native Computing Foundation, and we're always interested in
welcoming more folks to the project.

If you're new to Linkerd, the best way to get started is:

1. Join the [Linkerd slack](https://slack.linkerd.io), especially the
`#contributors` channel, and say hi!
2. Attend the next monthly [Linkerd Online Community
Meetup](https://www.meetup.com/Linkerd-Online-Community-Meetup/);
3. Peruse the [open
proxy issues](https://github.com/linkerd/linkerd2/issues?q=is%3Aopen+is%3Aissue+label%3Aarea%2Fproxy),
especially those marked "good first issue"; and
4. Familiarize yourself with our [RFC
process](/2020/04/08/introducing-linkerds-rfc-process/) for
introducing bigger changes to the project.

If you're new to Rust especially, you might also want to take a look at the
[live proxy code walkthroughs](https://www.youtube.com/watch?v=wRZE7JlsnpA)
that Eliza has been running.

All the fame and glory of open source Rust maintainership awaits you. Join us
and let's build this amazing proxy together.

## Try it today!

Want to see the proxy in action? You can try Linkerd on any relatively modern
Kubernetes cluster in a matter of minutes. Download the latest stable release
by running:

```bash
curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install | sh
```

You can be up and running with a functioning service mesh (and an awesome Rust
proxy) in a matter of minutes.

## Linkerd is for everyone

Linkerd is a community project and is hosted by the [Cloud Native Computing
Foundation](https://cncf.io/). Linkerd is [committed to open
governance.](/2019/10/03/linkerds-commitment-to-open-governance/)
If you have feature requests, questions, or comments, we'd love to have you
join our rapidly-growing community! Linkerd is hosted on
[GitHub](https://github.com/linkerd/), and we have a thriving community on
[Slack](https://slack.linkerd.io/), [Twitter](https://twitter.com/linkerd), and
the [mailing lists](/community/get-involved/). Come and join the fun!

Image credit: Photo by [Amit Jain](https://unsplash.com/@amitjain0106?utm_source=unsplash&amp;utm_medium=referral&amp;utm_content=creditCopyText) on [Unsplash](https://unsplash.com/s/photos/roadmap?utm_source=unsplash&amp;utm_medium=referral&amp;utm_content=creditCopyText)
