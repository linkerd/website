+++
author = "william"
date = 2021-03-01T00:00:00Z
feature = "/uploads/kari-shea-B8JFJWzAC9s-unsplash.jpg"
tags = ["Linkerd"]
thumbnail = "/uploads/kari-shea-B8JFJWzAC9s-unsplash.jpg"
title = "Linkerd 2.10 and Extensions"
featured = true
+++

![Zen garden](/uploads/kari-shea-B8JFJWzAC9s-unsplash.jpg")

Linkerd is the smallest, simplest service mesh in the world. Since Linkerd 2.0,
we've followed a philosophy of minimalism, composability, and building on top
of the existing ecosystem. Doubling down on this idea might seem a little
crazy, but in this blog post I'll describe a feature of the upcoming Linkerd
2.10 that will make Linkerd _even_ smaller and simpler: _extensions_.

In Linkerd 2.10, we've stripped Linkerd's default control plane deployment into
a bare-bones deployment, without Prometheus, Grafana, the dashboard, or several
other components that previously shipped by default. Thanks to these changes, a
basic Linkerd control plane now weighs in at under 200mb at startup, down from
500mb in Linkerd 2.9.

Those components, as well as other components that are not strictly necessary
for basic operation, are instead available as a set of opt-in _extensions_. The
initial set of Linkerd extensions will include:

 * **viz**, which will contain all the on-cluster metrics stack: Prometheus, Grafana, the dashboard, etc.;
 * **multicluster**, which will contain all the machinery for cross-cluster communication; and
 * **jaeger**, which will contain the distributed tracing collector and UI.

The move to extensions serves two purposes. First, it allows Linkerd adopters
to choose exactly which bits and pieces of Linkerd they want to install on
their cluster. Second, it allows the Linkerd community to build
Linkerd-specific operators and controllers without having to modify the core
Linkerd CLI.

## How does it work?

Installing an extension is just as easy as you'd expect. Using the CLI, you
run:

```bash
linkerd install -f - | kubectl apply - # install the core control plane
linkerd viz install -f - | kubectl apply - # install the viz extension
```

(For Helm users, each extension will have a corresponding Helm chart.)

While Linkerd will ship with some default extensions, we've made it as easy as
possible for third-party extensions to hook into this system. For example, a
call to `linkerd foo <cmd>` will automatically invoke a `linkerd-foo` binary,
if it's found in the user's search path, just as `git` and other extensible
CLIs work. Furthermore, after installation, `linkerd check` will automatically
run the checks for any installed extensions and concatenate the output

The goal is that, regardless of source, extensions should "feel" just like the
rest of Linkerd.

## Why do this?

As Linkerd adoption continues to grow dramatically, so does the set of use
cases it must handle. For some users, out-of-the-box observability is the key
reason they adopted Linkerd. For others, it's secure, cross-cluster
communication. For still others it's Linkerd's transparent, on-by-default mTLS.
This variety of use cases is great to see, but it also places stress on the
project—especially with our focus on simplicity.

Thus far, we've tackled this in a somewhat ad-hoc manner, including a custom
install flow for the multi-cluster components, a specialized "[Bring Your Own
Prometheus](https://linkerd.io/2/tasks/external-prometheus/)" feature, and so
on. Moving all this machinery to the extensions framework allows for
consistency: each of these feature extensions can now be treated exactly the
same way.

The extensions mechanism also makes it possible for everyone to build features
into Linkerd that "feel" like the rest of Linkerd but don't require modifying
the core project. We'll be releasing documentation for how to write an
extension shortly after the 2.10 release. In the meantime, you can [crib from
an existing one](https://github.com/linkerd/linkerd2/tree/main/jaeger).

## Linkerd 2.10

The Linkerd 2.10 release should be live next week, and will include a ton of
other exciting features, most notably _opaque ports_&mdash;see the writeup by
Charles Pretzer on [Protocol Detection and Opaque Ports in
Linkerd](/2021/02/23/protocol-detection-and-opaque-ports-in-linkerd/) for the
exciting details.

Want to give extensions a shot today? You can try them in the [latest edge
release](https://linkerd.io/2/edge/) already.

## Linkerd is for everyone

Linkerd is a community project and is hosted by the
[Cloud Native Computing Foundation](https://cncf.io/). Linkerd is
[committed to open governance](https://linkerd.io/2019/10/03/linkerds-commitment-to-open-governance/).
If you have feature requests, questions, or comments, we'd love to have you join
our rapidly-growing community! Linkerd is hosted on
[GitHub](https://github.com/linkerd/), and we have a thriving community on
[Slack](https://slack.linkerd.io/), [Twitter](https://twitter.com/linkerd), and
the [mailing lists](https://linkerd.io/2/get-involved/). Come and join the fun!

(Photo by
[Kari Shea](https://unsplash.com/@karishea?utm_source=unsplash&amp;utm_medium=referral&amp;utm_content=creditCopyText) on
[Unsplash](https://unsplash.com/s/photos/animal-listening?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText)).
