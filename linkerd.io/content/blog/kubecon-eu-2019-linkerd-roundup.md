---
title: 'KubeCon EU 2019 Roundup'
author: 'william'
date: Fri, 30 May 2019 09:00:00 +0000
draft: false
tags: [Community, Linkerd, Kubecon]
thumbnail: kccnceu19-linkerd.jpg
---

![Linkerd at KCCNCEU19](/uploads/kccnceu19-linkerd.jpg)

Linkerd momentum was at an all-time high at last week's KubeCon EU! This was
the biggest Kubecon yet, with 7,500+ attendees, over 200 talks, and a huge
amount of Linkerd momentum. Here's a quick recap of all the Linkerd news that
was fit to print:

On Saturday, the folks at Kinvolk releases their [Linkerd
Benchmarks](https://linkerd.io/2019/05/18/linkerd-benchmarks/), comparing
Linkerd, Istio, and bare metal, and showing you the resource cost of adding the
service mesh to your infrastructure. The results may surprise you!

[![Linkerd benchmark graph](/uploads/600rps-latency-small.png)](/2019/05/18/linkerd-benchmarks/)

On Tuesday, Microsoft announced the [Service Mesh
Interface](https://linkerd.io/2019/05/24/linkerd-and-smi/), a specification
that exposes core service mesh features like telemetry, traffic shifting, and
policy via Kubernetes primitives. Linkerd was a major part of this launch, and
we're excited about the opportunities this opens up for us, especially around
integrations like [Kiali](https://www.kiali.io/),
[Flagger](https://github.com/weaveworks/flagger), and
[Kubecost](https://kubecost.com/)!

On Wednesday, the VSCode team launched a [Linkerd VSCode
plugin](https://marketplace.visualstudio.com/items?itemName=bhargav.vscode-linkerd),
adding cool Linkerd functionality to your local VSCode editor! (See the [talk
here](https://www.youtube.com/watch?v=fOvpMfunD4s#t=20m01s).)

During Kubecon, Digital Ocean's Kubernetes Service officially [went to GA
(General Availability)](https://blog.digitalocean.com/doks-in-ga/), with a
little hidden feature in the UI:

![Digital Ocean Linkerd screenshot](/uploads/digital-ocean-linkerd.png)

Finally, the Kubecon talks are already up on YouTube—if you couldn't make it,
never fear! Here's the full list:

- [Keynote: CNCF Project Update - Bryan Liles,
  VMware](https://youtu.be/vdxcaR3I2ic?t=359)
- [Why Your OSS Project Needs A GUI - Risha Mars,
  Buoyant](https://www.youtube.com/watch?v=gPUmeMcLrQ4)
- [Intro: Linkerd - William Morgan,
  Buoyant](https://www.youtube.com/watch?v=Z3nfLI3z0hc)
- [Scavenging for Reusable Code in the Kubernetes Codebase - Kevin Lingerfelt,
  Buoyant](https://www.youtube.com/watch?v=G8swjziYjY8)
- [What WePay Learned From Processing Billions of Dollar Using Linkerd - Mohsen
  Rezaei, WePay](https://www.youtube.com/watch?v=ph_NqGNHdhM)
- [Panel Discussion: Ask Us Anything: Microservices and Service
  Mesh](https://www.youtube.com/watch?v=101xw1RN3t4)
- [JustFootball’s Journey to gRPC + Linkerd in Production - Ben Lambert, Just
  Football & Kevin Lingerfelt,
Buoyant](https://www.youtube.com/watch?v=AxPfa7Mp_WY)
- [Grow with Less Pains - Meshing From Monolith to Microservices - Leo Liang,
  Cruise Automation](https://www.youtube.com/watch?v=sNRpfAZxD-A)
- [Building Cloud Native GDPR Friendly Systems for Data Collection - Zsolt
  Homorodi, VTT](https://www.youtube.com/watch?v=sKaeOApBPsw)
- [Autoscaling Multi-Cluster Observability with Thanos and Linkerd - Andrew
  Seigner, Buoyant & Frederic Branczyk, Red
Hat](https://www.youtube.com/watch?v=qTxunwzYO0g)
- [Deep Dive: Linkerd - Oliver Gould,
  Buoyant](https://www.youtube.com/watch?v=E-zuggDfv0A)
- [Dealing with the Pesky Path Parameter Problem: Service Profiles - Alex
  Leong, Buoyant](https://www.youtube.com/watch?v=yJ1AXO3eH10)

This was another great Kubecon for Linkerd. It was incredible to
meet so many enthusiastic and friendly people, and we can't wait to do it all
again this November in San Diego!

{{<tweet 1130789969293991936>}}
