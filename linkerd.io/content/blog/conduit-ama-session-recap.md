---
slug: 'conduit-ama-session-recap'
title: 'Conduit AMA session recap'
aliases:
  - /2017/12/27/conduit-ama-session-recap/
author: 'gmiranda23'
date: Wed, 27 Dec 2017 22:12:40 +0000
draft: false
featured: false
thumbnail: /uploads/conduit_community_recap.png
tags: [Community, conduit, Conduit, News, Release Notes]
---

Conduit is now part of Linkerd! [Read more >]({{< relref
"conduit-0-5-and-the-future" >}})

Earlier this month we [announced Conduit](https://buoyant.io/2017/12/05/introducing-conduit/), the ultralight next-gen service mesh for Kubernetes. We’ve been blown away by the reception to Conduit and we got a chance to speak to many of you in-person at [KubeCon + CloudNativeCon](https://buoyant.io/2017/12/11/kubecon-cloudnativecon-north-america-2017-roundup/). To chat with those who couldn’t make it to Austin, we hosted an Ask Me Anything session via Slack with Buoyant co-founders William Morgan and Oliver Gould on Monday Dec 11.

In case you missed it, we’re sharing a transcript here as well. The transcript has been edited for brevity and clarity, but otherwise contains the AMA questions & answers in their entirety.

---

**How is Conduit different from Istio?**

**William:** Conduit and Istio have basically the same goals (and so does Linkerd): provide reliability, security, flexibility, etc for a microservice app by managing the communication layer, adding timeouts, retries, circuit breaking, TLS, policy... all the stuff we know and love from Linkerd. But they come at it from different angles. For Conduit, we're really focused on providing the smallest possible solution that gets you there. Smallest = memory and CPU footprint, latency impact, etc, but also API surface area and the set of things you have to learn about. That’s a really important difference.

We also have learned a lot from Linkerd over the past 18 months of operating it in prod, and a lot of those lessons are not obvious at all. But we're wrapping them up in Conduit. So, if we do our job right, Conduit will give you all the things you want out of the service mesh without imposing a big burden on either you or your horde of computers.

**What’s in the Conduit 0.1 release today and can we expect next from what’s on the roadmap?**

**Oliver:** For the 0.1 release, our primary target was to provide immediate visibility for gRPC services. This was mostly set as an engineering goal to make us solve the hard problems of transporting HTTP/2, which is quite a bit more complex than plain-old HTTP/1. In the upcoming releases, we’ll expand proxy support for HTTP/1, as well as arbitrary TCP streams. Furthermore, I expect we’ll be integrating with CA systems to provide TLS privacy out-of-the-box.

**When will Conduit be production-ready?**

**Oliver:** Conduit will be production-ready when it’s in production ;-D

But we expect that will be in the early-next-year (2018) timeframe. We’re focused on primarily providing outstanding visibility, security by default, and the base operational features that make your system more resilient to consider Conduit production-ready. Much of the configuration surface area for Conduit, I expect, will be introduced after we can productionize a constrained set of features.

**It looks like Conduit doesn’t currently ship with an Ingress controller. Is the idea that Conduit will have the proxy run as a k8s ingress controller? In the interim do you have and guidance on running Conduit with community provided k8s ingress controllers?**

**Oliver:** This will become quite a bit easier once we hit our Proxy Transparency goals and Conduit is able to route arbitrary traffic. I expect that once that’s done, we’ll have a way to integrate well with k8s ingress resources; though over time, we’ll want something quite a bit better than them. But that should emerge out of Conduit’s routing functionality.

**William:** Personally I think it would be cool to see if we can get something like [Contour](https://github.com/heptio/contour) and Conduit working together.

**Oliver:** Conduor?

**William:** TourDuit?

**After I inject Conduit into my running deployments, what happens if the Conduit sidecar dies? Do I lose the entire deployment? How do I recover?**

**William:** If it dies in one pod, it's tantamount to pod death. We have all sorts of mechanisms for handling that in K8s. But... it shouldn't die.

**Oliver:** And we’d love a bug report in that case if it does.

**Are all of the engineers at Buoyant working on Conduit? Is it split teams, some on Conduit and some on Linkerd? How are you supporting both?**

**William:** We're continuing to invest heavily in Linkerd. It's the world's most widely deployed open source service mesh. And the world's only prod-ready open source service mesh. It's hard to speak for individual engineers, since these are both team efforts. But the same folks who are working on Linkerd are working on Conduit, roughly speaking, and it's important to me for everyone at Buoyant to share expertise across both.

**Does that mean they're equal or is Buoyant prioritizing one over the other?**

**William:** A good way of thinking about it is that we're spending our innovation points on Conduit.

**Oliver:** We want linkerd to be boring. Boring and stable.

**William:** Conduit will be boring... in the future.

**What would you say is the most amazing feature of Conduit?**

**Oliver:** Tap. Definitely tap. Oh, or maybe the per-path stats. Or maybe that flow control is integrated deeply into our buffer management.

**How can non-Buoyant community members get involved with the new project?**

**Oliver:** The best way to get involved right now is [filing issues](https://github.com/runconduit/conduit/issues) and giving feedback! But over the next few weeks, we’ll be posting a lot more of our roadmap and good guidance for getting started will be up.

**William:** Yeah. We already hit our first issue today in the Slack #conduit channel where someone wasn't able to get Conduit working due to (we suspect) RBAC. Which is probably totally right! And awesome. We should fix that. _Editor’s note: that was fixed in the_ [_Conduit 0.1.1 release_]({{< relref "announcing-conduit-0-1-1" >}}) _on Dec 20._

**What about from the contribution perspective? Does the choice of Rust limit the pool of potential contributors submitting PR's?**

**William:** I**'m actually hoping that the fact that the control plane is in Go will lower the barrier for contributions to Conduit. I think with Linkerd we suffer a bit from the fact that Scala (and not just regular Scala, but Finagle-ized Scala) is not trivial to ramp up on.**

**Oliver:** And Rust is also a non-trivial (though wildly fun) ramp to traverse.

**William:** Rust has quite a steep learning curve as well, but the data plane is isolated from a lot of what people want to do, so I think overall we're probably in better shape for accepting contributions with Conduit than we are with Linkerd. Besides, that coveted First PR Accepted award is still out there, waiting for just the right person… _Editor’s note: we accepted the_ [_first community PR_](https://github.com/runconduit/conduit/pull/83) _on Dec 22. Thanks,_ [_FaKod_](https://github.com/FaKod)_!_

**In playing around with Conduit this weekend I was a little confused by the Proxy Status UI. Can you explain what that represents and how it's intended to be used?**

{{< fig
  alt="dashboard"
  title="Dashboard"
  src="/uploads/2017/12/Screen-Shot-2017-12-21-at-9.43.47-AM.png" >}}

**William:** It represents the pods in the deployment, and which ones have the Conduit project injected (green) vs which ones don't (grey). In that screenshot you've captured a deployment in the middle of rolling a \`conduit inject\`, I suspect. So you have a halfway state. There are definitely a couple of things we can do to make this more clear, but that's the goal at least.

**Kevin Lingerfelt:** Also, just last week we [added hover states for the circles](https://github.com/runconduit/conduit/pull/19) in that column, to help explain what they mean. will be in the [0.1.1 release](https://github.com/runconduit/conduit/releases/tag/v0.1.1).

**William:** Like that ^. We're also not capturing when pods are in a Terminating state right now. When we add that, we can make the transition states for a deployment even more obvious.

**As a non-Rust developer interested in getting involved it's not clear how to get started, what the best dev cycle is. So a getting started doc might be helpful?**

**William:** For sure. that's on our short-term todo list. And you may not actually have to learn Rust to contribute... in fact, I'm hoping that you _don't_ have to learn Rust to contribute except for a very particular set of features.

**Oliver:** Yeah, totally. The controller APIs are still settling, but those will become the place to help build out better features.

**What should we expect to see around the release pace for Conduit? Linkerd has been getting released about every 2 weeks. Same for Conduit? More? Less?**

**William:** I don't know if we'll stick to exactly 2 weeks, though I like that pace. We definitely have some aggressive goals around getting ready for prod usage as rapidly as possible with a minimal feature set, and like Oliver said above, we're aiming to do that by early next year. One of the other things that makes our lives a bit easier vs Linkerd is that the Conduit control plane will be configurable via gRPC plugins. This means a) we can ship with a minimal feature set since everything will be very customizable; and b) that user plugins don't have to run in the data plane.

---

[Try Conduit](https://conduit.io/getting-started/) today. Hopefully the transcript answers some of the questions you've had about Conduit. If it doesn't, pop into the #conduit channel on the [Linkerd Slack group](http://linkerd.slack.com) to chat with us directly. Open issues or submit PR's [directly via Github](https://github.com/runconduit/conduit). And if you want to work with us, [we're hiring](https://buoyant.io/careers/)!
