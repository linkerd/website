---
title: Announcing the Linkerd Ambassador program
description: |-
  Linkerd Ambassadors are community members who have demonstrated passion,
  engagement, and a commitment to sharing their Linkerd experience.
date: 2021-08-05T00:00:00Z
keywords: [community]
params:
  author: catherine
---

Hot on the heels of Linkerd's CNCF graduation, we are very excited to announce
the [Linkerd Ambassador Program](https://linkerd.io/community/ambassadors/)!

The Linkerd Ambassador badge is a distinction awarded to those community
members who are experts in their field and who demonstrate passion,
engagement, and a commitment to sharing their Linkerd experience with the
broader community. Linkerd Ambassadors are hand-picked by the Linkerd
maintainers.

## Meet the Linkerd Ambassadors

### Chris Campbell, Cloud Software Engineer 🇺🇸

Currently employed by Shopify, Chris was previously the lead architect of the
cloud infrastructure platform at HP working initially with HP JetAdvantage
solutions and then HP's print business. During that time, Chris played an
integral role in the company’s digital transformation journey.

Chris "discovered" the service mesh early on. Around 2015,  he first started
playing with Linkerd 1. At the time, his goal was to integrate microservices
with Consul, without needing to write a bunch of app code. He loved the design
pattern and found many other use cases for it. But it wasn’t until 2018, when
Chris became the infrastructure lead for a device management solution, that
his team adopted Kubernetes.

Chris' team successfully used Linkerd for automated canary deployments, golden
signal tracking, mTLS, retries, timeouts, and overall "smarter" routing between
services. Today, the team relies heavily on Linkerd's application-level metrics
and wouldn't know how to operate without it.

Chris gets particularly excited about technology that makes him more effective
at delivering cloud services. In the past, he has enjoyed working with Docker,
Kubernetes, Terraform, Golang, and, of course, Linkerd.

When asked about the program, Chris said "I'm super excited about the Linkerd
Ambassador Program. This is an incredibly special project, made of great tools
and led by honest hardworking individuals. I'm honored to be a part of it."
And so are we, Chris!

### Christian Hüning, Director of Cloud Technologies 🇩🇪

Christian and his team at finleap connect, built a GDPR-compliant cloud native
platform for the company's highly regulated OpenBanking and Switchkit products.
Operating in the financial services industry, finleap connect's applications
must meet the highest security standards, including full traffic encryption and
visibility. Today, the platform runs over 5,000 meshed services achieving four
nines of availability. Check out Christian's KubeCon talk on his team achieved
[compliance with zero-conf mTLS](https://buoyant.io/media/compliance-with-zero-conf-mtls-day-2/).

In 2018, the team explored service meshes as a way to enable mTLS between all
services. Initially, they considered Istio but it was too hard to set up. Then,
they discovered a mesh called "Conduit" (Linkerd 1). After a few interactions
with the Conduit team on Slack they discovered that some of the key features
they would need in the future were on the product roadmap. In early 2019,
they formally adopted Linkerd. They loved the solution and Christian's team
has been keen Linkerd users and contributors ever since.

With Linkerd, observability increased, load balancing improved, all services
automatically have mTLS, and, in some cases, they even prevented config errors
in certain load-balancing scenarios. Thanks to Linkerd's simple setup, Christian
and team were able to deliver the cloud native transformation project on time.

Christian is passionate about the cloud native community and what it enables
them to do. "It's exciting to see how people around the world collaborate to
improve, not only our technical solutions but the cloud native community as a
whole. I really enjoy being part of that community — it's invigorating and fun."

### Fredrik Klingenberg, Developer 🇳🇴

Fredrik’s life work is helping organizations adopt cloud native technologies.
Client engagements include Elkjøp, Hafslund Nett, and If Insurance among others.
A recent success story was Elkjøp's Next Generation Retail (NGR) project,
involving building two new Kubernetes-based platforms: a new point of sales app
used by all in-store sales reps across Scandinavia and an app to host all
microservices. With Frederik’s help, Elkjøp modernized its architecture,
processes, as well as app development and maintenance. Elkjøp estimates that
the new platforms will save them over 90% in hosting cost — pretty impressive!
You can learn all about it in
[Fredrik's CNCF blog](https://www.cncf.io/blog/2021/02/19/how-a-4-billion-retailer-built-an-enterprise-ready-kubernetes-platform-powered-by-linkerd/).

Fredrik first learned about the service mesh in 2019 while collaborating
with Microsoft on several projects. Microsoft has been a trusted
partner for Fredrik for a while and he often shares his experience at
various Microsoft events.

The biggest impact Linkerd has had for Frederik’s clients (at least from
his perspective) is that it significantly reduced MTTR by providing a good
baseline on network insight.

Fredrik is most passionate about "helping customers think more about systems
and less about individual applications."

### Sergio Méndez, DevOps Engineer 🇬🇹

Sergio — or "the professor" as we like to call him — has made it his
mission to build the next generation of cloud native engineers in Latin
America. Passionate about the entire ecosystem, Sergio exposes his students
to emerging technologies early on. The professor and his students are
frequent speakers at KubeCon, CNCF live streams, and meetups, where they
share lessons learned. Most recently, Sergio and Jossie Castrillo presented
Jossie's thesis results on
[how Linkerd complements Chaos Mesh well for chaos engineering experiments](https://buoyant.io/media/chaos-in-the-university-with-linkerd-and-chaos-mesh/).
"It's awesome how CNCF technologies can open the doors for Central American
youth!" says Sergio.

Sergio is also a DevOps Engineer at Yalo where he works on Kubernetes-based
WhatsApp chatbots. You may have seen his KubeCon talk on
[chatbots he built for a large Central American telco based on Kubernetes, OpenFaaS, and Linkerd](https://buoyant.io/media/serverless-chatbots-linked-kubernetes-opensaas/).

In his operating system course at San Carlos University of Guatemala,
Sergio uses a variety of cloud native technologies to provide students
with hands-on experience before they enter the job market. Their
latest project is based on Kubernetes, Linkerd, and Chaos Mesh
([check out their repo](https://github.com/sergioarmgpl/operating-systems-usac-course)).

A professor focused on cloud native technology, Sergio discovered the
service mesh on the cloud native landscape. Initially, he looked into
Istio but his attention quickly shifted towards Linkerd which seemed
much simpler and did not require a huge learning curve.

Sergio loves working with students and sharing his experience with cloud
native technologies. "I love to participate in the communities as a way to
meet people around the world. Thanks, Linkerd for this awesome journey
using service meshes."

### Steve Gray, Head of Trading Solutions 🇦🇺

Steve and his team at Entain Australia built a modern, cloud native trading
platform based on Kubernetes, gRPC, and Linkerd. These tools allowed them to
build a high-performance, reliable, and scalable system. Learn more about this
project in
[Steve's CNCF blog](https://www.cncf.io/blog/2021/04/19/when-lebron-scores-latency-matters-realizing-10x-throughput-while-driving-down-costs-and-sleeping-through-the-night/).

Steve first heard about service meshes when he stumbled over one of
William's YouTube videos a few years back. But it was only a year ago
that his team started adopting the service mesh. The impact was huge!
It improved performance and scalability while reducing operating costs.

Steve is passionate about architecture and microservices design and sharing
his experience with others. He particularly enjoys engaging with peers to
demonstrate how his team has adopted cloud native technologies. If you're
based in the Brisbane, Australia, area and are looking for a cloud native
enthusiast willing to share lessons learned (and pitfalls),
[hit him up on LinkedIn](https://www.linkedin.com/in/eventualconsistency/).
He may well invite you to the office or a one-on-one Zoom call.

An avid ice hockey player, skater, and snowboarder, Steve also really enjoys
traveling. "The second international travel is back on the menu,
I’m off to Japan!"

## Welcome everyone!

Each one of these innovators have been unofficial Linkerd Ambassadors for a
while, sharing their expertise at various conferences, in blog posts, on Slack,
and social media. Today, we want to officially recognize and thank them for
their amazing community engagement. The Linkerd community is incredibly lucky
to have such amazing members!
