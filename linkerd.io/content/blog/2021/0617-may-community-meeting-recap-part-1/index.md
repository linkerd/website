---
title: Linkerd at KubeCon EU
description: |-
  May's Community Meeting was a little different than our typical meetups. Hot
  off a successful KubeCon EU, we chose to recap the great Linkerd stories told
  during the conference"
date: 2021-06-17T00:00:00Z
keywords: [community]
params:
  author: jason
  thumbnailProcess: fit
  videoSchema:
    - title: Why the future of the cloud will be built on Rust
      description: |-
        In his Cloud Native Rust Day talk, Oliver Gould notes that system
        programming differs from app programming and requires a different
        language like Rust.
      embedUrl: https://youtu.be/BWL4889RKhU
      thumbnailUrl: http://i3.ytimg.com/vi/BWL4889RKhU/maxresdefault.jpg
      uploadDate: 2021-05-14
      duration: PT31M26S
    - title: |-
        Panel Discussion: Rust in the Cloud
      description: |-
        In this panel discussion, the speakers agreed that Rust front-loads the
        application maintenance burden and is extremely secure and performant.
      embedUrl: https://youtu.be/8oOiqbxGu0U
      thumbnailUrl: http://i3.ytimg.com/vi/8oOiqbxGu0U/maxresdefault.jpg
      uploadDate: 2021-05-14
      duration: PT43M28S
    - title: Scheduling 68k COVID Tests with Linkerd
      description: |-
        Dom DePasquale and Shawn Smith from the Pennsylvania State University
        discussed how they scheduled 68,000 COVID tests before the fall semester
        started.
      embedUrl: https://youtu.be/dDW1OoTaMdU
      thumbnailUrl: http://i3.ytimg.com/vi/dDW1OoTaMdU/maxresdefault.jpg
      uploadDate: 2021-05-14
      duration: PT24M38S
    - title: Rapid Experimentation Simplified with Linkerd
      description: |-
        When Alexander Simon Jones worked at a multi-national financial
        institution his team used Linkerd to simplify experimentation.
      embedUrl: https://youtu.be/EB6QWpIYMSA
      thumbnailUrl: http://i3.ytimg.com/vi/EB6QWpIYMSA/maxresdefault.jpg
      uploadDate: 2021-05-14
      duration: PT16M21S
    - title: Tap Tap, Debugging an App with your Service Mesh
      description: |-
        In his ServiceMeshCon talk, Jason Morgan shows how easy it is to debug
        an app with Linkerd. The tap tool inspects traffic flowing through the
        mesh.
      embedUrl: https://youtu.be/YJ8zP-lqB5E
      thumbnailUrl: http://i3.ytimg.com/vi/YJ8zP-lqB5E/maxresdefault.jpg
      uploadDate: 2021-05-14
      duration: PT21M24S
    - title: Creating Chaos in the University with Linkerd and Chaos Mesh
      description: |-
        Jossie Bismarck Castrillo Fajardo and Sergio Arnaldo Méndez Aguilar,
        discuss how they used Chaos Mesh and Linkerd to inject faults and
        failures.
      embedUrl: https://youtu.be/vGVtnP8gOl8
      thumbnailUrl: http://i3.ytimg.com/vi/vGVtnP8gOl8/maxresdefault.jpg
      uploadDate: 2021-05-14
      duration: PT19M38S
    - title: |-
        Panel: The State of Service Mesh
      description: |-
        According to the panelists, enterprises must decide whether they want to
        write and maintain code that a service mesh provides or have a platform
        team that supports it.
      embedUrl: https://youtu.be/Uf1C5oxrv4w
      thumbnailUrl: http://i3.ytimg.com/vi/Uf1C5oxrv4w/maxresdefault.jpg
      uploadDate: 2021-05-14
      duration: PT23M16S
    - title: |-
        Compliance the Easy Way: Zero-conf mTLS for Dev and Smooth Day-2 for Ops
      description: |-
        Christian Hüning and Lutz Behnke discuss how they implemented mTLS
        without needing their dev team to do any work.
      embedUrl: https://youtu.be/KoweR6u0t8c
      thumbnailUrl: http://i3.ytimg.com/vi/KoweR6u0t8c/maxresdefault.jpg
      uploadDate: 2021-05-14
      duration: PT21M42S
    - title: Seamless Multi-Cluster Communication and Observability with Linkerd
      description: |-
        Max Körbächer from Liquid Reply provided a great breakdown of when it
        makes.
      embedUrl: https://youtu.be/X70Tb54Y-o4
      thumbnailUrl: http://i3.ytimg.com/vi/X70Tb54Y-o4/maxresdefault.jpg
      uploadDate: 2021-05-14
      duration: PT39M28S
    - title: |-
        Keynote: Linkerd vs. COVID-19: Addressing the global Pandemic with a
        Service Mesh
      description: |-
        William Morgan shares some examples of how organizations like NIH,
        Clover Health, Penn State, and H-E-B, have been using Linkerd in their
        effort to face COVID-19 challenges.
      embedUrl: https://youtu.be/S-7XbbJMonM
      thumbnailUrl: http://i3.ytimg.com/vi/S-7XbbJMonM/maxresdefault.jpg
      uploadDate: 2021-05-14
      duration: PT9M22S
    - title: Overview and State of Linkerd
      description: |-
        William Morgan and Matei David delivered a quick overview of the state
        of Linkerd, why we are witnessing an increase in adoption, and what
        drives this great and welcoming community.
      embedUrl: https://youtu.be/ATUkfUwbBvo
      thumbnailUrl: http://i3.ytimg.com/vi/ATUkfUwbBvo/maxresdefault.jpg
      uploadDate: 2021-05-14
      duration: PT18M48S
---

## May Community Meeting Recap Part 1

May's Community Meeting was a little different than our typical meetups. Hot off
a successful KubeCon EU (at least from a Linkerd perspective), we chose to recap
the great Linkerd stories told during the conference. Also featured was an
amazing talk by  Linkerd maintainer, Matei Davis, on multi-cluster with headless
services.

Because this meeting yielded such great content, we're splitting the recap into
two blogs. Today, we'll focus on KubeCon EU.

Before we get started, just a quick reminder of the
[Linkerd Anchor program](https://linkerd.io/community/anchor/).
If you have a great Linkerd story, we’d love to help you tell it.
We can assist with the writing process, reviewing code, or providing guidance on
how to create a helpful video tutorial.
[Complete this form](https://linkerd.io/community/anchor/) and we’ll reach out!

## Linkerd at KubeCon EU 2021

Here's a quick overview of each Linkerd talk at KubeCon EU 2021 along with the
video recording.

## Why the future of the cloud will be built on Rust

In his Cloud Native Rust Day talk, Buoyant CTO, Oliver Gould,  notes that system
programming differs from application programming and requires a different
language like Rust. Apps that are written in Rust provide the confidence in
memory safety and
[reliability](https://linkerd.io/service-mesh-glossary/#reliability) that infra
teams need.

Rust is a great language for that purpose because it has a robust safety net.
It requires error handling and prevents runtime errors, safe concurrency in
isolation with the borrow checker, and follows a "resource acquisition is
initialization" (RAII) model. Tokio and Tonic offer mature networking
functionality while kube-rs (client-go for Rust) is one to watch.

{{< youtube "BWL4889RKhU" >}}

## Panel Discussion: Rust in the Cloud

In this Cloud Native Rust Day panel discussion, Paul Howard (Arm), William
Morgan (Buoyant), Oliver Gould (Buoyant), Ashley Williams (Rust Foundation), and
Carl Lerche (Amazon) agreed that Rust front-loads the application maintenance
burden and is extremely secure and performant.

Rust is still new and the community is heavily invested in improving the
developer experience. Even though it has a steep learning curve, there is
excellent developer tooling. All panelists were confident that we’ll see a lot
of investment in this language moving forward and encourage everyone who hasn't
tried Rust, to do so now.

{{< youtube "8oOiqbxGu0U" >}}

## Scheduling 68k COVID Tests with Linkerd

Dom DePasquale and Shawn Smith from the Pennsylvania State University discussed
how they scheduled 68,000 COVID tests before the fall semester started. To do
that, they needed a [service
mesh](https://linkerd.io/service-mesh-glossary/#service-mesh) that was simple
and provided mTLS and free retries. While
[observability](https://linkerd.io/service-mesh-glossary/#observability) was the
most critical feature for this project, multi-cluster and traffic split came in
handy.

{{< youtube "dDW1OoTaMdU" >}}

## Rapid Experimentation Simplified with Linkerd

Before joining Civo, Alexander Simon Jones worked at a multi-national financial
institution where the team used Linkerd to simplify experimentation. He's been a big
proponent of using service meshes for that purpose ever since. Here are his main
takeaways:

* A service mesh is a key component to rapid experimentation, both for traffic
splitting and observability
* Standardized metrics simplify experimentation
* A service mesh helps operations and QA team build out experiments

{{< youtube "EB6QWpIYMSA" >}}

## Tap Tap, Debugging an App with your Service Mesh

In his ServiceMeshCon talk, Jason Morgan, Tech Evangelist at Buoyant, shows how
easy it is to debug an app with Linkerd. The Linkerd tap tool inspects traffic
flowing through the service mesh. With debugging tools like Tap, service graphs,
and routes, the mean time to resolution (MTTR) is significantly shorter.

{{< youtube "YJ8zP-lqB5E" >}}

## Creating Chaos in the University with Linkerd and Chaos Mesh

Computer science student, Jossie Bismarck Castrillo Fajardo, and his professor,
Sergio Arnaldo Méndez Aguilar, discuss the hows and whys of chaos experimenting.
During their ServiceMeshCon talk, they discuss using Chaos Mesh and Linkerd to
inject faults and failures. If you'd like to try it yourself, Jossie and Sergio
[shared their
repo](https://github.com/sergioarmgpl/operating-systems-usac-course) for anyone
to reproduce their experiments.

{{< youtube "vGVtnP8gOl8" >}}

## Panel: The State of Service Mesh

This panel, which included William Morgan (Buoyant), Idit Levine (Solo.io),
Nic Jackson (Hashicorp), Marco Palladino (Kong Inc), Louis Ryan (Google),
and Lin Sun (Solo.io) covered a lot of ground. For instance, how should users
decide if they need a service mesh? According to the panelists, enterprises must
decide whether they want to write and maintain code that a service mesh provides
or have a platform team that supports a service mesh. Either way, they do need
that functionality — there is no way around that.

Over the past few years, the state of the service mesh has evolved. Not too
long ago, enterprises asked themselves if they needed a service mesh. Today,
the question is rather when should they adopt one. While the service mesh has
become socially easier to adopt, practically it's still challenging. More
vendors translate into more decision complexity.

William concluded with a quick overview of what's next for Linkerd. Users will
soon see policy updates including configuring and enforcing rules about how
services communicate with each other. Modularity through extensions is only
highly encouraged.

{{< youtube "Uf1C5oxrv4w" >}}

## Compliance the Easy Way: Zero-conf mTLS for Dev and Smooth Day-2 for Ops

Christian Hüning and Lutz Behnke from the German-based fintech startup Finleap
Connect (which adopted Linkerd after struggling with Istio) shared their
journey to mTLS.  In their KubeCon talk, they discuss how they implemented mTLS
without needing their dev team to do any work. The service mesh enabled them
to easily scale to over 5,000 pods. And, after externalizing Prometheus, the
team helped Linkerd evolve. By the way, their help with the cert-manager
integration was fundamental and much appreciated by everyone at Linkerd!

{{< youtube "KoweR6u0t8c" >}}

## Seamless Multi-Cluster Communication and Observability with Linkerd

Max Körbächer from Liquid Reply provided a great breakdown of when it makes
sense to use multi-cluster. As he’s experienced in his client work,
organizations are increasingly considering
[multi-cluster](https://linkerd.io/service-mesh-glossary/#multi-cluster)
architectures; yet knowledge, complexity, security, and networking are common
application architecture pain points. Linkerd is great for multi-cluster use
cases and, based on an example, Max showcases how the service mesh has become
a lot easier to handle.

{{< youtube "X70Tb54Y-o4" >}}

## Keynote: Linkerd vs. COVID-19: Addressing the global Pandemic with a Service Mesh

In William Morgan's KubeCon keynote, he shares some examples of how organizations
like NIH, Clover Health, Penn State, and H-E-B, have been using Linkerd in
their effort to face COVID-19 challenges.

{{< youtube "S-7XbbJMonM" >}}

## Overview and State of Linkerd

KubeCon wouldn't be KubeCon without the “Overview and State of Linkerd”. William
Morgan and Matei David delivered a quick overview of the state of Linkerd, why
we are witnessing an increase in adoption, and what drives this great and
welcoming community. They discussed the problems the service mesh solves,
its continuous commitment to simplicity, as well as recent and upcoming features.

{{< youtube "ATUkfUwbBvo" >}}

This concludes part one of our Community Meeting recap. In part two,
we'll focus on Matei's multi-cluster with headless services presentation,
so stay tuned. And don't forget to
[register for our upcoming meeting](https://community.cncf.io/events/details/cncf-linkerd-community-presents-june-linkerd-online-community-meetup/)
on June 24 at 9 a.m. PT / 12 p.m. ET. We hope to see you there!
