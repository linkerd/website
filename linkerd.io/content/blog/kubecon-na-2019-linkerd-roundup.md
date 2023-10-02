---
title: 'Linkerd at Kubecon NA 2019 roundup: Nordstrom, Microsoft, OpenFaaS, PayBase, and lots of community!'
author: 'william'
date: Tue, 26 Nov 2019 09:00:00 -0800
draft: false
featured: false
slug: linkerd-at-kubecon-na-2019-roundup
tags: [Community, Linkerd, Kubecon]
thumbnail: /uploads/kccnceu19-linkerd.jpg
---

![Linkerd at KCCNCNA19](/uploads/kccncna19-linkerd.jpg)

Once again, Linkerd momentum was at an all-time high at last week's Kubecon NA
in San Diego. This was the biggest Kubecon yet, with 10k+ attendees, hundreds
of talks, and a great Linkerd presence.

If you weren't able to make it, never fear! Most of the talk videos are already
live. Here's a quick recap of the Linkerd news.

## Nordstrom's Linkerd Deployment

One of the highlights of the show was the talk by Nordstrom engineers Hema Lee
and Cody Vandermyn titled [Service Mesh: There and Back
Again](https://www.youtube.com/watch?v=sq8nsjuJqO4), in which they detail
Nordstrom's service mesh journey and why they chose Linkerd.

{{< youtube sq8nsjuJqO4 >}}

## Serverless + Service Mesh with Linkerd and OpenFaaS

OpenFaaS founder Alex Ellis joined Linkerd engineer Charles Pretzer for a great
talk entitled [OpenFaaS Cloud + Linkerd: A Secure, Multi-Tenant
Serverless Platform](https://www.youtube.com/watch?v=sD7hCwq3Gw0). Two great
open source projects that go great together!

{{< youtube sD7hCwq3Gw0 >}}

## Microsoft, Linkerd, CI/CD, and OPA

As usual, lots of great Linkerd content from our friends at Microsoft. Brian
Redmond gave some great Linkerd demos in a talk entitled [Supercharge Your
Microservices CI/CD with Service Mesh and
Kubernetes](https://www.youtube.com/watch?v=SMoaem3UBag), and Microsoft's Rita
Zhang joined Linkerd engineer Ivan Sim for a presentation on [Enforcing
Automatic mTLS With Linkerd and OPA
Gatekeeper](https://www.youtube.com/watch?v=gMaGVHnvNfs).

{{< youtube gMaGVHnvNfs >}}

## Debugging Linkerd at Paybase

Sometimes even the service mesh has bugs. Paybase engineer Ana Calin joined
Linkerd maintainer Risha Mars for a talk titled [There's a bug in my service
mesh! What do you do when the mesh is at
fault?"](https://kccncna19.sched.com/event/UaZB/theres-a-bug-in-my-service-mesh-what-do-you-do-when-the-mesh-is-at-fault-ana-calin-paybase-risha-mars-buoyant),
covering Ana and Risha's process for identifying, triaging, reporting, and
fixing bugs in service meshes. (Sadly, looks like the video isn't up for this
talk yet.)

## Linkerd intro and deep dive sessions

As usual, I did my [Intro to Linkerd
talk](https://www.youtube.com/watch?v=guHZ7U7ZoWc), and Oliver Gould did the
[Linkerd Deep Dive](https://www.youtube.com/watch?v=NqjRqe0J98U) talk. Both
talks were jam-packed with people and had some really great Q&A.

{{< youtube guHZ7U7ZoWc >}}
{{< youtube NqjRqe0J98U >}}

## Linkerd in the news

Linkerd's momentum is not lost on the press. I particularly like this quote
from Cody in [Linkerd vs. Istio battle heats up as service mesh gains
steam](https://searchitoperations.techtarget.com/news/252474376/Linkerd-vs-Istio-battle-heats-up-as-service-mesh-gains-steam):

"We performance tested Istio and Linkerd just over a year ago, and chose
Linkerd," said Cody Vandermyn, senior engineer at Nordstrom, a large retailer
headquartered in Seattle. "At the time, our tests found that for us, Linkerd
introduced less latency and met our requirements around memory footprint."

## Wrapping it all up

This was another great Kubecon for Linkerd. As usual, the best part for me is
the chance to meet other members of our enthusiastic and friendly community in
person. I'm looking forward to doing more of the same next March in Amsterdam!

{{< tweet user="LiliCosic" id="1197335694856687616" >}}

{{< tweet user="DC_Corbin3" id="1197953404154216448" >}}

{{< tweet user="eamonb" id="1197348236198965249" >}}

## Join us!

Linkerd is a community project and is hosted by the [Cloud Native Computing
Foundation](https://cncf.io). If you have feature requests, questions, or
comments, we'd love to have you join our rapidly-growing community! Linkerd is
hosted on [GitHub](https://github.com/linkerd/), and we have a thriving
community on [Slack](https://slack.linkerd.io),
[Twitter](https://twitter.com/linkerd), and the [mailing
lists](https://linkerd.io/2/get-involved/). Come and join the fun!
