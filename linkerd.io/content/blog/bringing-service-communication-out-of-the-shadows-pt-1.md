---
slug: 'bringing-service-communication-out-of-the-shadows-pt-1'
title: 'Bringing Service Communication Out of the Shadows - Part 1'
aliases:
  - /2017/10/26/bringing-service-communication-out-of-the-shadows-pt-1/
author: 'gmiranda23'
date: Thu, 26 Oct 2017 08:05:40 +0000
thumbnail: /uploads/shadows1_featured_Twitter_ratio.png
draft: false
featured: false
tags: [Buoyant, buoyant, Linkerd, News, Video]
---

It’s been an interesting few months for the service mesh. First, it’s now an ecosystem! [Istio 0.2](https://github.com/istio/istio/milestone/2) was just released, NGINX recently [launched its service mesh](https://www.nginx.com/blog/introducing-nginx-application-platform/), Uber is considering open-sourcing its [Catalyst service mesh](https://thenewstack.io/ubers-catalyst-service-mesh-provides-visibility-speed/), and [Envoy is now hosted by the CNCF](https://www.cncf.io/blog/2017/09/13/cncf-hosts-envoy/). At Buoyant, we’re encouraged by the recent surge in service mesh technology.

Second, that surge validates our “service mesh” approach as a missing building block in the world of microservices. We’re encouraged to see the service mesh gain adoption. But the reality is that a lot of users out there still aren’t even entirely sure what problem a service mesh solves.

In this series we’re going to unpack why this surge is happening now, take an in-depth look at the problems a service mesh solves, and look at where service mesh technology is going next.

This is one article in a series of articles covering service mesh technology. Other installments in this series include:

1. The problem we’re solving (this article)
2. [Making service requests visible]({{< ref
   "bringing-service-communication-shadows-part-2" >}})
3. Adding a layer of resilience
4. Security and implementation
5. Customer use cases
6. Future state & where the technology is going

## Preface

Before we get started, you should know what a service mesh is. If you don’t yet, you should check out a few links. Phil Calçado wrote an informative history of [the service mesh pattern](http://philcalcado.com/2017/08/03/pattern_service_mesh.html), Redmonk shared their [hot take on Istio and Linkerd](http://redmonk.com/jgovernor/2017/05/31/so-what-even-is-a-service-mesh-hot-take-on-istio-and-linkerd/), and—if you’re more the podcast type—The Cloudcast has an introduction to both [Linkerd](http://www.thecloudcast.net/2017/05/the-cloudcast-298-introduction-to.html?m=1) and [Istio](http://www.thecloudcast.net/2017/09/the-cloudcast-312-istio-routing-load.html?m=1). Collectively, those paint a pretty good picture.

TL;DR, a service mesh is a dedicated infrastructure layer for handling service-to-service communication. The service mesh has two distinct components that each behave differently. The [data plane](https://medium.com/@mattklein123/the-universal-data-plane-api-d15cec7a) is the layer responsible for moving your data (aka requests) through your service topology in real time. When your apps make service-to-service calls, they are unaware of the data plane’s existence: it’s basically transparent. In practice, this layer is typically comprised of a series of interconnected proxies.

A service mesh also provides a [control plane](https://medium.com/@mattklein123/the-universal-data-plane-api-d15cec7a): that’s where the magic happens. A control plane exposes new primitives you can use to control how your services communicate. Those primitives enable you to do some [fun things](https://istio.io/docs/tasks/) you couldn’t do before.

When you (as a human) interact with a service mesh, you interact with the control plane. You use the new primitives to compose some form of policy: routing decisions, auth, rate limits, etc. The data plane reads your policies from the control plane and alters its behavior accordingly.

That’s enough to get started. We’ll explore further in-depth later.

Finally, this series focuses on the service mesh in a broad sense. This series isn’t a side-by-side feature comparison of specific tools. Unless absolutely necessary, I’ll skew toward using general examples instead of product-specific examples.

## The problem

Service-to-service communication lives in the shadows. There’s a lot we can infer about the state of service communication based on circumstantial evidence. Directly measuring the health of those requests at any given time is a challenge with no clear solution.

You’re probably monitoring network performance stats somehow today. Those metrics tell you a lot about what’s happening in the lower level network layer: packet loss, transmission failures, bandwidth utilization, and so on. That’s important data. It tells you if your network is healthy. But it’s hard to infer anything about service-to-service communications from such low-level metrics. Directly monitoring the health of application service requests means looking further up the stack.

You might use a latency monitoring tool—like [smokeping](http://www.smokeping.org)—to get closer to measuring service health. This breed of tools provide useful external availability data. But that’s an external view. If you notice suboptimal performance, troubleshooting issues means correlating those external measures with an internal data source like an application event stream log captured somewhere. You get closer to inferring how your services are behaving by triaging between data sources. But you still aren’t measuring service health directly.

Using an in-band tool—like [tcpdump](http://www.tcpdump.org/)—gets you right into examining service communication where it happens: the packet level. Again, this is a low-level inspection tool, albeit a powerful one. To find the data that’s relevant, you have to filter out all normal traffic by looking for specific payloads, targets, ports, protocols, or other bits of known information. In any reasonable production setting, that’s a flood of data. You are searching for needles in a proverbial haystack. With enough sophisticated scaffolding, that search can be made more effective. Even then, you still need to correlate data from the types of tools named above to triage and infer the health of service-to-service communications.

If you’ve managed production applications before, you probably know this dance well. And for a majority of us, these tools and tactics have mostly been good enough. Troubleshooting service communication can be an uncommon event since many monolithic applications make relatively few service requests and it’s often clear where they are coming from and going to. Investing time to create more elegant solutions to unearth what’s happening in that hidden layer simply hasn’t been worth it.

Until microservices.

## Managing requests for microservices

When you start building out microservices, service-to-service communication becomes the default. In production, it’s not always clear where requests are coming from or where they’re going to. You become painfully aware of the service communication blindspot.

Some development teams solve for that blindspot by building and embedding custom monitoring agents, control logic, and debugging tools into their service as communication libraries. And then they embed those into another service, and another, and another ([Jason McGee summarizes](http://www.thecloudcast.net/2017/09/the-cloudcast-312-istio-routing-load.html?m=1) this pattern well).

The service mesh exists to decouple that communication logic from your applications. The service mesh provides the logic to monitor, manage, and control service requests by default, everywhere. It pushes that logic into a lower part of the stack where it can be more easily managed across your entire infrastructure.

The service mesh doesn’t exist to manage parts of your stack that already have sufficient controls, like packet transport & routing at the TCP/IP level. The service mesh presumes that a usable (even if unreliable) network already exists. The scope of the service mesh is only that blind spot more easily seen by the shift to microservice architectures.

If you’re asking yourself whether you need a service mesh, the first sign that you do is that you have a lot of services intercommunicating within your infrastructure. The second is that you have no direct way of determining the health of that intercommunication. Using only indirect measurements to infer what’s happening means you have a blindspot. You might have service requests failing right now and not even know it.

The service mesh works for managing all service-to-service communication, but its value is particularly strong in the world of managing distributed cloud-native applications.

## Visibility isn’t enough

Shining a light into the darkness of service communication is the first step. Because the service mesh is implemented as a series of interconnected proxies, it makes sense to use that layer to directly measure and report the health of service-to-service communication.

The two most common ways of setting up a service mesh (today) are to either deploy each proxy as a container sidecar, or deploy one proxy per physical host. Then, whenever your containerized applications make external service requests, they route through the new proxy.

But visibility isn’t enough to run production microservices. Those services need to be resilient and secure. The implemented architecture of the service mesh also provides an opportunity to improve several problems where they occur.

Before the service mesh, service communication logic has mostly been bundled into application code: open a socket, transmit data, retry if it fails, close the socket when you’re done, etc. By abstracting that logic and exposing primitives to control that behavior on an infrastructure level, you can decouple service communication from your applications. From a code perspective, all your apps now need to do is make a plain old external service call.

On a global (or partial) infrastructure level, you can then decide how those communications occur. Should they all be TLS encrypted by default? If a service call fails, should it be retried, and how often for how long? Which critical service calls should be dynamically load-balanced to the most performant instances of a particular service?

For example, the service mesh can simplify how you manage TLS certificates. Rather than baking those certs into every microservice application, you can handle that logic in the service mesh layer. Code all of your apps to make a plain HTTP call to external services. At the service mesh layer, specify the cert and encryption method to use when that call is transmitted over the wire and manage any exceptions on a per service basis. When you eventually need to update certificates, you handle that at the service mesh layer without needing to change any application code.

The service mesh both simplifies your apps and gives you finer-grain control. You push management of all service requests down into an organization-wide set of intermediary proxies (or a ‘mesh’) that inherit a common behavior with a common management interface.

## Service communication as a first-class citizen

The data plane shines a light into the previously dark realm of service-to-service communications to make them visible and measureable. The control plane then exposes ways to more easily manage and control the behavior of that communication. Together, they bring service-to-service communication up to the level where any mission critical component of your infrastructure needs to be: managed, monitored, and controlled.

Monolithic architectures have enabled service communication to live in the shadows for decades. But with microservices, that long hidden problem is one we can’t continue to live with anymore. The service mesh turns service communication into a first-class citizen within your application infrastructure.

We’ve laid out a few benefits of the service mesh in this article. In the next installment of this series, we’ll explore how the various features of the service mesh are implemented in practice.
