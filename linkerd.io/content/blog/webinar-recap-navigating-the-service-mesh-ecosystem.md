---
slug: 'webinar-recap-navigating-the-service-mesh-ecosystem'
title: 'Webinar recap: Navigating the service mesh ecosystem'
aliases:
  - /2018/03/26/webinar-recap-navigating-the-service-mesh-ecosystem/
author: 'gmiranda23'
date: Mon, 26 Mar 2018 17:30:38 +0000
draft: false
featured: false
thumbnail: /uploads/navigating_the_ecosystem.png
tags: [Conduit, Uncategorized]
---

Conduit is now part of Linkerd! [Read more >]({{< relref
"conduit-0-5-and-the-future" >}})

Earlier this month, Christian Posta (Red Hat) joined me to present a joint webinar looking at the various open-source service mesh projects (Linkerd, Envoy, Istio, and Conduit) to help users make sense of where to start and how to navigate the many options available to them. Check out the webinar below for the full length session along with Q&A.

The webinar has tips for both beginners and advanced users. We begin with a brief high-level overview of common service mesh architecture and explore the types of considerations that teams should be thinking about when evaluating different solutions, both from a technical and organizational perspective.

{{< youtube X8CBGsTLuHU >}}

Below are some highlights. We hope you’ll watch the recording, and please join us on the individual project Slack channels if you have more specific questions ([Linkerd](https://linkerd.slack.com), [Envoy](https://envoyslack.cncf.io/), [Istio](https://istio.slack.com/), and #conduit on [Linkerd Slack](https://slack.linkerd.io/)). You can also reach either [Christian](https://twitter.com/christianposta) or [me](https://twitter.com/gmiranda23) directly via Twitter, the [CNCF Slack group](https://cloud-native.slack.com/), or the [Kubernetes Slack group](https://kubernetes.slack.com). We’d love to hear about your journey into navigating the service mesh ecosystem and how we can help get you started.

## Service mesh architecture

Aside from [basics about a service mesh](https://buoyant.io/2017/04/25/whats-a-service-mesh-and-why-do-i-need-one/), we discussed how the shift to microservices introduces a new class of communication into your infrastructure. In microservice-based architectures, service-to-service communication suddenly becomes the primary fundamental factor that determines how your applications will behave at runtime.

Complicating runtime behavior, the shift to microservices also means you begin to see a sprawl of ownership and workflows. Services typically shift to being owned by different teams, with different schedules, and often conflicting priorities. Understanding the relationships between the many interdependent services supporting your mission critical apps can easily become impossible. The service mesh exists to solve these operational runtime challenges.

{{< fig alt="Basic service mesh architecture"
src="/uploads/2018/03/Screen-Shot-2018-03-20-at-3.43.11-PM-300x168.png"
title="Basic service mesh architecture" >}}

In this basic architectural diagram the green boxes in the data plane represent apps, the blue squares are service mesh proxies, and the rectangles are app endpoints (a pod, a physical host, etc). The service mesh should also provide a control plane where you, as an operator, compose policy that alters behavior in the data plane. The service mesh manages all service requests (e.g. messages) with an inherent understanding that makes it application aware. It provides capabilities like retries, timeouts, and circuit breaking to improve overall resiliency.

## A new way to solve old problems

The service mesh isn’t just limited to managing service requests. As a proxy layer it can, and should, manage all network traffic. Because the value proposition behind a service mesh is particularly strong when it comes to managing service requests (e.g. messages), we sometimes see frequent comparisons to things like messaging-oriented middleware, an Enterprise Service Bus (ESB), Enterprise Application Integration patterns (EAI), API Gateways, or resilience libraries like Netflix’s Hystrix or Twitter’s Finagle.

The service mesh is different because it lives as a dedicated infrastructure layer that is decoupled and managed separately from your applications. The service mesh relieves developers from having to implement solutions that are tightly coupled to your application business logic.

## Questions should you be asking

Learning about and implementing a new solution always comes at a cost measured in cognitive burden and time. With many service mesh solutions existing today, it helps to clearly understand your own needs before making the investment in due diligence to try out tools that could be right for your environment. To better understand how your needs align with what different service mesh options provide, we covered a list of technical and operational questions to help you pinpoint a starting point on your service mesh journey.

- Am I ready for a service mesh? Is your organization?
- What problems am I having today? Are you experiencing pain today or simply preparing for what you think you might need?
- What platforms does my team need to support?
- What level of observability do your services have today? Where are the current gaps in logging, tracing, etc?
- What functionalities of a service mesh do you already have? Can you introduce a service mesh safely and how will it interact with the features you’ve already built?
- What is the division of responsibility in your organization and will the product you’re considering allow you to work in ways that support that structure?
- Does your team favor centralized or decentralized functionality?
- What support needs does your team have?

## A service mesh landscape

The webinar then dives deep into each of the existing open-source solutions on the market today (Linkerd, Envoy, Istio, and Conduit) to examine the different use cases for which each is best suited. Whether you have a complex architecture that needs to support a number of third-party integrations, you want something easy to use and simple to understand, or if you need a large all-encompassing framework, there is a service mesh solution that could be right for you.

We encourage you to listen to this portion of the webinar because it’s more than we can simply summarize in this post. As always, please reach out if you’d like to dive deeper into your particular situation, and stay tuned for more webinars like this in the future.
