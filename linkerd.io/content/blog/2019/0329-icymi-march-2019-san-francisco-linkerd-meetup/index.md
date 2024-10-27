---
title: |-
  ICYMI: March 2019 San Francisco Linkerd Meetup
date: 2019-03-29T00:00:00Z
params:
  author: kiersten
---

Earlier this week we kicked off our very first [San Francisco Linkerd Meetup](https://www.meetup.com/San-Francisco-Linkerd-Meetup/). It was a fun night filled with education, great food, and lots of good conversation. If you missed it, never fear: all the talks were recorded!

## Talk 1: What is Linkerd?

{{< youtube "90jnPXk3iCs" >}}

In this talk, William Morgan, Linkerd maintainer, provides a short introduction into Linkerd, and explains how you can use Linkerd for runtime debugging, observability, reliability, and security—all without changes to your code. He shares the history of the project and the latest design principles around Linkerd 2.x.

## Talk 2: Multi-cluster observability with Kubernetes, Linkerd, and Thanos

{{< youtube "hKqZP6RGKP0" >}}

In this talk, Andrew Seigner, software engineer at Buoyant and Linkerd maintainer, spoke about multi-cluster observability with Kubernetes, Linkerd, and Thanos. Andrew demonstrates how to add observability to applications across multiple Kubernetes clusters with zero code changes, and then uses Thanos to enable observability across all clusters in one unified view. He outlines how Linkerd uses Prometheus to provide zero-config observability for applications running in Kubernetes, and how Thanos enables observability to scale across any number of Prometheus instances. He concludes with a demo of installing Linkerd onto a Kubernetes cluster, injecting Linkerd into sample apps across 4 cluster cloud providers, and aggregating metrics into a single Thanos Querier.

The Linkerd-Thanos demo can be found [here on GitHub](https://github.com/linkerd/linkerd-examples/tree/master/thanos-demo).

## Talk 3: Linkerd at Strava in production

{{< youtube "f0q_Vw4dAuE"  >}}

In this talk, J Evans, Infrastructure Engineer at Strava describe Strava’s real-world use case for Linkerd. Strava has been running Linkerd in production for over a year, and almost every internal app uses it for service discovery and routing. From incident response workflows to candidate deployments, Linkerd plays an integral part throughout Strava’s infrastructure stack. J describes how Strava uses Linkerd’s Prometheus and Statsd integrations to respond to service outages, and how these observability tools along with other Linkerd features can even be used to avoid such outages in the first place.

---

The [San Francisco Linkerd Meetup](https://www.meetup.com/San-Francisco-Linkerd-Meetup/) group is a gathering spot for like-minded developers and engineers of all skill levels who are interested in Linkerd, the open source service mesh. Join us now! Want to give a talk, or have a venue in SF that can host this meetup? Please email events@buoyant.io!
