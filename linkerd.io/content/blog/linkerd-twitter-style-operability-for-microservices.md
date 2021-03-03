---
slug: 'linkerd-twitter-style-operability-for-microservices'
title: 'Linkerd: Twitter-style Operability for Microservices'
aliases:
  - /2016/02/18/linkerd-twitter-style-operability-for-microservices/
author: 'william'
thumbnail: /uploads/linkerd_featured_operability.png
date: Thu, 18 Feb 2016 22:51:16 +0000
draft: false
featured: false
tags: [Buoyant, buoyant, Linkerd, linkerd, News]
---

How do you operate modern, cloud-native applications at scale? What problems arise in practice, and how are they addressed? What is *actually* required to run a cloud-native, microservices-based application under high-volume and unpredictable workloads, without introducing friction to feature releases or product changes?

For all the talk about microservices, it turns out that very few people can actually answer these questions. The rapid rise of exciting new technologies like Docker, Mesos, Kubernetes, and gRPC easily makes armchair architects of us all. But actual high-traffic, production usage? By our reckoning, the number of companies that have actually solved the problems of running microservices at scale is a handful at best.

Twitter is one of those companies. And while it’s certainly had its share of public outages, it operates one of the [highest-scale microservice applications in the world](https://blog.twitter.com/2013/new-tweets-per-second-record-and-how), comprising hundreds of services, tens of thousands of nodes, and millions of RPS per service. Shockingly enough, it turns out that this is [not easy to do](https://www.slideshare.net/InfoQ/decomposing-twitter-adventures-in-serviceoriented-architecture). The problems that arise are [not obvious](https://web.archive.org/web/20181205153929/https://www.somethingsimilar.com/2013/01/14/notes-on-distributed-systems-for-young-bloods/). The failure modes are [surprising](http://roc.cs.berkeley.edu/papers/dsconfig.pdf), [hard to predict](http://web.archive.org/web/20141009231131/http://www.ctlab.org/documents/How%20Complex%20Systems%20Fail.pdf), and sometimes even [hard to describe](https://blog.twitter.com/2012/today-s-turbulence-explained). It can be done, but it takes [years of thought and work](https://monkey.org/~marius/redux.html) to make everything work well in practice.

When Oliver and I left Twitter in the not-too-distant past, our goal was to take these years of operational knowledge and turn them into something that the rest of the world could use. Happily, a tremendous amount of that knowledge was already encoded in an open-source project called [Finagle](http://finagle.github.io/), the high-throughput RPC library that powers Twitter’s microservice architecture.

Finagle is Twitter’s core library for managing the communication between services. Practically every online service at Twitter is built on Finagle, and it powers millions upon millions of RPC calls every second. And it’s not just Twitter—Finagle powers the infrastructure at [Pinterest](https://www.pinterest.com/), [SoundCloud](https://soundcloud.com/), [Strava](https://www.strava.com/), [StumbleUpon](http://www.stumbleupon.com/), and [many other companies](https://github.com/twitter/finagle/blob/master/ADOPTERS.md).

Today, we’re happy to announce a small step towards our vision of making Finagle usable by the masses. **[Linkerd](http://linkerd.io/)** has hit 0.1.0, and we’re open-sourcing it under the [Apache License v2](http://www.apache.org/licenses/LICENSE-2.0).

{{< fig
  alt="logo"
  title="logo"
  src="/uploads/2017/07/buoyant-linkerd-logo.png" >}}

**Linkerd** is our open-source *service mesh* for cloud-native applications. It’s built directly on Finagle, and is designed to give you all the operational benefits of Twitter’s microservice-based, orchestrated architecture—those many lessons learned over many years—in a way that’s self-contained, has minimal dependencies, and can be dropped into existing applications with a minimum of change.

If you’re building a microservice and want to take advantage of the benefits of Finagle—including [intelligent, adaptive load balancing](https://linkerd.io/features/load-balancing/), [abstractions over service discovery](https://linkerd.io/features/service-discovery/), and [intra-service traffic routing](https://linkerd.io/features/routing/)—you can use Linkerd to add these features without having to change your application code. Plus, fancy dashboards!

{{< fig
  alt="linkerd dashboard"
  title="linkerd dashboard"
  src="/uploads/2017/07/buoyant-linkerd-dashboard.png" >}}

Linkerd isn’t complete yet, but in the spirit of “release early and release often”, we think it’s time to get this baby out to the wild.

So if this piques your interest, start with [linkerd.io](https://linkerd.io/) for docs and downloads. And if you’re interested in contributing, head straight to the [Linkerd Github repo](https://github.com/linkerd/linkerd). We’re strong believers in open source—Finagle itself has been open source since almost the beginning—and we’re excited to build a community around this.

We have a long roadmap ahead of us, and a huge list of exciting features we’re looking forward to adding to Linkerd. [Come join us](https://slack.linkerd.io/)!

—[William](https://twitter.com/wm), [Oliver](https://twitter.com/olix0r), and the [whole team at Buoyant](https://buoyant.io/).

(If you’re wondering about the name: we like to think of Linkerd as a “dynamic linker” for cloud-native apps. Just as the dynamic linker in an OS takes the name of a library and a function, and does the work necessary to *invoke* that function, so too Linkerd takes the name of a service and an endpoint, and does the work necessary to make that call happen—safely, securely and reliably. See [Marius’s talk at FinagleCon](https://monkey.org/~marius/redux.html) for more about this model.)
