---
slug: 'linkerd-1-3-3-announcement-community-spotlight'
title: 'Linkerd 1.3.3 Announcement and Community Spotlight'
aliases:
  - /2017/12/01/linkerd-1-3-3-announcement-community-spotlight/
author: 'eliza'
date: Fri, 01 Dec 2017 15:39:26 +0000
draft: false
featured: false
thumbnail: /uploads/linkerd_version_133_featured.png
tags: [Buoyant, Community, Linkerd, linkerd, Release Notes]
---

Today we’re happy to announce the release of [Linkerd version 1.3.3](https://github.com/linkerd/linkerd/releases/tag/1.3.3), with a number of bug fixes and performance improvements.

Many Linkerd production users will be especially pleased to see that this release includes fixes for two slow memory leaks that can occur in some conditions.

Since many of the fixes in this release were written by members of the Linkerd community, we wanted to spotlight the work of open source contributors.

## Kubernetes AsyncStream Memory Leak

One of the biggest community contributions in 1.3.3 is Linkerd pull request [#1714](https://github.com/linkerd/linkerd/pull/1714), written by Sergey Grankin ([@sgrankin](https://github.com/sgrankin) on GitHub). Sergey found and [reported](https://github.com/linkerd/linkerd/issues/1694) a slow leak which occurred while using Linkerd as a Kubernetes ingress controller, investigated the issue, and submitted a patch in short order.

This graph of Linkerd memory usage in our test environment displays the dramatic impact of Sergey’s change:

{{< fig
  alt="Linkerd Memory Usage Graph"
  title="Linkerd Memory Usage Graph"
  src="/uploads/2018/05/usage.png" >}}

The orange line shows the memory used by Linkerd 1.3.2, while the green line is memory usage after deploying a build of Sergey’s branch.

Thanks, Sergey!

## Netty4 ByteBuf Memory Leak

1.3.3 also fixes a memory leak caused by incorrect reference counting on a Netty 4 ByteBuf ([#1690](https://github.com/linkerd/linkerd/issues/1690)). Thank you to Linkerd users Zack Angelo ([@zackangelo](https://github.com/zackangelo)) and Steve Campbell ([@DukeyToo](https://github.com/dukeytoo)), who were extremely helpful with reporting and investigating this issue and with validating the fix. Thanks also to Matt Freels ([@freels](https://github.com/freels)) for his help debugging.

## DNS Namer Record Updating Issues

Linkerd user Carlos Zuluaga ([@carloszuluaga](https://github.com/carloszuluaga)) submitted a pull request fixing an issue where the DNS SRV record namer failed to update after changes in DNS records ([#1718](https://github.com/linkerd/linkerd/issues/1718)). In addition to being Carlos’ first contribution to the project (welcome, Carlos!), this contribution is noteworthy in that the SRV record namer is an entirely community-contributed component. We’d also like to thank the namer’s original author, Chris Taylor ([@ccmtaylor](https://github.com/ccmtaylor)), for taking such an active role in his contribution’s ongoing maintenance.

## Namer Plugin Admin UI Fix

Finally, we’d like to thank another first-time Linkerd contributor, Robert Panzer ([@robertpanzer](https://github.com/robertpanzer)). Robert found and fixed an issue where UI elements added by custom namer plugins were not added to the admin UI ([#1716](https://github.com/linkerd/linkerd/issues/1716)). Linkerd’s plugin interface allows plugins to add nav items and handlers to the admin web UI, but due to an error in the function that registers plugins, these UI items were never actually added to the admin page. Thanks Robert!

## The Linkerd Community is Amazing

As always, we’re humbled and gratified to have such a strong open source community around Linkerd. Thanks again to Robert, Carlos, Zack, Steve, Chris, Matt, and Sergey. For a first-hand view into just how helpful the community around Linkerd can be, please join us in the [Linkerd Slack](http://slack.linkerd.io) or on the [Linkerd Support Forum](https://linkerd.buoyant.io/)!
