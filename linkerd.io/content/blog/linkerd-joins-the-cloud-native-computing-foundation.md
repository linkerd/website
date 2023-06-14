---
slug: 'linkerd-joins-the-cloud-native-computing-foundation'
title: 'Linkerd Joins the Cloud Native Computing Foundation'
aliases:
  - /2017/01/23/linkerd-joins-the-cloud-native-computing-foundation/
author: 'william'
date: Tue, 24 Jan 2017 00:20:26 +0000
draft: false
featured: false
thumbnail: /uploads/linkerd_cncf_featured.png
tags: [Buoyant, buoyant, Linkerd, linkerd, News]
---

_(This bit of Linkerd history appeared on 24 January 2017, cross-posted on
the [Cloud Native Computing Foundation
blog](https://www.cncf.io/blog/2017/01/23/linkerd-project-joins-cloud-native-computing-foundation).
Linkerd has evolved quite a lot since 2017: in particular, what we donated in
2017 was Linkerd 1, not the powerful, secure, Rust-based Linkerd 2 of today.
However, we'll always be proud to have been a part of the early history of the
CNCF, and grateful for the phenomenal support of our community. Thank you!)_

----

Today, the [Cloud Native Computing Foundation](http://cncf.io/)’s (CNCF) Technical Oversight Committee (TOC) voted to accept [Linkerd](https://linkerd.io/) as its fifth hosted project, alongside [Kubernetes](https://kubernetes.io/), [Prometheus](https://prometheus.io/), [OpenTracing](https://opentracing.io/) and [Fluentd](https://www.fluentd.org/).

Linkerd is an open source, resilient service mesh for cloud-native applications. Created by Buoyant founders [William Morgan](https://twitter.com/wm) and [Oliver Gould](https://twitter.com/olix0r) in 2015, Linkerd builds upon [Finagle](http://finagle.github.io/), the scalable microservice library that powers companies like [Twitter](https://twitter.com/), [Soundcloud](https://soundcloud.com/), [Pinterest](https://pinterest.com/) and [ING](https://ing.com/). Linkerd brings scalable, production-tested reliability to cloud-native applications in the form of a *service mesh*, a dedicated infrastructure layer for service communication that adds resilience, visibility and control to applications without requiring complex application integration.

{{< fig
  alt="logo"
  title="logo"
  src="/uploads/2017/07/buoyant-linkerd-logo.png" >}}

“As companies continue the move to cloud native deployment models, they are grappling with a new set of challenges running large scale production environments with complex service interactions,” said [Fintan Ryan](https://twitter.com/fintanr), Industry Analyst at [Redmonk](http://redmonk.com/). “The service mesh concept in Linkerd provided a consistent abstraction layer for these challenges, allowing developers to deliver on the promise of microservices and cloud native applications at scale. In bringing Linkerd under the auspices of CNCF, Buoyant are providing an important building block for the wider cloud native community to use with confidence.”

## ENABLING RESILIENT AND RESPONSIVE MICROSERVICE ARCHITECTURES

Linkerd enables a consistent, uniform layer of visibility and control across services and adds features critical for reliability at scale, including latency-aware load balancing, connection pooling, automatic retries and circuit breaking. As a service mesh, Linkerd also provides transparent TLS encryption, distributed tracing and request-level routing. These features combine to make applications scalable, performant, and resilient. Linkerd integrates directly with orchestrated environments such as Kubernetes and DC/OS, and supports a variety of service discovery systems such as ZooKeeper, Consul, and `etcd`. It features HTTP/2 and [gRPC](http://www.grpc.io/) support, and can provide metrics in [Prometheus](https://prometheus.io/) format.

“The service mesh is becoming a critical part of building scalable, reliable cloud native applications,” said [William Morgan](https://twitter.com/wm), CEO of Buoyant and co-creator of Linkerd. “Our experience at Twitter showed that, in the face of unpredictable traffic, unreliable hardware, and a rapid pace of production iteration, uptime and site reliability for large microservice applications is a function of how the services that comprise that application communicate. Linkerd allows operators to manage that communication at scale, improving application reliability without tying it to a particular set of libraries or implementations."

Companies and organizations around the world use Linkerd in production to power their software infrastructure, including [Monzo](https://monzo.com/), [Zooz](https://zooz.com/), [ForeSee](https://foresee.com/), [Olark](https://olark.com/), [Houghton Mifflin Harcourt](https://hmhco.com/), the [National Center for Biotechnology Information](https://www.ncbi.nlm.nih.gov/), and [Douban](https://www.douban.com/). Linkerd is featured as a default part of cloud-native distributions such as Apprenda’s [Kismatic Enterprise Toolkit](https://github.com/apprenda/kismatic) and StackPointCloud.

“Linkerd was built based on real world developer experiences in solving problems found when building large production systems at web scale companies like Twitter and Google,” said [Chris Aniszczyk](https://twitter.com/cra), COO of of the CNCF. “It brings these expertise to the masses, allowing a greater number of companies to benefit from microservices. I’m thrilled to have Linkerd as a CNCF inception project and for them to share their knowledge of building a cloud native service mesh with scalable observability systems to the wider CNCF community.”

{{< fig
  alt="individual instance diagram"
  title="individual instance diagram"
  src="/uploads/2017/07/buoyant-diagram-individual-instance.png" >}}

As CNCF’s first inception level project, under the CNCF Graduation Criteria v1.0, Linkerd will receive mentoring from the TOC, priority access to the CNCF Community Cluster, and international awareness at CNCF events like [CloudNativeCon/KubeCon Europe](http://events17.linuxfoundation.org/events/kubecon-and-cloudnativecon-europe). The CNCF Graduation Criteria was recently voted in by the TOC to provide every CNCF project an associated maturity level of either inception, incubating or graduated, which allows CNCF to review projects at different maturity levels to advance the development of cloud native technology and services.
