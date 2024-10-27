---
title: September Linkerd community meeting recap 
description: |-
  The Linkerd 2.11 docs are live and you'll see lots of small changes. The
  Linkerd team and the community have been working on 2.11 since May.
date: 2021-10-26T00:00:00Z
keywords: [meetup, community, meeting]
params:
  author: matei
  thumbnailProcess: fit
  videoSchema:
    - title: September Linkerd community meeting recap 
      description: |-
        The Linkerd 2.11 docs are live and you'll see lots of small changes.
        The Linkerd team and the community have been working on 2.11 since May.
      embedUrl: https://youtu.be/rVpiUC08bgs
      thumbnailUrl: http://i3.ytimg.com/vi/rVpiUC08bgs/maxresdefault.jpg
      uploadDate: 2021-10-01
      duration: PT53M51S
---

Delayed slightly due to KubeCon, our Linkerd Community Meeting recap and
recording are now live.

Before we get started — as usual — a quick reminder of our
[Linkerd Community Anchor Program](https://linkerd.io/community/anchor/).
If you have a Linkerd story you’d like to share, we’d love to help you
tell it. Whether you built a cloud native platform with Linkerd or
integrated the service mesh with another CNCF project, these experiences
are incredibly beneficial for the community!

We are also continuing to gather responses for our
[2021 Linkerd survey](https://docs.google.com/forms/d/e/1FAIpQLSfofwKQDOrAN9E9Vg1041623A3-8nmEAxlAbvXw-S9r3QnT9g/viewform).
So, if you haven’t done so yet, participate today — thank you!

## Roadmap

The [Linkerd 2.11 docs](https://linkerd.io/2.11/overview/)
are live and you'll see lots of small changes. The Linkerd team and the
community have been working on 2.11 since May. Changes include more robust
iptables rules, reduced proxy and memory CPU usage (in load testing),
and, finally, the introduction of policy! The latter is the big change
we are all particularly proud of.

While the plan for 2.12 is not fully fleshed out and scoped into issues,
we will work on client-side policies like deprecated (or improved)
ServiceProfiles. These will allow us to do cool stuff like circuit breaking.
With the SMI extension, we will be looking at removing TrafficSplits from
core Linkerd and introducing (potentially) new resources.

It's a great time to get involved! We'll post new issues soon and there will
be plenty of opportunities to help shape the Linkerd project. Stay tuned and
look out for those issues, your help really makes a difference!

## Policy demo

As mentioned above, policy is one of the features that shipped with 2.11.
Charles demoed this long-awaited and powerful capability. To replicate it, just
[follow the instructions in the docs](https://linkerd.io/2.11/features/server-policy/).

Policy allows you to control which connections a server accepts. Generally,
policy is focused on enforcing mTLS and typical use cases are in multi-tenancy
environments and for regulatory compliance.

Policies can be applied on the cluster or per workload, including namespaces
and pods. When installing Linkerd, you have a set of default policies which
can be applied on a workload-by-workload basis. You may also create policies
specifically for a pod through two new resources: Servers and Server
Authorizations.

Here's how it works: A server selects pods by labels and matches ports on
those pods. Server Authorization selects a server and specifies whether
mTLS is mandatory and what clients are permitted. Check out a Kubernetes
engineer’s [guide to mTLS](https://buoyant.io/mtls-guide/) to learn more.

{{< youtube rVpiUC08bgs >}}

## Deep dive with Eliza: Retries with message bodies

Eliza, a core maintainer of the proxy, walked us through how Linkerd retries
HTTP requests with bodies — another new 2.11 feature. Retrying requests
with bodies is especially important for anyone using Linkerd with gRPC:
since all gRPC requests are HTTP/2 `POST` requests with bodies, this feature
enables retries to be configured for gRPC traffic. To learn more about it,
check out [Eliza’s writeup on retries with message bodies](https://linkerd.io/2021/10/26/how-linkerd-retries-http-requests-with-bodies/).

## September Linkerd Hero

Last, but not least, we announced our Linkerd Hero, Ujjwal Goyal. An
enthusiastic Linkerd contributor, Ujjwal raised issues and contributed
code to the website repository and Linkerd’s multicluster capabilities.
Ujjwal also helps spread the Linkerd message and provides awesome
tweet-length summaries of different Linkerd events! Because lots of small
contributions really add up, the
[maintainers nominated Ujjwal](https://linkerd.io/2021/09/30/announcing-septembers-linkerd-hero/).

Who is your Linkerd Hero?
[Submit your nomination today](https://docs.google.com/forms/d/e/1FAIpQLSfNv--UnbbZSzW7J3SbREIMI-HaooyX9im8yLIGB7M_LKT_Fw/viewform)!

That’s it! Hope you can attend our next community meeting on Thursday,
October 28 at 9 a.m. PT live.
[Register
today](https://community.cncf.io/events/details/cncf-linkerd-community-presents-october-linkerd-online-community-meetup/)!
