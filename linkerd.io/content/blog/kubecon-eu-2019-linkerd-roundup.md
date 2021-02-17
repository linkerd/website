---
title: 'Linkerd at KubeCon EU 2019: Benchmarks, SMI, VSCode, and more'
author: 'william'
date: Fri, 31 May 2019 09:00:00 +0000
draft: false
featured: false
tags: [Community, Linkerd, Kubecon]
thumbnail: /uploads/kccnceu19-linkerd.jpg
---

![Linkerd at KCCNCEU19](/uploads/kccnceu19-linkerd.jpg)

Linkerd momentum was at an all-time high at last week's KubeCon EU! This was
the biggest Kubecon yet, with 7,500+ attendees, over 200 talks, and a huge
amount of Linkerd momentum. Here's a quick recap of most of the Linkerd news.

## Linkerd Benchmarks

On Saturday, the folks at [Kinvolk](https://kinvolk.io) published their
[Linkerd Benchmarks](https://linkerd.io/2019/05/18/linkerd-benchmarks/),
comparing Linkerd, Istio, and bare metal, and showing you the resource cost of
adding the service mesh to your infrastructure. The results may or may not
surprise you.

[![Linkerd benchmark graph](/uploads/600rps-latency-small.png)](/2019/05/18/linkerd-benchmarks/)

## Microsoft and Linkerd

On Tuesday, Microsoft announced the [Service Mesh
Interface](https://smi-spec.io), a specification that exposes core service mesh
features like telemetry, traffic shifting, and policy via Kubernetes primitives.
[Linkerd was a major part of the SMI
launch](https://linkerd.io/2019/05/24/linkerd-and-smi/), and we're excited about
the opportunities this opens up for us, especially around integrations like
[Kiali](https://www.kiali.io/),
[Flagger](https://github.com/weaveworks/flagger), and
[Kubecost](https://kubecost.com/)!

On Wednesday, the VSCode team launched a [Linkerd VSCode plugin][vscode],
adding cool Linkerd functionality to your local VSCode editor! (See the [talk
here](https://www.youtube.com/watch?v=fOvpMfunD4s#t=20m01s).)

## DigitalOcean and Linkerd

Right in the middle of Kubecon, Digital Ocean's Kubernetes Service officially
[went to GA (General Availability)](https://blog.digitalocean.com/doks-in-ga/),
with a little hidden feature in the UI:

![Digital Ocean Linkerd screenshot](/uploads/digital-ocean-linkerd.png)

## OpenFaaS integration

One of the exciting hot topics at the conference was the
[OpenFaaS](https://www.openfaas.com/) Linkerd integration, allowing OpenFaaS
users to automatically encrypt communication between functions! (You can read
[the full guide
here](https://github.com/openfaas-incubator/openfaas-linkerd2).)

{{< tweet 1129105603354333184 >}}

## And, of course, lots and lots of talks!

As always, there was a long list of Linkerd talks at Kubecon If you couldn't
make the conference in person, never fear, the recordings are already live.

- [Keynote: CNCF Project Update w/Linkerd](https://youtu.be/vdxcaR3I2ic?t=359):
  Bryan Liles, VMware
- [Lightning talk: Why Your OSS Project Needs A
  GUI](https://www.youtube.com/watch?v=gPUmeMcLrQ4): Risha Mars, Buoyant
- [Intro to Linkerd](https://www.youtube.com/watch?v=Z3nfLI3z0hc): William
  Morgan, Buoyant
- [Scavenging for Reusable Code in the Kubernetes
  Codebase](https://www.youtube.com/watch?v=G8swjziYjY8): Kevin Lingerfelt,
Buoyant
- [What WePay Learned From Processing Billions of Dollars Using
  Linkerd](https://www.youtube.com/watch?v=ph_NqGNHdhM): Mohsen Rezaei, WePay
- [JustFootball’s Journey to gRPC + Linkerd in
  Production](https://www.youtube.com/watch?v=AxPfa7Mp_WY): Ben Lambert, Just
Football & Kevin Lingerfelt, Buoyant
- [Grow with Less Pains: Meshing From Monolith to
  Microservices](https://www.youtube.com/watch?v=sNRpfAZxD-A): Leo Liang,
Cruise Automation
- [Building Cloud Native GDPR Friendly Systems for Data
  Collection](https://www.youtube.com/watch?v=sKaeOApBPsw): Zsolt Homorodi, VTT
- [Autoscaling Multi-Cluster Observability with Thanos and
  Linkerd](https://www.youtube.com/watch?v=qTxunwzYO0g): Andrew Seigner,
Buoyant & Frederic Branczyk, Red Hat
- [Deep Dive: Linkerd](https://www.youtube.com/watch?v=E-zuggDfv0A): Oliver
  Gould, Buoyant
- [Dealing with the Pesky Path Parameter Problem: Service
  Profiles](https://www.youtube.com/watch?v=yJ1AXO3eH10): Alex Leong, Buoyant

## Wrapping it all up

This was another great Kubecon for Linkerd. It was incredible to meet so many
enthusiastic and friendly people, and we can't wait to do it all again this
November in San Diego!

{{< tweet 1130789969293991936 >}}

{{< tweet 1131493061916319744 >}}

{{< tweet 1130810652862373889 >}}

---

Linkerd is a community project and is hosted by the [Cloud Native Computing
Foundation](https://cncf.io). If you have feature requests, questions, or
comments, we'd love to have you join our rapidly-growing community! Linkerd is
hosted on [GitHub](https://github.com/linkerd/), and we have a thriving
community on [Slack](https://slack.linkerd.io),
[Twitter](https://twitter.com/linkerd), and the [mailing
lists](https://linkerd.io/2/get-involved/). Come and join the fun!

[vscode]: https://marketplace.visualstudio.com/items?itemName=bhargav.vscode-linkerd
