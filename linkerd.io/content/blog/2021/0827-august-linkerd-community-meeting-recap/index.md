---
date: 2021-08-27T00:00:00Z
title: August Linkerd Community Meeting Recap
description: |-
  We are pushing towards the 2.11 release and our next edge release is the first
  with policy support! We recently updated our ingress documentation which will
  hopefully result in an easier getting-started process.
keywords: [linkerd, community]
params:
  author: kevinl
  thumbnailRatio: fit
---

If you missed our August Community Meeting, don't worry, here's the recap along
with the recording.

Before we get started, just a quick reminder of our
[Linkerd Community Anchor Program](/community/anchor/). If you have a Linkerd
story you’d like to share, we’d love to help you tell it. Whether you built a
cloud native platform with Linkerd or integrated the service mesh with another
CNCF project, these are all things that are incredibly beneficial for the
community! We are also continuing to gather responses for our
[2021 Linkerd survey](https://docs.google.com/forms/d/e/1FAIpQLSfofwKQDOrAN9E9Vg1041623A3-8nmEAxlAbvXw-S9r3QnT9g/viewform).
So, if you haven’t done so yet, participate today — thank you!

## News & Updates

We are pushing towards the 2.11 release and our next edge release is the first
with policy support! We recently updated our ingress documentation which will
hopefully result in an easier getting-started process. We are also currently
updating the
[CNCF Linkerd training course](https://www.edx.org/course/introduction-to-service-mesh-with-linkerd)
to reflect the extension model introduced in 2.10.

Here's some fun news: after Linkerd's graduation, we are getting a mascot. We
already got a sneak peek and love it! Stay tuned for the big unveiling at
KubeCon!

## Roadmap

We’re mostly focused on getting policy shipped for 2.11. The CRDs, policy
controller (first Rust code to appear in the control plane), and proxy support
for discovering policy have all been completed. This week’s edge will better
support HTTP and metrics. The remaining work mostly involves wiring up the
recently added metric labels and lots of testing.

And please, please try the latest edge and test it as much as you can! Give
policy a spin and let us know if anything does not make sense or if you have any
suggestions. Your feedback is super important and helpful!

## Community Conversation with Chris Campbell & Dan Duggan

Chris and Dan worked together in cloud architecture roles at HP (Chris recently
switched jobs). Both started their DevOps journey together working on a frontend
app where they quickly realized they needed to adopt a lot of industry best
practices.

The migration from monolith to microservices started because HP was making a
general move from delivering hardware to software. It started about five years
ago and is still ongoing. The initial course of action was moving to Docker
Swarm — that was fairly quick. But, given HP's size, the rest took (and is still
taking) some time.

The service mesh became relevant when Chris and Dan were trying to understand
what was happening within their microservices. Why are things breaking? How
could they get better information at the infrastructure level? They quickly
understood that proxies would play an important role in gathering that type of
data. Already familiar with Linkerd 1, they felt comfortable adopting Linkerd2.

In their experience, as the space continues to grow, it has become harder to
describe the role of the service mesh and its value to stakeholders. Initially,
it was a lot easier. Service meshes had fewer features that focused on a very
specific value proposition. At the time, it was clear the service mesh filled a
key role in the migration process and, at least in their case, wasn't a hard
sell. But with all the hype and additional features, that conversation feels
more difficult today.

If they could add any feature to Linkerd, Chris would like to have a better way
to expose tap to cluster operators and policy (the latter is coming soon).
Additionally, exposing how many retries are occurring in the system and what
percentage of traffic they represent would be super valuable.

{{< youtube vujvDltxmhg >}}

## Deep Dive with Alejandro: Updating Helm Charts

Before getting started, please note that these updates **will not** make it into
2.11. But they are coming soon, so stay tuned. The driver for the Helm chart
changes Alejandro discussed has been the upgrade from Helm v2 to v3.

In Helm v3 it is best to leave the responsibility of namespace creation to Helm
rather than providing one through the chart. This allows the chart’s Helm config
to be stored in the relevant namespace instead of the default namespace.

Moving forward, Linkerd and its extensions will adopt this best practice which
means namespaces will be removed from each of these charts. Because extension
namespaces require specific labels to work properly, there will be
post-installation hooks that add the additional metadata. Lastly, the core
install chart will be split into two—one that contains CRDs (TrafficSplit,
ServiceProfile, Server, ServerAuthorization) and one that contains the core
components (destination, identity, proxy injector).

Why? Well, CRDs must be available before their resources are created. If any of
these resources are included in the core install — such as Servers and
ServerAuthorizations — the cluster must know about their definitions beforehand.
As mentioned, we'll have to be a little patient to see these changes implemented
but it's coming soon.

## August Linkerd Hero

Last, but not least, we announced our Linkerd Hero Dom DePasqual. Dom and his
team at Penn State
[used Linkerd to schedule 68,000 COVID tests](http://buoyant.io/media/how-linkerd-helped-schedule-68-000-covid-tests/)
and he shared his Linkerd journey at this year's ServiceMeshCon EU. Because
sharing lessons learned with the community is so important,
[the maintainers nominated Dom](/2021/08/26/announcing-augusts-linkerd-hero/).

Who is your Linkerd Hero?
[Submit your nomination today](https://docs.google.com/forms/d/e/1FAIpQLSfNv--UnbbZSzW7J3SbREIMI-HaooyX9im8yLIGB7M_LKT_Fw/viewform)!

That’s it! Hope you can attend our next community meeting on Thursday, September
30 at 9 a.m. PT live.
[Register today](https://community.cncf.io/events/details/cncf-linkerd-community-presents-september-linkerd-online-community-meetup/)!
