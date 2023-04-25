---
slug: 'linkerd-0-8-4-released'
title: 'Linkerd 0.8.4 released'
aliases:
  - /2016/12/07/linkerd-0-8-4-released/
author: 'william'
date: Wed, 07 Dec 2016 00:11:05 +0000
draft: false
featured: false
thumbnail: /uploads/linkerd_version_084_featured.png
tags: [Linkerd, linkerd, News, Product Announcement]
---

We’re happy to announce that we’ve released [linkerd 0.8.4](http://github.com/linkerd/linkerd/releases/tag/0.8.4)! With this release, two important notes. First, Kubernetes and Consul support are now officially production-grade features—high time coming, since they’re actually already used widely in production. Second, this release features some significant improvements to Linkerd’s HTTP/2 and gRPC support, especially around backpressure and request cancellation.

## KUBERNETES AND CONSUL NAMERS NO LONGER EXPERIMENTAL

Here at the Buoyant code mines, we tend to be pretty conservative about marking features as “production ready”. Both Kubernetes and Consul namers have had the `experimental` flag since they were introduced to Linkerd many months ago.

However, since these namers are being used extensively in production by companies and organizations such as [Olark](http://olark.com/), [Monzo](http://monzo.com/), and [NCBI](https://www.ncbi.nlm.nih.gov/), and are free of known bugs and performance issues, it’s time to remove the experimental flag from those namers.

So, as of Linkerd 0.8.4, Linkerd’s Kubernetes support and Consul support are both officially production-grade.

## IMPROVED HTTP/2 AND GRPC SUPPORT

Over the past few releases, [Oliver](https://twitter.com/olix0r) has been working hard on improving Linkerd’s HTTP/2 support. Since Linkerd doesn’t parse the request body, HTTP/2 support also gives us [gRPC support](https://linkerd.io/features/grpc/).

In 0.8.4, we started testing Linkerd against known-good gRPC clients and servers, including non-Go implementations. As a result of this testing, Linkerd 0.8.4 includes much improved support for HTTP/2 and gRPC, especially around HTTP/2’s backpressure and request cancellation features.

For now, HTTP/2 and gRPC support remain behind the experimental flag. However, production-ready HTTP/2 and gRPC support are on our short term roadmap, and you should expect to see these features continue to improve over the next few releases.

We hope you enjoy this release. For more about HTTP/2 or gRPC with Linkerd, feel free to stop by our [Linkerd community Slack](http://slack.linkerd.io/), ask a question on the [Linkerd Support Forum](https://linkerd.buoyant.io/), or [contact us directly](https://linkerd.io/overview/help/).

—William and the gang at [Buoyant](https://buoyant.io/)
