---
date: 2021-08-16T00:00:00Z
title: July Linkerd Community Meeting Recap
description: |-
  The big news this month is Linkerd's CNCF graduation! As you can imagine, the
  entire Linkerd team is very excited and we hope you are too.
keywords: [community]
params:
  author: matei
  thumbnailRatio: fit
  videoSchema:
    - title: July Linkerd Community Meeting Recap
      description: |-
        The big news this month is Linkerd's CNCF graduation! As you can
        imagine, the entire Linkerd team is very excited and we hope you are
        too.
      embedUrl: https://youtu.be/DJ7iUM6aunw
      thumbnailUrl: http://i3.ytimg.com/vi/DJ7iUM6aunw/maxresdefault.jpg
      uploadDate: 2021-07-29
      duration: PT51M23S
---

It's time for our monthly Linkerd Community recap. Read the summary, watch
the recording, or both!

As usual, we started with a reminder of our
[Linkerd Community Anchor Program](/community/anchor/).
If you have a Linkerd story you'd like to share, we'd love to help you tell
it. Whether you built a cloud native platform with Linkerd or integrated
the service mesh with another CNCF project, these are all things that are
incredibly beneficial for the community!

We are also continuing to gather responses for our
[2021 Linkerd survey](https://docs.google.com/forms/d/e/1FAIpQLSfofwKQDOrAN9E9Vg1041623A3-8nmEAxlAbvXw-S9r3QnT9g/viewform).
To make Linkerd even more awesome, the Linkerd maintainers need to hear
from you. If you haven't done so yet, participate today — thank you!

## News and updates

The big news this month is Linkerd's CNCF graduation! As you can imagine,
the entire Linkerd team is very excited and we hope you are too. We wouldn't
have been able to do it without our great community!

As Linkerd moves closer to the 2.11 release, watch out for weekly edge
releases of up-and-coming features that will likely make the cut. These
include dependency updates, an even leaner control plane and extensions,
more granular metrics, and more.

In other updates: CloudCover released their
[scale benchmarking with Linkerd](https://cldcvr.com/news-and-media/blog/benchmarking-istio-consul-and-linkerd/),
Dependabot has been added to the Linkerd GitHub repositories, and we are
planning on more community engagement. Tweet us if you’d like to see
anything specific.

## Linkerd roadmap

The Linkerd team has been busy working on the 2.11 release. Ahead of the
new policy release, we've analyzed your feedback about improving integration
between certificate management and cert-manager. As part of this change, we
moved the trust anchors to a configmap. While this still requires some
integration work with cert-manager, it'll be a big step forward. By the way,
feedback like this is super valuable, so keep it coming!

We are also adding an SMI extension that will extend and manage TrafficSplits,
among other things. A nice addition to the new policy changes!

You'll also see StatefulSet support for multicluster. It's close to the finish
line and should be merged with the next edge release. To support this,
service-mirror, proxy, and destination controller have also been updated.

Our policy work is in full swing! Look out for a CRD and controller PR — our
first controller written in Rust! This expands the language usage outside of
the proxy and into the broader scope of the project. We are very excited
about that!

On the proxy side, we have two work "threads". One, to change how the inbound
proxy is configured to discover port-level authorization policies. The other
is around FIPS140-2 compliant work. We've been working on this with the folks
at NetApp for quite some time and can't wait to see it live. This requires some
changes to the TLS encryption algorithms, but it is necessary for regulatory
environments. It won't be enabled by default, instead, adopters will be able
to opt-in.

## Linkerd CNCF graduation

As mentioned above, Linkerd graduated! This is a reflection of how far the
project has come but it’s by no means a stopping point. If anything, it’s a
good time to reflect and move full speed ahead. While graduation does not
have an immediate effect on engineering, it reflects the mark of approval
from the Linux Foundation and confers a degree of certainty for adopters.
Congratulations to the community and the team!

## Community convo with Dom DePasquale

Dom DePasquale, Cloud Administrator at Penn State, shared the university's
Linkerd journey in a conversation with our own Charles Pretzer. Penn State's
engineering department, had been running Kubernetes and Linkerd in production
for a while. The team had adopted Linkerd for its
[mTLS](https://buoyant.io/mtls-guide/)
feature. All
communication coming into the cluster is TLSed. Once inside the cluster,
Linkerd takes over and encrypts service-to-service communication, a setup
that worked really well.

In 2020, when the pandemic hit, Dom and his team were tasked with building
a contact tracing system for COVID-19. Time and resources were limited,
so the natural choice for Dom’s team was to turn to open source software.

All COVID services were publicly hosted on EKS while the other services were
kept on-prem. To allow environments to talk to each other, the team relied
on ingress-to-ingress communication.

The platform Dom’s team built was also responsible for sending out invites
to students and faculty members to get tested. All of the invites were sent
on the same day in large batches of tens of thousands. The team observed an
increase in 502 status codes and wait time after sending each batch and,
with the increasing load, the system ground to a halt. Luckily, the team was
watching the whole situation unfold as it happened and could react quickly.

After some research, they identified the root cause: a component in the
identity system that relied heavily on unnecessary checks. Linkerd was
instrumental in troubleshooting and identifying the problem. To learn more,
watch Dom's ServiceMeshCon on how his team built a
[HIPAA-compliant testing and scheduling system with Linkerd](https://buoyant.io/media/how-linkerd-helped-schedule-68-000-covid-tests/).

Asked about what's missing in Linkerd, Dom said service-to-service RBAC.
Luckily, it's coming with the 2.11 release!

{{< youtube "DJ7iUM6aunw" >}}

## Maintainer deep dive: Alex and the Tapshark extension

Linkerd maintainer Alex Leong presented Tapshark, a Linkerd extension he
wrote. It was inspired by the Linkerd CLI command Tap which gives users a
running stream of live requests. While it's a great way to get forensic
information for debugging and understanding your system, the format and
volume of information make it hard to use effectively.

Tapshark is based on Wireshark’s format, one of Alex’s favorite debugging
tools. It allows users to see the information in different structures and
browse through requests within the terminal. It's a lot faster to drill
down into the data you need!

Tapshark is a client-side Linkerd extension, no need to deploy anything!
It uses the existing tap infrastructure and simply re-formats data to
highlight information faster — how genius is that!

When asked about how it relates to the debug sidecar, Alex explained it's
a bit different. While debug sidecar is useful for low-level forensics
(e.g. looking at sockets), Tapshark is better (and easier to use) for
high-level protocols like HTTP.

At the moment, Tap doesn’t show request bodies so Tapshark doesn’t either.
But it's on the roadmap, so expect to see it soon!

If this sounds interesting,
[give Tapshark a try](https://github.com/adleong/tapshark).
You can install it like any other
[Linkerd extension](/2.10/reference/extension-list/).

## Linkerd Hero

As always, we announced our Linkerd Hero. And the winner is...Sanskar
Jaiswal! Huge congrats to Sanskar. Check out
[why he won and why he's such a valuable community member](/2021/07/29/announcing-julys-linkerd-hero/).
Who is your Linkerd Hero?
[Submit your nomination today](https://docs.google.com/forms/d/e/1FAIpQLSfNv--UnbbZSzW7J3SbREIMI-HaooyX9im8yLIGB7M_LKT_Fw/viewform)!

That's it! Hope you can attend our next community meeting on Thursday,
August 26 at 9 a.m. PT live.
[Register today](https://community.cncf.io/events/details/cncf-linkerd-community-presents-august-linkerd-online-community-meetup/)!
