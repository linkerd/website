---
slug: 'announcing-conduit-0-3-conduit-roadmap'
title: 'Announcing Conduit 0.3 and the Conduit Roadmap'
author: 'william'
date: Wed, 21 Feb 2018 20:47:41 +0000
draft: false
featured: false
thumbnail: /uploads/version_conduit_030.png
tags: [conduit, Conduit, News, Release Notes]
---

Conduit is now part of Linkerd! [Read more >]({{< ref
"conduit-0-5-and-the-future" >}})

Today we’re very happy to announce the release of Conduit 0.3! With this release, Conduit moves from _experimental_ to _alpha_---meaning that we’re ready for some serious testing and vetting from you. [Full release notes are here](https://github.com/runconduit/conduit/releases/tag/v0.3.0).

Conduit 0.3 focuses heavily on production hardening of Conduit’s telemetry system, which automatically measures and aggregates service-level success rates, latency distributions, and request volumes. Conduit should “just work” for most apps on Kubernetes 1.8 or 1.9 without configuration, and should support Kubernetes clusters with hundreds of services, thousands of instances, and hundreds of RPS per instance. Conduit publishes top-line metrics for most HTTP/1.x and gRPC services without any configuration, and if you have your own Prometheus cluster, you can now also [export those metrics](https://conduit.io/prometheus) to it directly.

Conduit 0.3 also features _load aware_ request-level load balancing, by which Conduit automatically sends requests to service instances with the fewest pending requests. This should improve application performance compared to the default layer 4 load balancing in Kubernetes, especially for applications under load.

Most importantly, as of 0.3, we’re opening up Conduit development and planning. We’ve published the much-requested [Conduit roadmap](https://conduit.io/roadmap/), and we’re tracking upcoming [issues and milestones](https://github.com/runconduit/conduit/milestones) in GitHub. We’ve also launched new mailing lists: [conduit-users](https://groups.google.com/forum/#!forum/conduit-users), [conduit-dev](https://groups.google.com/forum/#!forum/conduit-dev), and [conduit-announce](https://groups.google.com/forum/#!forum/conduit-announce), which we’ll be using to plan and coordinate Conduit development.

We hope these changes will make it even easier to get involved. If you want to participate, please subscribe to the mailing lists above, get familiar with the [Conduit README](https://github.com/runconduit/conduit/blob/master/README.md), and check out the [GitHub issues marked “help wanted”](https://github.com/runconduit/conduit/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22)!

Finally, while Conduit is now in alpha, we don’t expect it to stay that way for long. We’re making a concerted effort to make Conduit production-ready as rapidly as possible. Of course, this all depends on you. [Try Conduit](https://conduit.io/) on your own Kubernetes apps, give us feedback, and help us get there!
