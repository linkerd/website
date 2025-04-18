---
date: 2021-03-17T00:00:00.000Z
title: February Linkerd Community Meeting Recap
description: |-
  From the 2.9.3 edge release to Linkerd-await (a wrapper for your apps and
  jobs) to protocol detection, we covered a lot of ground in the February
  meeting.
keywords: [linkerd]
params:
  author: charles
  thumbnailRatio: fit
---

If you missed our meeting last month, this recap and recording will bring you up to speed.

## Linkerd is testing the Discord waters

We've heard lots of great things about Discord and many other open source projects already moved to it, so we wanted to give it a try as well. [Join the Linkerd server](https://discord.com/invite/bE4sJBad), say hi, and let us know what you think.

## 2.9.3 edge release

Oliver Gould talked about Linkerd 2.9.3 which was released a little over a month ago. The release addressed two issues. The first involved upgrading, especially from 2.8 upwards, and preserving all configurations. The second focused on the proxy and compatibility between 2.8 to 2.9.  

If you want to upgrade from 2.8, especially to 2.10, the Linkerd team strongly recommends doing so from version 2.9. This will give you all the safety features needed to avoid downtime or interruptions when upgrading. Always upgrade from a major version to a major version to avoid any issues.

## Community member highlight: Richard Pijnenburg

Richard is a DevOps manager at FXC Intel, a London-based fintech company and also our [January's Linkerd Hero](https://linkerd.io/community/heroes/). He recently gave Linkerd-await a try – a new feature that we dive into later in this blog. But first, let's step back and meet Richard.

Richard has been involved with open source for about a decade. In his early days, he used Puppet, Elasticsearch, and wrote in Go. He has been heavily involved with the community since adopting Linkerd, enjoys spreading the open source gospel, and has spoken at numerous conferences and meetups. He's also really active in helping the community answering questions – a key reason why he was nominated Linkerd Hero in January. Helping others is how Richard learns. It's his way to get ahead of issues he may encounter in the near future – a great approach and win-win! Thanks, Richard, the whole community appreciates your time and effort!

### Discovering Linkerd

Any open source tool Richard used over the years always started with a work requirement. It wasn't any different with Linkerd. His team was moving their entire infrastructure to Kubernetes with a key requirement that security was fully embedded into the cluster and all traffic completely encrypted. They were also keen on doing traffic splits or canary deployments down the road.

Istio was an obvious service mesh option, but the setup experience was painful and Richard started looking for alternatives. That's how he discovered Linkerd. This service mesh was much easier to use, especially for the features important to his use case.  Mutual TLS and ease of use were a big driver for adopting Linkerd.

### Linkerd-await – a wrapper for your applications and jobs

Some of Richard’s applications are "connection initiating programs," not web servers waiting for requests. And because these apps launch very quickly, they try to initiate the connection before the proxy sidecar is ready. This led to apps exiting early and caused the pods to fail.

Richard started doing a little research. He needed something that would check the status of the sidecar proxy before his main application starts running. A big believer in keeping track of Slack discussions, Richard remembered Oliver posting something about a tool called Linkerd-await that could solve that problem..

Linkerd-await wraps a given application and waits for the Linkerd proxy to be ready before allowing it to start. This prevents conditions like Richard was experiencing and allows your applications to start the right way every time. Linkerd-await also has the ability to wrap processes used in Kubernetes jobs. This has the added benefit of allowing meshed jobs to terminate their pods gracefully when they finish their work.

An alternative to Linkerd-await would have been a custom script but Richard wanted to avoid taking on that maintenance burden. Finding a ready-made, and community-supported tool like Linkerd-await was a small breakthrough.

{{< youtube "DHQ7rTh8djM" >}}

### Next potential contribution

When asked what featured he'd like to contribute, Richard named two: The first one is certificate management. Certificates are hard for most people. Improving that documentation, including the steps and integration with existing tools like cert-manager, is something he'd love to do.  The second one are opaque ports including a documented list of all problematic services or an automated default list.

### Linkerd love

What does Richard appreciate most about Linkerd? He found the community great and very open. Everybody is happy to talk and all the feedback is appreciated. That's great to see in open source communities. "Linkerd is so easy to use. I think that's one of the biggest selling points. It's super easy to deploy and get going – without much pain."

## Protocol Detection and Opaque Ports in Linkerd

Charles shared a preview of his latest blog [Protocol Detection and Opaque Ports in Linkerd](https://linkerd.io/2021/02/23/protocol-detection-and-opaque-ports-in-linkerd/). Check it out to learn all about Linkerd 2.10 which added a new opaque ports feature that further extends its ability to provide zero-config mTLS for all TCP traffic.

## February's Linkerd Hero

Last but not least, we announced our[February Linkerd Hero](https://linkerd.io/community/heroes/), Sergio Mendéz.

Sergio is a very unique Linkerd Hero. An IT professor in Guatemala, Sergio exposed his students early on to cloud native technologies. By teaching them about cutting-edge tech and encouraging them to present in English, Sergio is not only building the next generation of cloud native programmers in Central America, he’s also opening the door to a global job market. If your students don’t see the value of it yet, they sure will for sure in the future, Sergio! Congrats, Sergio, you deserve it!
