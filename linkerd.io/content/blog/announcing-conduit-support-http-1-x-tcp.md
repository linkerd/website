---
slug: 'announcing-conduit-support-http-1-x-tcp'
title: 'Announcing Conduit support for HTTP/1.x and TCP'
aliases:
  - /2018/02/01/announcing-conduit-support-http-1-x-tcp/
author: 'gmiranda23'
date: Thu, 01 Feb 2018 16:29:10 +0000
draft: false
featured: false
thumbnail: /uploads/version_conduit_020.png
tags: [conduit, Conduit, HTTP/1, News, Release Notes, TCP]
---

Conduit is now part of Linkerd! [Read more >]({{< relref
"conduit-0-5-and-the-future" >}})

We’re happy to announce that the latest Conduit release delivers on a big project milestone. With the 0.2.0 release, Conduit now includes support for HTTP/1.x and TCP traffic in addition to the existing HTTP/2 support. That means Conduit can now support most of your Kubernetes applications right out of the box.

One of the things we’re most excited about in this release is the continued progress we’re making on simplifying the process of getting started with a service mesh. Conduit focuses on minimizing the level of effort needed to make a service mesh operable by aiming for a “zero config” approach to management. In other words, you shouldn’t have to get bogged down in configuration options just to get the basic visibility, management, and control you need.

In the 0.2.0 release, you’ll notice that Conduit isn’t entirely zero config yet, but we’re getting pretty close. Some services still need manual configuration for now. Notably, if you’re using WebSockets or a protocol where the server sends traffic prior to the client (e.g. non-TLS encrypted MySQL or SMTP connections), you still need to manage those exceptions with some config. You can find more details in the [release notes](https://github.com/runconduit/conduit/releases/tag/v0.2.0).

Conduit is still in alpha, so there’s a lot of work to be done before it’s ready for production workloads. But the development pace for Conduit is exceeding our expectations and we have even better things for you around the corner in the upcoming 0.3 milestone. Stay tuned for announcements on what to expect as Conduit heads down the road to production.

[Try it for yourself](https://conduit.io/getting-started/) and let us know what you think! Join us in the #conduit channel in the [Linkerd Slack group](http://linkerd.slack.com) to chat with us directly. Keep the feedback coming! We’re thrilled with the response to Conduit so far and we’re excited to keep up with your suggestions.
