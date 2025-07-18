---
date: 2021-05-14T00:00:00Z
title: April Linkerd Community Meeting Recap
description: |-
  We chatted with Fredrik Klingenberg about his experience implementing Linkerd
  at Elkjøp, talked about our roadmap, and much more.
keywords: [linkerd]
params:
  author: jason
  thumbnailRatio: fit
---

As always, if you missed the April Linkerd Community Meeting, there is no reason to panic —  we've got you covered. Here's our recap and the recording.

Before getting started, we wanted to remind you of the [Linkerd Anchor program](/community/anchor/). If you have a great Linkerd story, we'd love to help you tell it. Our team is happy to assist with the writing process, reviewing code, or providing guidance on how to create a great video tutorial. [Submit the form](/community/anchor/) and we'll reach out!

We are also still gathering responses to the [Linkerd 2021 user survey](https://docs.google.com/forms/d/e/1FAIpQLSfofwKQDOrAN9E9Vg1041623A3-8nmEAxlAbvXw-S9r3QnT9g/viewform). If you haven't participated yet, please do so. It really helps us make this awesome service mesh even more awesome.

## Project updates

We've submitted Linkerd for CNCF graduation, and are currently waiting for a TOC sponsor. We've also added fuzz tests to the proxy, sponsored by the CNCF. You can read more in the blog post: [Introducing fuzz testing for Linkerd](/2021/05/07/fuzz-testing-for-linkerd/).

## Linkerd Roadmap

We’ve been taking feedback from the steering committee and [published a Linkerd roadmap](https://github.com/linkerd/linkerd2/blob/main/ROADMAP.md) you can follow. The big changes we’re working on for 2.11 are:

* **Server-side policy**: To allow for more intelligent decision-making and enforcement of mTLS.
* The **service profile resources** will likely be revamped:
  * As Linkerd evolves, the service profile API must also.
  * The existing API will be gracefully deprecated over time
* **Client-side policy**:
  * To allow more circuit breaker options
  * Support for fault injection
* **Better gRPC support**:
  * Enabling gRPC retries
  * Broader enhancements for gRPC traffic with Linkerd
* Better **integration with Open Metrics and Open Telemetry** as those APIs evolve

## Linkerd @ KubeCon EU

This KubeCon and CloudNativeCon were the most [Linkerd-heavy to date](https://buoyant.io/2021/05/13/kubecon-eu-2021-wrap-up/). We were particularly excited to see so many end users sharing their service mesh journey. It's just great to see how the community shares their lessons learned! This, by the way, ties directly into the [Linkerd Anchor Program](/community/anchor/). If you'd like to tell your story at KubeCon or at any other conference and need help, we'd love to assist you!

## Community convo with Fredrik Klingenberg

Our guest speaker last month was Fredrik Klingenberg, Senior Consultant at Aurum SA, a Norwegian consulting firm. Fredrik has been working with Kubernetes since version 1.5.x (as a reference, Kubernetes is currently at 1.21) and has a lot of hands-on experience. Due to his expertise, he was approached by Microsoft and asked if he could help Elkjøp with their Kubernetes journey. Aurum and Elkjøp joined forces and Fredrik helped the Nordic retail giant move to a home-grown Kubernetes platform powered by Linkerd. You can learn all about it on this [CNCF blog that Fredrik co-authored](https://www.cncf.io/blog/2021/02/19/how-a-4-billion-retailer-built-an-enterprise-ready-kubernetes-platform-powered-by-linkerd/)in February. It was the CNCF’s most viewed blog of that month!

## Timeout with Tarun

Tarun, one of Linkerd's core maintainers, shared what's new with Linkerd 2.10.1. There have been lots of improvements including some bug fixes for a number of edge cases. Traffic splits were updated and can now handle two versions at the same time. We’re also hoping to release 2.10.2 as soon as next week

## Linkerd Heroes

As always, we had three great Linkerd Hero nominees: Saim Safdar has been very active on Twitter and Linkerd's Discord welcoming new members. Rio Kierkels was nominated for his dedication to helping others on the Linkerd Slack. And Ali Ariff for his great code contributions. To learn more about our April heroes, [check out our nomination blog](/2021/04/21/vote-for-your-april-hero/). While they all deserved to win, the community voted and Rio won. Congrats Rio and thanks for being such a great part of the community.

Don't miss the [next community meeting](https://community.cncf.io/events/details/cncf-linkerd-community-presents-may-linkerd-online-community-meetup/) on Thursday, May 27 at 9 am PT.

{{< youtube "sUSetuaSIX4" >}}
