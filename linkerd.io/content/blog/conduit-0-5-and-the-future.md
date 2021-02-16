---
slug: 'conduit-0-5-and-the-future'
title: 'Conduit 0.5.0 and the future of Conduit'
aliases:
  - /2018/07/06/conduit-0-5-and-the-future/
author: 'oliver'
date: Fri, 06 Jul 2018 16:41:57 +0000
thumbnail: /uploads/a6d4b0bd-conduit.jpg
draft: false
featured: false
tags: [Conduit, Linkerd, News]
---

Today we're very happy to announce [Conduit 0.5.0](https://github.com/runconduit/conduit/releases/tag/v0.5.0), which introduces _zero-config_ automatic TLS between mesh'd pods (including certificate creation and distribution). This means that most Kubernetes users can now encrypt internal HTTP communication between their service in just two simple commands.

We're also happy to announce that 0.5.0 will be the last major release of Conduit. Conduit is [graduating into the Linkerd project](https://github.com/linkerd/linkerd/issues/2018) to become the basis of [Linkerd](http://linkerd.io) 2.0. Read on for what this means!

## Conduit 0.5.0: TLS for free

We've been working hard on Conduit 0.5.0 for the past few months. This release introduces several oft-requested features, including support for [HTTP protocol upgrades](https://developer.mozilla.org/en-US/docs/Web/HTTP/Protocol_upgrade_mechanism) (Conduit now supports WebSockets!) and HTTP CONNECT streams. Most importantly, it introduces a new feature that enables TLS between Conduit proxies, allowing them to automatically encrypt application traffic.

This new automatic TLS support is a major step towards Conduit's goal of providing reliability and security to Kubernetes applications "for free". While it's gated behind an experimental flag in this release, we'll be working hard to de-experimentify it in the near future, as well as extend its scope and capabilities. You can read more about Conduit's TLS design and upcoming plans in the [Conduit Automatic TLS documentation](https://conduit.io/automatic-tls/).

## Conduit is merging with Linkerd

Conduit 0.5.0 will be the last major release of Conduit. We’re happy to announce that Conduit is graduating into the Linkerd project to become the basis of Linkerd 2.0. Over the next few weeks, you’ll start to see some changes in the Conduit and Linkerd projects in order to prepare for this change.

Why merge Conduit into Linkerd? When we launched Conduit in December 2017, our hypothesis was that we could build a dramatically simpler solution to the problems that we've spent the last several years helping Linkerd users tackle: monitoring, reliability, and security of their cloud native applications. Furthermore, we were pretty sure that we could do this using only a small fraction of the system resources that Linkerd requires. But this was a risky move, and it didn't feel right to our many Linkerd production users to call it "Linkerd" until we were sure it would be successful.

Happily, after seven months of [iterating](https://blog.buoyant.io/2018/05/17/prometheus-the-right-way-lessons-learned-evolving-conduits-prometheus-integration/) on Conduit, it’s clear to us that Conduit is worthy of bearing the Linkerd name. Conduit's lightning-fast Rust proxies are ~10mb per instance, have sub-millisecond p99 latencies, and support HTTP/1.x, HTTP/2, and gRPC. Conduit can be installed in seconds on almost any Kubernetes cluster and applied incrementally to just the services you're interested in. [Conduit's telemetry support is best in class](https://blog.conduit.io/2018/04/20/conduit-0-4-0-wheres-my-traffic/) and, like TLS, comes "for free" without requiring any application changes. Most importantly, the [community around Conduit](https://github.com/runconduit/conduit/graphs/contributors) has dramatically ramped up over the past few months, with contributors, production users, and, of course, [lots of GitHub stars](http://www.timqian.com/star-history/#runconduit/conduit&linkerd/linkerd)!

Over the coming weeks, [github.com/runconduit/conduit](https://github.com/runconduit/conduit) will be moved to [github.com/linkerd/linkerd2](https://github.com/linkerd/linkerd2); and the proxy component will be split into its own repo at [github.com/linkerd/linkerd2-proxy](https://github.com/linkerd/linkerd2-proxy). Once this change is made, we’ll stop publishing docker images to [gcr.io/runconduit](https://gcr.io/runconduit) and start publishing images to [gcr.io/linkerd-io](https://gcr.io/linkerd-io). After the merge, both Linkerd 1.x and 2.x lines will continue to be developed in parallel. Linkerd (both versions) will, of course, continue to be a CNCF member project. And we’ll be working hard on the next step: a Linkerd 2.0 GA release.

There's a lot more we want to say about our plans for Linkerd 2.0, so please stay tuned. On behalf of both the Conduit and Linkerd maintainers, we’re incredibly excited about what this means for the future of Linkerd and the service mesh. Please drop into Linkerd [GitHub](https://github.com/linkerd/linkerd/issues/2018), [Slack](http://slack.linkerd.io) or [mailing list](https://groups.google.com/forum/#!forum/linkerd-users) with any feedback, questions, or concerns. This is a great time to get involved!
