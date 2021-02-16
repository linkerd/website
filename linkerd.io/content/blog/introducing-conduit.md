---
slug: 'introducing-conduit'
title: 'Introducing Conduit'
aliases:
  - /2017/12/05/introducing-conduit/
author: 'william'
date: Tue, 05 Dec 2017 16:00:44 +0000
draft: false
featured: false
thumbnail: /uploads/conduit_introducing_conduit_featured.png
tags:
  [
    Buoyant,
    buoyant,
    conduit,
    Conduit,
    Industry Perspectives,
    News,
    Release Notes,
  ]
---

Conduit is now part of Linkerd! [Read more >]({{< relref "conduit-0-5-and-the-future" >}})

Today, we’re very happy to introduce [Conduit](http://conduit.io), our new open source service mesh for Kubernetes.

We’ve built Conduit from the ground up to be the fastest, lightest, simplest, and most secure service mesh in the world. It features an incredibly fast and safe data plane written in [Rust](https://www.rust-lang.org/), a simple yet powerful control plane written in [Go](https://golang.org/), and a design that’s focused on performance, security, and _usability_. Most importantly, Conduit incorporates the many lessons we’ve learned from over 18 months of production service mesh experience with [Linkerd](https://linkerd.io).

Why build Conduit? Linkerd is the most widely deployed production service mesh in the world. It introduced the term “service mesh”, spawning a whole new category of software infrastructure, and has powered trillions of production requests across the globe at companies like Salesforce, Paypal, Expedia, AOL, and Monzo. Throughout this time, we’ve been deeply involved with our customers and users—we’ve sat in their meetings, we’ve built joint roadmaps, and we’ve woken up with them at 3am to firefight. We’ve learned an incredible amount about what happens when open source infrastructure meets the real world.

One thing we’ve learned is that there are deployment models where Linkerd’s resource footprint is simply too high. While Linkerd’s building blocks---widely-adopted, production-tested components like Finagle, Netty, Scala, and the JVM---allow Linkerd scale _up_ to incredibly high workloads when given lots of CPU and RAM, they aren’t designed to scale _down_ to environments that have limited resources---in particular, to sidecar-based Kubernetes deployments. So, earlier this year, we asked ourselves: if we could build the ideal service mesh, focused on ultra-low-resource environments, but _with_ the benefit of everything we’ve learned from 18 months of production service mesh experience---what would we build?

The answer is Conduit. Conduit is a next generation service mesh that makes microservices safe and reliable. Just like Linkerd, it does this by transparently managing the runtime communication _between_ services, automatically providing features for observability, reliability, security, and flexibility. And just like Linkerd, it’s deployed as a data plane of lightweight proxies that run alongside application code, and a control plane of highly available controller processes. Unlike Linkerd, however, Conduit is explicitly designed for low resource sidecar deployments in Kubernetes.

## So what makes Conduit so great?

### **Blazingly fast and lightweight**

A single Conduit proxy has a sub-millisecond p99 latency and runs with less than 10mb RSS.

### **Built for security**

From Rust’s memory safety guarantees to TLS by default, we’re focused on making sure Conduit has security in mind from the very beginning.

### **Minimalist**

Conduit’s feature set is designed to be as minimal and as composable as possible, while allowing customization through gRPC plugins.

### **Incredibly powerful**

From built-in aggregated service metrics to a powerful CLI to features like _tap_ (think “tcpdump for microservices”), Conduit gives operators some new and incredibly powerful tools to run microservices in production.

We’ve been hard at work on Conduit for the past 6 months. We’ve hired incredible people like [Phil](http://philcalcado.com/), [Carl](https://github.com/carllerche), [Sean](http://seanmonstar.com), and [Brian](https://briansmith.org). We’ve invested in core technologies like [Tokio](https://github.com/tokio-rs/tokio) and [Tower](http://github.com/tower-rs/tower) that make Conduit extremely fast without sacrificing safety. Most importantly, we’ve designed Conduit to solve real world problems based on all we’ve learned from our Linkerd community.

## What does this mean for Linkerd?

In short, very little. Linkerd is the most widely adopted production service mesh in the world, and it won’t be going anywhere. We’ll continue to develop, maintain, and provide commercial support for Linkerd, and we’re committed to ensuring that our many production Linkerd users remain happy campers.

Conduit is not Linkerd 2.0. Conduit targets a very specific environment—Kubernetes—and does not address any of the wide variety of platforms or integration use cases supported by Linkerd. For our many users of ECS, Consul, Mesos, ZooKeeper, Nomad, Rancher, or hybrid and multi-environment setups spanning these systems, Linkerd is the best service mesh solution for you today, and we’ll continue to invest in making it even better.

## Try it now!

We’ve just released Conduit 0.1. [Try it here](https://conduit.io)! This is an alpha release—so early that it only supports HTTP/2 (i.e. doesn’t even support HTTP/1.1). That said, we wanted to get it out the door so that early adopters and enthusiasts could start experimenting with it, and because we want _your_ input on how to make Conduit work for you.

Over the next few months, we’ll be aggressively working toward making Conduit ready for production, and in 0.2, targeted for early next year, we’ll add support for HTTP/1.1 and TCP. (We've published [the Conduit roadmap here](https://conduit.io/roadmap/)). We’ll be very public in our progress and the goals we’re setting for the project. Finally, we’ll also offer commercial support for Conduit—if this interests you, please [reach out to us](mailto:hello@buoyant.io) directly.

Want to learn more? Subscribe to the release announcements mailing list, join us in [the #Conduit channel in Linkerd Slack](http://slack.linkerd.io), follow [@runconduit](https://twitter.com/runconduit) on Twitter for updates and news, or find us on [GitHub](https://github.com/runconduit).

Conduit is open source and licensed under Apache 2.0.

(And, of course, we’re hiring! If you think Conduit and Linkerd are the coolest things since time-sliced multitasking, [take a gander at our careers page](http://buoyant.io/careers) and drop us a note!)
