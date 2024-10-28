---
title: December Linkerd community meeting recap
date: 2021-12-22T00:00:00Z
description: |-
  We hosted our very first hands-on workshop on mTLS with Matei David. It was
  such a success that we decided to do these regularly so we launched a Service
  Mesh Academy program.
keywords: [community, meetup]
params:
  author: kevinl
  thumbnailProcess: fit
---

As usual, there is no reason to panic if you missed our community meeting.
Here's our recap along with the recording.

Before getting started, please make sure you participate in this
[CNCF service mesh micro-survey](https://www.surveymonkey.co.uk/r/D9RK6HR)
— your input really helps Linkerd! And nope, it's not the same survey we
shared earlier, it's a new one. So thanks for doing this again!

## News and updates

We hosted our very first hands-on workshop on
[mTLS](https://buoyant.io/service-mesh-academy/a-deep-dive-into-kubernetes-mtls-with-linkerd/)
with Matei David. It was such a success that we decided to do these
regularly so we launched a
[Service Mesh Academy](https://buoyant.io/service-mesh-academy/)
program. Look out for more workshops on Linkerd and other related CNCF
projects. You can also
[signup for updates](https://buoyant.io/service-mesh-academy/),
so you don't miss them.

Notable edge releases changes from the last few weeks include
EndpointSlices that are now enabled by default and the proxy-init
container which can be run without root privileges.

## Linkerd roadmap

Of course we also heard from Oliver Gould with some roadmap updates.
The Linkerd team continues working on the next evolution of
ServiceProfiles. We are also revamping Helm chart versions to better
communicate breaking changes. Additionally, we are splitting Helm charts
so that the privileged installation of CRDs is separate from the
installation of other components and we will follow a more strict
Kubernetes version deprecation cycle.

{{< youtube fje09yl3vW4 >}}

## MarbleRun and Linkerd

This month, Moritz Eckert from the [MarbleRun](https://marblerun.sh/)
team demoed Linkerd with their control plane for confidential
computing. But before getting started, Charles wanted to learn a
little bit more about MarbleRun. Moritz explained that their goal
is to solve the problem of running confidential workloads when using
the cloud native stack, challenges include:

- Runtime encryption of data
- Verifiable topology and functionality
- Protection against malicious actors

Marblerun is an open source tool that allows users to run sensitive
workloads in isolated, encrypted, and verifiable enclaves on commodity
CPUs. It creates confidential deployments with confidential containers
(such as with [EGo](https://github.com/edgelesssys/ego)) that are then
meshed.  mTLS termination must happen inside enclaves because you
can't trust the host the deployment it is running on.

For this demo, Moritz modified Buoyant’s emojivoto application to
provide an example of how to run it as a confidential workload
[edgelesssys/emojivoto](https://github.com/edgelesssys/emojivoto). You can find the steps for installing
MarbleRun and securing emojivoto in their
[documentation](https://docs.edgeless.systems/marblerun/#/).
Watch the video to see the demo — it starts at min ~15.

## Speeding up control plane integration tests

Linkerd maintainer Matei shared how the team is seeking to speed
up control plane integration tests. Improving CI execution by
speeding up individual tests, avoiding tests on changes that do
not affect Linkerd behavior, and fixing flakiness has always been
a priority. We are also working on removing duplicated test
suites, moving tests that share a dependency into a single suite
(e.g.  tests that depend on linkerd-viz should be part of the viz
test suite), and identifying tests that block execution with sleeps
instead of retries. Expect some of these updates soon!

## December Hero

Last but certainly not least, we announced our December Linkerd Hero
[Aleksandr Tarasov](https://github.com/aatarasoff)! Aleksandr is
Director of Engineering at ANNA Money and recently wrote three great
Linkerd blog posts. In his first blog, he shares his team’s
decision-making process when
[selecting Linkerd as their service mesh](https://aatarasoff.medium.com/the-journey-to-service-mesh-part-2-how-we-met-linkerd-cd32a6e9fa63).
His next blog covers
[three ways to use Linkerd with Kubernetes jobs](https://itnext.io/three-ways-to-use-linkerd-with-kubernetes-jobs-c12ccc6d4c7c).
And his latest blog is a
[practical guide to Linkerd authorization policies](https://itnext.io/a-practical-guide-for-linkerd-authorization-policies-6cfdb50392e9).
These are all great reads, keep them coming Aleksandr!
Sharing your experience with the community is one of the most
valuable ways to contribute to Linkerd! Thank you, Aleksandr,
for sharing your journey so others can learn from it!

[Join our next community meeting](https://community.cncf.io/events/details/cncf-linkerd-community-presents-january-linkerd-online-community-meetup/)
on Thursday, January 27!
