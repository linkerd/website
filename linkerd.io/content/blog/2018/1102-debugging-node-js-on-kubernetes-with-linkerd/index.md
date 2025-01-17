---
date: 2018-11-02T00:00:00Z
slug: debugging-node-js-on-kubernetes-with-linkerd
title: Debugging Node.js on Kubernetes with Linkerd
keyword: [community, events, linkerd, news]
params:
  author: kiersten
---

A few weeks ago, at [Node+JS Interactive](https://events.linuxfoundation.org/events/node-js-interactive-2018/), our friend Brian Redmond of Microsoft Azure gave an excellent talk that used Linkerd 2.0 to identify the source of failures in a Node app.

In this talk, Brian explained why debugging Node apps is no trivial task on Kubernetes. In Brian’s demo app, which pulls in earthquake, flight, and weather data into real-time interactive maps, is made of three services (running on Azure). Each service runs on three Kubernetes pods. Brian describes why this fairly standard setup can already be complex for debugging, and how standard approaches like tailing log files rapidly break down when requests are split across pods and services.

Brian demoed how Linkerd’s UNIX-style CLI tools (e.g. `linkerd tap`, `linkerd top`, and `linkerd stat`) can be used to trace the source of failure to a bad database response in the earthquake API, dramatically reducing the “mean time to clue”. He also talked at length about how service meshes are being used today.  Check out the video and tell us what you think, and kudos to Brian for a compelling demo!

{{< youtube sJVV0GFYz7k >}}
