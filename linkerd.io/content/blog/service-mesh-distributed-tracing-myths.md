---
title: 'Distributed tracing and the service mesh: four myths'
author: 'william'
date: 2019-08-08T00:00:00+00:00
thumbnail: /uploads/threading-the-needle.jpg
draft: false
slug: service-mesh-distributed-tracing-myths
tags: [Linkerd]
---

![Starting a trace, the old-fashioned way](/uploads/threading-the-needle.jpg)

One of the most common feature requests for Linkerd 2.x is *distributed
tracing*. Unfortunately, we've found that many people asking for this feature
don't really actually understand what they're asking for.

A few weeks ago we conducted [a Twitter
survey](https://twitter.com/linkerd/status/1152326635959439360). It was highly
unscientific--64 respondents, advertised purely on Twitter, not peer reviewed,
etc--but the results suggested that there is a popular misunderstanding of what
distributed tracing support in a service mesh actually is. These
misunderstandings can be traced to two issues:

1. People believe that a service mesh can "provide distributed
   tracing" without requiring changes to the application code. (It can't.)
2. People believe that distributed tracing is required for some observability
feature they want that, in fact, is already provided by the service mesh.

These misunderstandings manifest as a set of "myths", which I'll attempt to
categorize and dispel below.

## Myth 1: I need distributed tracing to measure the latency of my services.

*False*. Many respondents suggested that measuring service latency was a
desired use case for distributed tracing in the service mesh. But Linkerd can
already provide latency per service (as well as per route, per client per
service, per client per route, etc) from metrics data, without requiring
distributed tracing or other application-level changes. In fact, the Linkerd
dashboard and CLI already report this data!

{{< fig
  alt="Linkerd dashboard showing an automatically generated route metrics"
  title="Linkerd dashboard showing an automatically generated route metrics"
  src="/images/books/webapp-routes.png" >}}

## Myth 2: I need distributed tracing to see which services talk to which other services.

*False*. Many respondents suggested that drawing a *service topology* was a
desired use of distributed tracing in a service mesh. But Linkerd can already
detect and display these relationships purely from metrics data, again without
requiring distributed tracing or any application-level changes. In fact, the
Linkerd dashboard already displays this topology!

{{< fig
  alt="Linkerd dashboard showing an automatically generated topology graph"
  title="Linkerd dashboard showing an automatically generated topology graph"
  src="/images/books/webapp-detail.png" >}}

## Myth 3: I can "get distributed tracing" from the service mesh without having to make any changes to my application.

*False*. Many respondents answered that they would not expect to need any
application changes once Linkerd added distributed tracing support.
Unfortunately, while Linkerd can emit trace spans from the proxies, the
application will need to *propagate headers* in order for these spans to be
pulled together into traces. In other words, distributed tracing in the service
mesh can only work if developers make the corresponding changes in their code.

(This isn't a flaw with Linkerd; this is a function of the sidecar proxy model
and is true of any sidecar-based service mesh.)

## Myth 4: I can "get distributed tracing" from the service mesh by instrumenting my application with a distributed tracing library.

*Sort of false*. Some respondents answered that they would make use of
distributed tracing in Linkerd by instrumenting their applications with a
distributed tracing library. It's true that these libraries will make it easy
to propagate the headers, thus accomplishing the development work you need to
do to make use of distributed tracing. But once you're at this point, you
already have distributed tracing, regardless of whether Linkerd has
"distributed tracing support"!

## So, what does distributed tracing support in a service mesh actually get you?

There are some questions that Linkerd can't help you with and that distributed
tracing is the best way to answer, including:

* What were the slowest N requests across the application over the past 24
  hours, and *where* were they slow?
* For a particular end-to-end request, what happened?
* For a particular end-to-end request, how much time elapsed in sidecar proxy hops?

If it's critical for you to be able to answer these questions, then distributed
tracing is a great approach. (The last question may seem a little obscure, but
often comes up when people have recently introduced a service mesh and want to
understand its behavior.)

If you've decided you want distributed tracing, then the *actual* value of
Linkerd adding distributed tracing support is:

1. If you are doing distributed tracing already, you will now also get proxy
   timing and data in your spans
2. If you are unwilling to implement a distributed tracing library in your
   code, but *are* willing to propagate headers, you can get traces. (They will
   treat services as black boxes, but that may be fine for you.)
3. You will be able to report service mesh proxy behavior on a per-request basis.

These are all completely valid reasons, and we have many concrete examples of
cases where they are useful. But they're a far cry from the expectations for
distributed tracing that we've seen from people in the wild.

All that said, [distributed tracing support *is* on the roadmap for Linkerd
2.x](https://github.com/linkerd/linkerd2/issues/3188). So if distributed
tracing support is a valuable feature for you in Linkerd 2.x, please leave a
comment on that ticket saying as much--we'd love to hear from you.

_Linkerd is a community project and is hosted by the [Cloud Native Computing
Foundation](https://cncf.io/). If you have feature requests, questions, or
comments, we'd love to have you join our rapidly-growing community! Linkerd is
hosted on [GitHub](https://github.com/linkerd/), and we have a thriving
community on [Slack](https://slack.linkerd.io/),
[Twitter](https://twitter.com/linkerd), and the [mailing
lists](https://linkerd.io/2/get-involved/). Come and join the fun!_

*Special thanks to Alex Ellis for reviewing an earlier draft of this post.*

(*Image credit: [Dennis Skley](https://www.flickr.com/photos/dskley/)*)
