---
date: 2024-10-23T00:00:00Z
slug: making-linkerd-sustainable
title: Towards a Sustainable Service Mesh
keywords: [linkerd]
params:
  author: william
  showCover: true
---

Open source covers a vast spectrum of projects, but they all face the same
existential threat: what ensures this project will be maintained in the future?
Today, Linkerd adopters can be confident they're getting the world's simplest,
fastest, lightest service mesh. Can they be confident they're getting a project
that will be around tomorrow? Another decade?

These are not theoretical questions. The past 18 months alone have provided many
examples of just how fragile open source can be:

* In February, Weaveworks, the company behind much of the Gitops movement,
  [shut its
  doors](https://thenewstack.io/end-of-an-era-weaveworks-closes-shop-amid-cloud-native-turbulence/),
  temporarily leaving the fate of the widely-used CNCF-graduated Flux project in
  doubt.
* In March, Redis, a well-established infrastructure project, [changed its
  licenses to move away from open
  source](https://redis.io/blog/redis-adopts-dual-source-available-licensing/),
  following a [similar license change by
  Terraform](https://www.hashicorp.com/blog/hashicorp-adopts-business-source-license)
  a year earlier.
* Last year, Open Service Mesh, a CNCF service mesh project created, maintained,
  and marketed heavily by Microsoft, [shut down
  entirely](https://openservicemesh.io/blog/osm-project-update/), its
  maintainers reassigned to other projects.

Being a CNCF project—even a graduated one—offers no protection. The CNCF does
not step in to rescue dying projects. Nor does the backing of a trillion-dollar
company; nor a happy and robust community. Each project must find its own answer
to this question.

To this end, in February [we announced a significant change to
Linkerd](https://linkerd.io/2024/02/21/announcing-linkerd-2.15/). We would no
longer publish stable release packages as part of the open source project.
Instead, we would rely on the vendor ecosystem for that work. The change itself
was a small simplification of the project, but the goal behind it was very
large: **to ensure Linkerd could become a truly sustainable project, without
relicensing, without violating CNCF rules, and without changing Linkerd's
fundamental open source nature.**

We made this change the only way we thought was truly realistic: by building a
clear economic path from the companies that build their businesses on top of
Linkerd, to the vendors who employ, today, 100% of the Linkerd maintainers.

Did it work?

## The Linkerd community is amazing

Yes. Today, we can confidently state that the future of Linkerd is very bright.
You can read [Buoyant's full announcement
here](https://buoyant.io/blog/linkerd-forever).

We first need to start with a giant *thank you* to the Linkerd community. Since
our announcement, we've had countless conversations with adopters who understood
the criticality of what we were trying to do and why it made sense for them; who
told us they had our backs; who took this leap of faith with us.

Since making this change, the Linkerd team has gained both maintainers and
momentum, achieving milestone after milestone:

* We've shipped many features that have been languishing in the backlog,
  including support for IPv6, authorization policy audit mode, and bringing our
  Gateway API implementation to feature parity with ServiceProfiles.
* We've delivered a new implementation of retries, timeouts, and per-route
  metrics—some of the earliest code ever shipped in Linkerd—that fixes some
  long-standing corner case behavior in these features.
* We've made significant progress on both egress functionality, rate limiting,
  and Open Telemetry support, all long-awaited features to be delivered in the
  upcoming Linkerd 2.17 release.
* We've added a search bar to linkerd.io docs. (Sometimes it's the little
  things!)
* We've hit 10,000 community Slack members :)

We've also significantly improved our edge release process to make edge
artifacts easier to consume, providing both [post-hoc
guidance](https://github.com/linkerd/linkerd2/releases) about each release as
well as [monthly
roundups](https://linkerd.io/2024/09/06/linkerd-edge-release-roundup/). As we
hoped, this is has dramatically increased the speed of bugfixes for
adopter-reported issues (see e.g.
[#12610](https://github.com/linkerd/linkerd2/issues/12610)).

## Linkerd gets more maintainers

We're very happy to report that Buoyant is adding maintainers to Linkerd to
further increase the pace of development.

Two new maintainers (technically, still maintainers-in-training) have already
joined the team. They are both increasing project bandwidth where we need it
most: in Linkerd's Rust microproxy, the nuclear engine behind Linkerd's entire
feature set. The proxy is the key to Linkerd's stellar performance and
simplicity, but it's also the most challenging part of the project to work on.
Linkerd's microproxy is one of the most advanced Rust codebases in the world,
and being able to operate effectively here requires an extremely high caliber of
talent.  These incredible folks will be working full time on making Linkerd's
dataplane even faster, even lighter, and even more featureful.

And that's just the beginning.

## Our advice to other CNCF projects

Shortly after our announcement, multiple CNCF maintainers reached out to us
privately, wondering if a similar change might make sense for them.

Our answer today is "probably". While open source projects can have dramatically
different needs, constraints, and communities, many CNCF projects have a set of
characteristics that we believe makes this type of release-artifact-focused
change effective:

* **The project is primarily used in commercial contexts.** Many CNCF projects,
  like Linkerd, have a community that is primarily there on behalf of their
  employer, on their employer's dime, with the goal of advancing their
  employer's business interests.
* **Adopters primarily interact with the project through release packages.**
  Many CNCF projects, like Linkerd, have a community that primarily interacts
  with the projects by downloading and deploying pre-built release artifacts,
  and when the project is working they move on to the next task at hand.
* **The project is a critical part of adopters' infrastructure.** Many CNCF
  projects, like Linkerd, provide features which are critical to the business
  and cannot be easily replicated.

For projects like these, providing a clear way for adopters to fund project
development is a tremendous asset. Our change gave Linkerd's adopters agency in
the project's long-term survival, and the ability to not just de-risk the worst
outcome but to accelerate the best ones. These are transformative benefits.

Our experience was also that the CNCF itself was receptive to this change. We
met with the TOC shortly after the announcement. They asked for minor
clarifications and adjustments to our plan, but the tone of the meeting was
supportive, and it was clear that ultimately everyone, from TOC to maintainers
to adopters, shared the same goal: the long-term health of Linkerd.

## What's next for Linkerd?

More, faster, better Linkerd-ing, of course! With our supercharged team, we're
rapidly converging on a stellar Linkerd 2.17 release and fleshing out our long
and very exciting roadmap beyond that. We'll continue to add maintainers to the
project and to grow our adopter base the only way we know how: by solving actual
problems for actual people. (Without causing them more problems in the
meantime.)

A handful of Linkerd maintainers and project participants will be in attendance
at [Kubecon NA in Salt Lake City this
November](https://buoyant.io/blog/linkerd-community-guide-to-kubecon-cloudnativecon-na-2024-in-salt-lake-city).
If you're there, please do stop by the Linkerd booth in the project pavilion and
say hi. All are welcome.

Needless to say, we'll also continue feeling very grateful for our community.
Thank you, again, from the bottoms of our hearts. We'd love to hear from you,
whether about this change, your thoughts on the future of Linkerd, or any other
mesh-y topics you'd like to discuss.

We honestly do want your input. Linkerd is unique in the service mesh space is
that we are a single, nimble team working off a single, unified roadmap. This
means that the voice of the adopter is one of the strongest forces in our
universe.

Until our next update: onwards.

## Linkerd is for everyone

Linkerd is a graduated project of the [Cloud Native Computing
Foundation](https://cncf.io/). Linkerd is [committed to open
governance.](/2019/10/03/linkerds-commitment-to-open-governance/) If you have
feature requests, questions, or comments, we'd love to have you join our
rapidly-growing community! Linkerd is hosted on
[GitHub](https://github.com/linkerd/), and we have a thriving community on
[Slack](https://slack.linkerd.io/), [Twitter](https://twitter.com/linkerd), and
the [mailing lists](/community/get-involved/). Come and join the fun!

## Photo credit

Photo by
[kazuend](https://unsplash.com/@kazuend?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash)
on
[Unsplash](https://unsplash.com/photos/worms-eye-view-of-forest-during-day-time-19SC2oaVZW0?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash)
