---
title: 'Distributed tracing and the service mesh: four myths'
author: 'william'
date: 2019-08-07T00:00:00+00:00
thumbnail: /uploads/threading-the-needle.jpg
draft: false
slug: service-mesh-distributed-tracing-myths
tags: [Linkerd]
---

![Starting a trace, the old-fashioned way](/uploads/threading-the-needle.jpg)

One of the most common feature requests we get for Linkerd 2.x is to support
*distributed tracing*. Unfortunately, we've found that many people asking for
this feature don't really actually understand what they're asking for.

To capture these misconceptions, a few weeks ago we conducted a Twitter survey.
This survey was highly unscientific--64 respondents, advertised purely on
Twitter, not peer reviewed, etc--but the results suggested that popular
misunderstanding of service mesh distributed tracing could be traced to two
core misunderstandings:

1. A service mesh can "provide distributed tracing" without requiring changes
   to the application code (it can't).
2. Distributed tracing is necessary for some "observability feature X" that
   the service mesh can already do.

These misunderstandings manifested as a set of "myths" about what it means for
a service mesh to add distributed tracing, which I'll attempt to catalogue and
address below.

## Myth 1: I need distributed tracing to measure the latency of my services

*Wrong*. Over 60% of respondents suggesting that measuring service latency was
a desired use of distributed tracing in a service mesh. But Linkerd can already
provide latency per service (as well as per route, per client per service, per
client per route, etc) from metrics data, without requiring distributed tracing
or any application-level changes. In fact, the Linkerd dashboard and CLI
already report this data:

{{< fig
  alt="Linkerd dashboard showing an automatically generated route metrics"
  title="Linkerd dashboard showing an automatically generated route metrics"
  src="/images/books/webapp-routes.png" >}}

## Myth 2: I need distributed tracing to see which services talk to which other services

*Wrong*. Around 60% of respondents suggested that drawing a *service topology*
was a desired use of distributed tracing in a service mesh. These relationships
can be produced purely from metrics data, again without requiring distributed
tracing or any application-level changes. In fact, the Linkerd dashboard
already displays it per service:

{{< fig
  alt="Linkerd dashboard showing an automatically generated topology graph"
  title="Linkerd dashboard showing an automatically generated topology graph"
  src="/images/books/webapp-detail.png" >}}

## Myth 3: I can "get distributed tracing" from the service mesh without having to make any changes to my application

*Wrong*. Almost 30% of respondents answered that they would not expect to need
any application changes once Linkerd added distributed tracing support.
Unfortunately, while Linkerd can emit trace spans from the proxies, the
application will need to *propagate headers* in order for these spans to be
pulled together into traces. (This isn't a flaw with Linkerd; this is a
function of the sidecar proxy model and is true of any sidecar-based service
mesh.)

Thus, distributed tracing in the service mesh can only function if developers
make the corresponding changes in their code.

## Myth 4: I can "get distributed tracing" from the service mesh by instrumenting my application with a distributed tracing library

*Sort of*. Almost 28% of respondents answered that they would make use of
distributed tracing in Linkerd by instrumenting their applications with a
distributed tracing library. But this is insufficient--just as in the previous
myth, application developers will need to modify their application to forward
distributed tracing headers, regardless of whether they have also instrumented
their application with tracing libraries.

(And if you're willing to do this work, then you can get distributed tracing
today--you don't need Linkerd to do anything specific.)

## So, what does distributed tracing support in a service mesh actually get you?

There are some questions that only distributed tracing can provide, including:

* What were the slowest requests across the application over the past 24 hours?
* For a particular request, *where* was it slow?
* For a particular request, how much time elapsed in sidecar proxy hops?

When Linkerd 2.x adds distributed tracing support, you will be able to answer
these questions, but only if you *also* modifying the application to forward
headers.

Note that almost no other service mesh feature requires no code changes. Also
note that if you want tracing to include data from *within* service code,
rather than treating the services as black boxes, you will likely need to
instrumenting your application code with a distributed tracing library.

## Wrapping it up

In conclusion, if you need to answer the specific class of questions above, and
if you are willing to modify your application--then distributed tracing will
allow you to do that. For everyone other situation, it's simply not necessary.

_Linkerd is a community project and is hosted by the [Cloud Native Computing
Foundation](https://cncf.io/). If you have feature requests, questions, or
comments, we'd love to have you join our rapidly-growing community! Linkerd is
hosted on [GitHub](https://github.com/linkerd/), and we have a thriving
community on [Slack](https://slack.linkerd.io/),
[Twitter](https://twitter.com/linkerd), and the [mailing
lists](https://linkerd.io/2/get-involved/). Come and join the fun!_

(*Image credit: [Dennis Skley](https://www.flickr.com/photos/dskley/)*)
