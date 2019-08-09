---
title: 'Distributed tracing and the service mesh: four myths'
author: 'william'
date: 2019-08-08T00:00:00+00:00
thumbnail: /uploads/threading-the-needle.jpg
draft: false
slug: service-mesh-distributed-tracing-myths
tags: [Linkerd]
---

![Starting a trace the old-fashioned way](/uploads/threading-the-needle.jpg)

One of the most common feature requests for Linkerd 2.x is *distributed
tracing*, and we're happy to report that this feature is on the [near-term
Linkerd roadmap](https://github.com/linkerd/linkerd2/issues/3188).
Unfortunately, we've found that many people asking for this feature don't quite
understand what they're asking for.

A few weeks ago we conducted [a Twitter
survey](https://twitter.com/linkerd/status/1152326635959439360) to validate
this theory. It was highly unscientific--64 respondents, advertised purely on
Twitter, not peer reviewed, etc--but the results suggested some common
misunderstandings of what distributed tracing support in a service mesh
actually provides. These misunderstandings can be traced to two classes of
issues:

1. Beliefs that a service mesh can "provide distributed tracing" without
   requiring changes to the application code.
2. Beliefs that distributed tracing is required for some observability feature
   they want that, in fact, is already provided by the service mesh.

These misunderstandings manifest as a set of "myths", which I'll attempt to
categorize and dispel below.

## Myth 1: I need distributed tracing to measure the latency of my services.

*False*. Many respondents suggested that measuring service latency was a
desired use case for distributed tracing in the service mesh. But Linkerd can
already provide latency per service (as well as per route, per client per
service, per client per route, etc) from metrics data, without requiring
distributed tracing or other application-level changes. In fact, the Linkerd
dashboard and CLI already report this data.

{{< fig
  alt="Linkerd dashboard showing an automatically generated route metrics"
  title="Linkerd dashboard showing an automatically generated route metrics"
  src="/images/books/webapp-routes.png" >}}

## Myth 2: I need distributed tracing to see which services talk to which other services.

*False*. Many respondents suggested that drawing a *service topology* was a
desired use of distributed tracing in a service mesh. But Linkerd can already
detect and display these relationships purely from metrics data, again without
requiring distributed tracing or any application-level changes. In fact, the
Linkerd dashboard already displays this topology.

{{< fig
  alt="Linkerd dashboard showing an automatically generated topology graph"
  title="Linkerd dashboard showing an automatically generated topology graph"
  src="/images/books/webapp-detail.png" >}}

## Myth 3: I can "get distributed tracing" from the service mesh without having to make any changes to my application.

*False*. Many respondents answered that they would not expect to need any
application changes once Linkerd added distributed tracing support.
Unfortunately, while Linkerd can emit trace spans from the proxies, the
application will need to *propagate headers* in order for these spans to be
pulled together into traces. In other words, in contrast to nearly every other
service mesh feature, distributed tracing mesh can only work if developers make
changes to their code.

(This isn't a flaw with Linkerd; this is a function of the sidecar proxy model
and is true of any sidecar-based service mesh.)

## Myth 4: I can "get distributed tracing" from the service mesh by instrumenting my application with a distributed tracing library.

*Sort of true*. Some respondents answered that they would make use of
distributed tracing in Linkerd by instrumenting their applications with a
distributed tracing library. It's true that these libraries will make it easy
to propagate the headers, thus accomplishing the development work you need to
do to make use of distributed tracing. But once you're at this point, you have
distributed tracing, regardless of whether Linkerd has "distributed tracing
support"! (Of course, Linkerd support will add some important data--see below.)

## What would distributed tracing support in a service mesh actually get you?

If you've decided you want distributed tracing, *and* you are willing and able
to modify your application to support it, then what distributed tracing at the
service mesh level would actually get you is:

1. Proxy timing and data in your traces, which can be helpful for understanding
   how much latency for particular requests is coming from the proxy. (Happily,
   [Linkerd is very fast]({{< ref "linkerd-benchmarks" >}}), but nothing is free.)
2. Extending traces to ingress points, which paints a more complete picture of
   how time is spent on requests.
3. Distributed tracing support without coupling application code to a
   particular library, at least for situations where it's ok to treat
   services as black boxes.

All that said, we're happy to report that [distributed tracing support *is* on
the roadmap for Linkerd 2.x in
2019](https://github.com/linkerd/linkerd2/issues/3188). If this is a valuable
feature for you in Linkerd 2.x, please leave a comment on that ticket saying as
much--we'd love to hear from you.

_Linkerd is a community project and is hosted by the [Cloud Native Computing
Foundation](https://cncf.io/). If you have feature requests, questions, or
comments, we'd love to have you join our rapidly-growing community! Linkerd is
hosted on [GitHub](https://github.com/linkerd/), and we have a thriving
community on [Slack](https://slack.linkerd.io/),
[Twitter](https://twitter.com/linkerd), and the [mailing
lists](https://linkerd.io/2/get-involved/). Come and join the fun!_

*Special thanks to Alex Ellis and Matt Turner for reviewing an earlier draft of
this post.*

(*Image credit: [Dennis Skley](https://www.flickr.com/photos/dskley/)*)
