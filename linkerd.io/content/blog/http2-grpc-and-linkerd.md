---
slug: 'http2-grpc-and-linkerd'
title: 'HTTP/2, gRPC and Linkerd'
author: 'oliver'
date: Wed, 11 Jan 2017 00:16:09 +0000
draft: false
featured: false
thumbnail: /uploads/linkerd_GRPC_featured.png
tags: [linkerd, News, Product Announcement]
---

In March 2016 at Kubecon EU, I gave my my [first public talk on Linkerd](https://www.youtube.com/watch?v=co7JRxihcdA). At the end of this talk, like most of the other 20+ talks I gave in 2016, I presented a high-level Linkerd [roadmap](https://speakerdeck.com/olix0r/kubernetes-meets-finagle-for-resilient-microservices?slide=34) that aspirationally included HTTP/2 & gRPC integration. As we enter 2017, I’m pleased to say that we’ve reached this initial goal. Let me take this opportunity to summarize what I think is novel about these technologies and how they relate to the future of Linkerd service meshes.

## WHAT’S THE BIG DEAL?

### H2: WHY A NEW PROTOCOL?

The HTTP protocol and its simple enveloped-request-and-response model underlie all communication on the Web. While innumerable schemes have been devised on top of HTTP, the fundamental protocol had changed very little since its inception.

After HTTP/1.0 was standardized in May 1996, implementers soon realized that it was impractically wasteful and s…l…o…w to establish a new connection for each request; and so the HTTP/1.1 protocol revision was standardized in January 1997. The revised protocol allowed browsers to reuse a connection to service multiple requests.

This simple communication scheme withstood an additional 15 years of usage with basically no change. However, in 2012, a group of Large Website operations and browser performance experts started to confront the limitations of HTTP/1.1. This resulted in a overhaul of the HTTP protocol: HTTP/2 (or just *h2*).

Unfortunately, the enhancements introduced in HTTP/1.1 were not enough to meet the performance requirements of modern applications:

1. In HTTP/1.1, requests are processed *sequentially*. This means that a single slow request may add latency to unrelated requests.
2. HTTP/1.1 has rudimentary support for streaming message bodies via the *chunked* transfer encoding, but streams consume an entire connection, and connections ain’t free.
3. And when the receiver of a stream wants to inform the producer that it doesn’t care to receive data, its only options are to stop calling `read(2)` to exert back-pressure, or it can `close(2)` and re-establish the entire connection before sending additional requests (which, as I’ve said, is costly).

Need convincing? Look at this trivial example that compares how [HTTP/1.1](http://http2.golang.org/gophertiles?latency=1000) and [HTTP/2](https://http2.golang.org/gophertiles?latency=1000) behave when communicating with a slow endpoint.

HTTP/2’s primary innovation is that it explicitly separates the (Layer-4) concerns of *connection management* from the (Layer-5) concerns of transmitting HTTP messages. Messages can be multiplexed, reordered, and canceled, eliminating bottlenecks and generally improving performance and reliability of the application at large.

### GRPC

Virtually all modern programming environments include a small arsenal for communicating over HTTP; and yet, it’s still far from trivial to begin programming against a new HTTP API in an arbitrary language. HTTP is simply a session protocol and it does virtually nothing to prescribe how applications are written to use it.

Enter the IDL. *Interface Definition Languages* allows service owners to specify their APIs independently of any given programming language or implementation. Interface definitions are typically used to *generate* communication code for a variety of programming environments, freeing programmers from the subtleties of encoding and transmission. While there are a [multitude of IDLs](https://en.wikipedia.org/wiki/Interface_description_language), [Google Protocol Buffers](https://developers.google.com/protocol-buffers/) (or*protobuf*) and [Apache Thrift](https://thrift.apache.org/) were championed by early microservice adopters like Google, Facebook, & Twitter. More recently the microservice movement, propelled by technologies like Docker, Kubernetes, and Mesos, has amplified the need for tools that simplify service-to-service communication.

In early 2015, [Google announced gRPC](https://developers.googleblog.com/2015/02/introducing-grpc-new-open-source-http2.html), a “universal RPC framework” which combines the ubiquitous foundation of HTTP with the performance gains of HTTP/2 and the portable interfaces of protobuf. It is novel in that:

- it transmit metadata through HTTP envelopes, allowing orthogonal features to be layered in (like authentication, distributed tracing, deadlines, and routing proxies ;),
- it provides operational affordances like multiplexed streaming, back-pressure, & cancellation,
- it will be available everywhere HTTP/2 is (like web browsers),
- and it abstracts the details of communication from application code (unlike REST).

gRPC takes a modular approach in the way that it layers the best features of IDL-specified RPC onto a standard, performant protocol, hopefully finally disabusing people of the notion that HTTP and RPC are different models.

## H2, GRPC, AND LINKERD

While Linkerd’s protocols are pluggable, support was initially limited to HTTP/1.1 and Thrift service meshes. For all of the reasons outlined above, we believe that gRPC is the future; so we set our sights on extending Linkerd to serve as a router for gRPC.

In March 2016, we began to [assess](https://github.com/linkerd/linkerd/issues/174) what this would take. We knew that Netty had a fairly stable, well-tested HTTP/2 implementation, and, by early May, Finagle had undergone the necessary refactoring to support HTTP/2 integration. It’s around this time that [Moses Nakamura](https://github.com/mosesn) started working on the [finagle-http2 subproject](https://github.com/twitter/finagle/tree/develop/finagle-http2). I spent some time testing this for our needs, but ultimately I decided that finagle-http2 was not an expedient path to gRPC support in Linkerd: it intended to sacrifice feature completeness for API compatibility (a totally reasonable tradeoff to make for the finagle project, but insufficient for our needs in Linkerd).

After several months writing, testing, and rewriting h2 support in Linkerd, the [0.8.2 release](https://github.com/linkerd/linkerd/releases/tag/0.8.2) introduced the ability to route HTTP/2 and gRPC messages. With help from Linkerd users around the world, each Linkerd release is improving the stability and performance of our h2 codec. There’s still [more work to do](https://github.com/linkerd/linkerd/issues?q=is%3Aissue+is%3Aopen+label%3Ah2), but we’re well on our way.

To that end, I’m also happy to announce that Linkerd’s [0.8.5 release](https://github.com/linkerd/linkerd/releases/tag/0.8.5) introduces support for [gRPC code generation in the Linkerd project](https://github.com/linkerd/linkerd/tree/master/grpc). This will make it possible to, for instance, consume gRPC APIs from Linkerd plugins. Furthermore, we plan on introducing a [gRPC API for namerd](https://github.com/linkerd/linkerd/issues/842) so that you can write namerd clients in any language.

### GOALS FOR 2017

We’ll be investing heavily in the HTTP/2 & gRPC ecosystem in Linkerd in 2017:

#### Graduate from `experimental`

Currently, the *h2* Linkerd router protocol is marked as *experimental*. Once we’ve completed a broader set of compatibility tests, and ideally once there are a few other serious users of Linkerd’s h2 protocol, we’ll [remove the `experimental` flag](https://github.com/linkerd/linkerd/issues/854).

#### Support HTTP/1.1->HTTP/2 upgrade

Currently, a Linkerd router may be configured to accept *either* HTTP/1 *or* HTTP/2 messages. However, Linkerd should be able to [upgrade HTTP/1 messages to HTTP/2](https://github.com/linkerd/linkerd/issues/841), without the application’s participation. This will allow Linkerd to be much more efficient in terms of how it manages inter-node connections.

#### gRPC control plane

After months of use, we’re eager to [replace Namerd’s Thrift API with gRPC](https://github.com/linkerd/linkerd/issues/842). If we’re happy with this, I’d like to create additional gRPC APIs for plugins so you can write controllers for Linkerd in any language.

I am frequently asked how Linkerd configuration should be updated at runtime. In short, I don’t think Linkerd’s *configuration* should have to be updated all that often. If it changes frequently, it’s not configuration; it’s data and deserves its own service abstraction. gRPC will help make my idealized view of the world a practical reality. I can’t wait.

## IN SUMMARY…

I’m thrilled that Linkerd is embracing foundational technologies of the future like HTTP/2 and gRPC.

This was challenging work, but we’re fortunate to be building on an outstanding framework (and community!) provided by [Finagle](http://finagle.github.io/) & [Netty](http://netty.io/). We’re also lucky that the Linkerd community is full of thoughtful users who are eager to test new features and provide feedback. Thanks especially to [@mosesn](https://github.com/mosesn) and the Finagle team, [@normanmaurer](https://github.com/normanmaurer) and the Netty team, and to Linkerd users like [@irachex](https://github.com/irachex), [@markeijsermans](https://github.com/markeijsermans), [@moderation](https://github.com/moderation), [@pinak](https://github.com/pinak), [@stvndall](https://github.com/stvndall), [@zackangelo](https://github.com/zackangelo) (and anyone else) who gave us early feedback.

And our work isn’t finished. We need your help [testing *h2*](https://linkerd.io/config/0.8.5/linkerd/index.html#http-2-protocol). Also, let me take this opportunity to invite you to [contribute to Linkerd on Github](https://github.com/linkerd/linkerd/labels/help%20wanted). At the very least, you should feel free to [join us on Slack](https://slack.linkerd.io/)!
