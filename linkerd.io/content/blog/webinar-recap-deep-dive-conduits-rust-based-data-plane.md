---
slug: 'webinar-recap-deep-dive-conduits-rust-based-data-plane'
title: 'Webinar recap: A deep dive into Conduit’s Rust-based data plane'
aliases:
  - /2018/02/05/webinar-recap-deep-dive-conduits-rust-based-data-plane/
author: 'courtney'
date: Mon, 05 Feb 2018 19:16:20 +0000
draft: false
featured: false
thumbnail: /uploads/conduit_webinar_recap.png
tags:
  [
    conduit,
    Conduit,
    Linkerd,
    Release Notes,
    rust,
    rustlang,
    service mesh,
    webinar,
    Webinars,
  ]
---

Conduit is now part of Linkerd! [Read more >]({{< relref
"conduit-0-5-and-the-future" >}})

Earlier this month, Conduit core contributors and Rust enthusiasts Carl Lerche and Sean McArthur presented a look at the internals of the new Conduit service mesh, explored its fundamental design choices, and covered our motivations for writing the Conduit data plane in Rust. In case you missed it, we have some of the key takeaways below.

## Why do we need Conduit in a world with Linkerd?

Buoyant sponsors two open source service mesh projects: [Linkerd](https://linkerd.io) and [Conduit](https://conduit.io). Linkerd is a battle tested, production grade, multi-platform, and feature-rich service mesh that is nearly two years mature. Built on components like Scala and the JVM, it's very adept at scaling up for high end performance use cases that can handle tens of thousands of requests per second per host.

While Linkerd is great at scaling up, its fundamental components also prevent it from scaling down. New emergent deployment patterns for microservices mean that they typically operate at significantly smaller scale than what Linkerd is best suited for. In those scenarios, a more appropriate solution is necessary. So in December, we introduced Conduit.

Conduit is a radically new take on the service mesh with a very different fundamental design philosophy. Conduit focuses on being small, ultralight, performant, secure, and simple. It reduces complexity by having very few moving parts and requiring very little configuration. In order to achieve all of those goals, Conduit developers had to make very specific architectural choices like those covered in this webinar.

## Memory safety guarantees with Rust

The proxying layer of a service mesh (aka, the data plane) has very strict performance and safety requirements. It gets injected into the communication layer between all of your services and every single byte that is sent or received over the network gets routed through it. In production environments, protecting sensitive data is a paramount concern as well as as regulatory one (HIPPA, PII, etc). The data plane must be fundamentally secure. At the same time, it’s also critical to limit the performance impact incurred when introducing that additional management layer. You want manageability and security, but not at the cost of performance. When it comes to production-grade performance, what matters most is ensuring*predictable* performance, with very low latency variance.

Modern programming languages either include a runtime (e.g. Go or Java) or they don’t (e.g. C/C++). The use of runtime abstracts a lot of low-level management, but that overhead incurs a significant performance hit that makes it unsuitable for use in the data plane. Foregoing a runtime gets in range of the performance requirements necessary in that layer, but that means taking responsibility for low-level tasks like memory management and introducing new risk by exposure to buffer overflow attack vectors. Historically, this has been the tradeoff every developer faces when choosing between safety and speed.

In order to provide both speed and safety, the Conduit team opted to use [Rust](https://www.rust-lang.org/) to develop the data plane. Rust is a relatively new language that doesn't require a runtime. It guarantees memory safety to prevent buffer overflow attacks while also compiling down to native code to ensure predictable high end performance. In the webinar, we cover the particulars of how Rust makes these guarantees, as well as which Rust components are used in Conduit, what they do, and how you can contribute and get involved.

You don’t need to learn Rust to use Conduit. Simply install and run it like any other piece of software you use. In fact, you probably don’t need to learn Rust to make contributions to Conduit either. While the Conduit data plane is written in Rust, the control plane is written in Go--a language commonly used in microservice management projects. For more specifics on all of these topics and more, check out the webinar below.

{{< youtube ig-I1641Gdk >}}

## More information

If you haven’t already tried [Conduit](http://conduit.io), follow the [getting started](https://conduit.io/getting-started/) guide. Check out the source on [Github](https://github.com/runconduit/conduit) and star the project if you like what we’re doing. If you have questions, come join us on the #conduit channel in the [Linkerd Slack group](http://linkerd.slack.com).
