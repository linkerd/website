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

A few weeks ago we conducted a Twitter survey. It was highly unscientific--64
respondents, advertised purely on Twitter, not peer reviewed, etc--but the
results suggested that the popular misunderstanding of service mesh distributed
tracing could be traced to two problems:

1. People believe that a service mesh can "provide distributed
   tracing" without requiring changes to the application code. (It can't.)
2. People believe that distributed tracing is required for some observability
   feature they want, that, in fact, the service mesh can already do without
   distributed tracing.

These misunderstandings manifest as a set of "myths", which I'll attempt to
categorize and dispel below.

## Myth 1: I need distributed tracing to measure the latency of my services.

*Wrong*. Over 60% of respondents suggesting that measuring service latency was
a desired use of distributed tracing in a service mesh. But Linkerd can already
provide latency per service (as well as per route, per client per service, per
client per route, etc) from metrics data, without requiring distributed tracing
or other application-level changes. In fact, the Linkerd dashboard and CLI
already report this data!

{{< fig
  alt="Linkerd dashboard showing an automatically generated route metrics"
  title="Linkerd dashboard showing an automatically generated route metrics"
  src="/images/books/webapp-routes.png" >}}

## Myth 2: I need distributed tracing to see which services talk to which other services.

*Wrong*. Around 60% of respondents suggested that drawing a *service topology*
was a desired use of distributed tracing in a service mesh. These relationships
can be produced purely from metrics data, again without requiring distributed
tracing or any application-level changes. In fact, the Linkerd dashboard
already displays this topology!

{{< fig
  alt="Linkerd dashboard showing an automatically generated topology graph"
  title="Linkerd dashboard showing an automatically generated topology graph"
  src="/images/books/webapp-detail.png" >}}

## Myth 3: I can "get distributed tracing" from the service mesh without having to make any changes to my application.

*Wrong*. Almost 30% of respondents answered that they would not expect to need
any application changes once Linkerd added distributed tracing support.
Unfortunately, while Linkerd can emit trace spans from the proxies, the
application will need to *propagate headers* in order for these spans to be
pulled together into traces. (This isn't a flaw with Linkerd; this is a
function of the sidecar proxy model and is true of any sidecar-based service
mesh.)

Distributed tracing in the service mesh will only work if developers make the
corresponding changes in their code.

## Myth 4: I can "get distributed tracing" from the service mesh by instrumenting my application with a distributed tracing library.

*Yes, sort of*. Almost 28% of respondents answered that they would make use of
distributed tracing in Linkerd by instrumenting their applications with a
distributed tracing library. These libraries will make it easy to propagate the
headers, thus accomplishing the development work you need to do to make use of
distributed tracing.

But once you're at this point, you already have distributed tracing, whether or
not Linkerd adds "distributed tracing support"!

## So, what does distributed tracing support in a service mesh actually get you?

There are some questions that *only* distributed tracing can answer, including:

* What were the slowest requests across the application over the past 24 hours?
* For a particular request, *where* was it slow?
* For a particular request, how much time elapsed in sidecar proxy hops?

Note that only the last question actually requires service mesh distributed
tracing support to answer (and is only interesting if you are using a service
mesh in the first place!)

## Wrapping it up

To summarize everything above, the only *real* value-add of Linkerd adding
distributed tracing support is:

1. If you are doing distributed tracing already, you will also get proxy timing
   and data in your spans.
2. If you are unwilling to implement a distributed tracing library, but are
   willing to propagate headers, you can easily get traces that treat services
   as black boxes.

Both of those are valuable results to have! But they're a far cry from the
expectations we've seen from people in the wild, and the fact that distributed
tracing support requires code changes to function makes it an outlier in the
service mesh feature set.

All that said, distributed tracing support *is* on the roadmap for Linkerd 2.x.
But after reading this, you may decide you don't need it after all.

_Linkerd is a community project and is hosted by the [Cloud Native Computing
Foundation](https://cncf.io/). If you have feature requests, questions, or
comments, we'd love to have you join our rapidly-growing community! Linkerd is
hosted on [GitHub](https://github.com/linkerd/), and we have a thriving
community on [Slack](https://slack.linkerd.io/),
[Twitter](https://twitter.com/linkerd), and the [mailing
lists](https://linkerd.io/2/get-involved/). Come and join the fun!_

(*Image credit: [Dennis Skley](https://www.flickr.com/photos/dskley/)*)
