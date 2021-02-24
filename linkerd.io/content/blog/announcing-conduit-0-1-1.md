---
slug: 'announcing-conduit-0-1-1'
title: 'Announcing Conduit 0.1.1'
aliases:
  - /2017/12/20/announcing-conduit-0-1-1/
author: 'gmiranda23'
date: Wed, 20 Dec 2017 23:11:11 +0000
draft: false
featured: false
thumbnail: /uploads/version_conduit_011.png
tags: [conduit, Conduit, Release Notes, releases]
---

Conduit is now part of Linkerd! [Read more >]({{< relref
"conduit-0-5-and-the-future" >}})

I'm excited to announce that the first inaugural [post-launch release of Conduit](https://github.com/runconduit/conduit/releases/tag/v0.1.1) is now available.

We've been blown away by your feedback and we're working hard to quickly help you with the problems you've told us matter most. This release is focused on making it easier to get started with Conduit and on better supporting your existing applications. In the same way you've come to expect a steady stream of [rapid Linkerd releases](https://github.com/linkerd/linkerd/releases), we're gearing up to also do that for Conduit. Two weeks after launch and we're shipping new features!

With this release, Conduit can now be installed on Kubernetes clusters using RBAC. Conduit can also now support existing gRPC and HTTP/2 applications that communicate with other non-HTTP/2 or non-gRPC services. Use the `--skip-outbound-ports` flag to bypass proxying for specific outbound ports when setting up individual services you want Conduit to manage with the `conduit inject` command.

In addition to new features, several existing features have been enhanced. Output from the `conduit tap` command has been reformatted to make it easier to parse with common UNIX command line utilities. Service calls can now be routed without the use of a fully-qualified domain name, meaning you can make relative lookups like those supported by default in kube-dns. The Conduit console has been updated to better support both large deployments and deployments that don't have any inbound or outbound traffic.

Thanks for all your awesome suggestions and keep them coming! A great way to tell us what you think is by [opening issues via Github](https://github.com/runconduit/conduit) or by joining the [Linkerd Slack group](http://linkerd.slack.com) and popping into #conduit to talk to us directly. Try out the new Conduit for yourself with our [getting started guide](https://conduit.io/getting-started/).
