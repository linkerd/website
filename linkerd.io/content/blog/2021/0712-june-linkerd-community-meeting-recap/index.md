---
date: 2021-07-12T00:00:00Z
title: June Linkerd Community Meeting Recap
description: |-
  Missed the June Linkerd Community Meeting? Here's our recap and the full
  recording.
keywords: [community]
params:
  author: charles
  thumbnailRatio: fit
  videoSchema:
    - title: June Linkerd Community Meeting Recap
      description: |-
        Missed the June Linkerd Community Meeting? Here's our recap and the full
        recording
      embedUrl: https://youtu.be/jcnnblzMcP8
      thumbnailUrl: http://i3.ytimg.com/vi/jcnnblzMcP8/maxresdefault.jpg
      uploadDate: 2021-06-24
      duration: PT52M12S
---

Missed the June Linkerd Community Meeting? Here's our recap and the full
recording.

## News and updates

First and foremost, Linkerd was in the
[public comment period for CNCF graduation](https://lists.cncf.io/g/cncf-toc/message/5917)
— the penultimate step in the graduation process. And is, since today,
[now open for graduation votes](https://lists.cncf.io/g/cncf-toc/message/5966).

In terms of upcoming Linkerd features: server-side policy is the big ticket item
in the upcoming 2.11 release, so please keep providing feedback. We are also
currently cleaning up proxy dependencies; the work is mostly done and should
make new dependency updates easier moving forward.

## Community convo with Sol Roberts from PlexTrac

Sol Roberts from PlexTrac shared his Linkerd story. After initially consulting
with PlexTrac years ago, Sol was onboarded to run their SRE practice. Under his
guidance, the team moved from Docker Compose to Kubernetes. They also added
useful tooling including Helm to simplify deployments, and Linkerd to provide
mTLS.

Over time, Linkerd proved itself to be useful for more than just mTLS and
PlexTrac took advantage of the observability and reliability features. Sol
shared a great story about hunting down and remediating a production issue using
Linkerd’s tap feature.

## Deep dive with Dennis: Shell completion in the CLI

Linkerd maintainer Dennis talked about adding shell completion in the CLI. In
prior Linkerd CLI versions, shell completion was fairly limited in that users
were unable to get autocomplete suggestions based on resources within a cluster.
Fortunately, [Cobra](https://github.com/spf13/cobra), a Go CLI library, provided
a way to make shell completion work similar to kubectl’s shell completion. Cobra
simplifies the addition of this functionality without the need to manually write
custom shell completion scripts. Cluster-resource-aware shell completion is now
available on the latest Linkerd edge releases, so please try it out!

## Linkerd Heroes

Last but not least, we announced
[June's Linkerd Heroes: Steve Gray and Steve Reardon](/2021/06/24/announcing-junes-linkerd-heroes/).
If you'd like to nominate someone for next month,
[please do so here](https://docs.google.com/forms/d/e/1FAIpQLSfNv--UnbbZSzW7J3SbREIMI-HaooyX9im8yLIGB7M_LKT_Fw/viewform)!
We love each and every opportunity to publicly celebrate the community members
who make Linkerd great. Want to be part of the action? Don't forget to join us
for our
[next Community Meetup](https://community.cncf.io/events/details/cncf-linkerd-community-presents-july-linkerd-online-community-meetup/)
on Thursday, July 29 at 9 am PT!

{{< youtube jcnnblzMcP8 >}}
