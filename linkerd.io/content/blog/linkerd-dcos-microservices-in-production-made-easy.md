---
slug: 'linkerd-dcos-microservices-in-production-made-easy'
title: 'Linkerd on DC/OS: Microservices in Production Made Easy'
aliases:
  - /2016/04/19/linkerd-dcos-microservices-in-production-made-easy/
author: 'william'
date: Tue, 19 Apr 2016 22:21:14 +0000
draft: false
featured: false
thumbnail: /uploads/linkerd_featured_EASY.png
tags: [buoyant, Linkerd, linkerd, News, Product Announcement]
---

As part of the [launch of DC/OS](http://dcos.io/), the open source Mesos ecosystem from Mesosphere, Buoyant, and dozens of other companies, we’re happy to announce the launch of [Linkerd](https://linkerd.io/) for DC/OS!

As of today, you can install Linkerd and its companion project, namerd, on your DC/OS cluster with two simple commands:

```bash
dcos package install Linkerd
dcos package install namerd
```

Together, Linkerd and namerd form Buoyant’s open source *service mesh* for cloud-native applications. If you’re running software on DC/OS, you’ll get global, programmable control of all HTTP or RPC traffic across your entire application. For devops and SRE teams, this means you’ll be able to gracefully handle service failures and degradations on the fly by failing over across service clusters or shifting traffic to other regions. You’ll also be able to take advantage of powerful new mechanisms for testing the production readiness of new code *before* it serves production traffic.

While microservices provide many benefits to application scalability and reliability, they also bring new challenges for SRE teams tasked with ensuring reliability and performance. Together, DC/OS and Linkerd directly address these challenges. Mesos automatically handles hardware failure and software crashes, providing the fundamental building blocks around component resilience. Linkerd broadens those semantics to the service level, allowing you to automatically shift traffic away from slow, overloaded, or failing instances.

{{< fig
  src="/uploads/2016/04/routing-diagram.png"
  alt="Traffic routing decouples the deployment topology"
  title="Traffic routing decouples the deployment topology" >}}

Linkerd also gives you powerful new mechanisms around *traffic routing*, or runtime control of the HTTP or RPC traffic within an application. By decoupling your application’s deployment topology from its traffic-serving topology, Linkerd makes blue-green deploys, staging, canarying, proxy injection, and pre-production environments easy—even when the services are deep within the application topology.

In the demo below, we’ll show you how to do a simple, percentage-based blue-green deploy in a microservice application running on DC/OS, and we’ll throw in a cross-service failover for good measure.

{{< youtube 3fV7v1gyYms >}}

Together, Linkerd and DC/OS make it incredibly easy to turn a collection of containers into a resilient, scalable, and operable microservice architecture. Best of all, much like DC/OS, Linkerd is built on top of open source technology that powers companies like Twitter, Pinterest, SoundCloud, and ING Bank. With Linkerd on DC/OS, you’ll be able to build your microservices on top of strong open source foundations, and proven, production-tested implementations.
