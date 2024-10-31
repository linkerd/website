---
date: 2019-04-29T00:00:00Z
slug: linkerd-design-principles
title: Linkerd's design principles
keywords: [linkerd]
params:
  author: william
  showCover: true
---

_tl;dr: Does a service mesh need design principles? We think so. We built Linkerd 2.0 around three core principles that are designed to reduce the operational cost---especially for human beings---of running a service mesh._

When we launched Linkerd 2.0 last September, it marked a substantial departure from Linkerd 1.x. Gone was the JVM, the config file, and the setup and tuning process that ranged from intricate to complex. Linkerd could now be installed in under 60 seconds, without configuration or application changes, and would _just work_. Not to mention that Linkerd 2.0 was literally orders of magnitude smaller and faster than before.

A little over 6 months in and [already at Linkerd 2.3](https://linkerd.io/2019/04/16/announcing-linkerd-2.3/), the reception to these changes has been resoundingly positive:

{{< tweet user="coleca" id="1091591745870139392" >}}

While [the move from the JVM to Rust](https://www.infoq.com/articles/linkerd-v2-production-adoption) was a huge part of this success for Linkerd 2.0, just as important was our decision to codifying a set of core _product design principles_ for 2.0. These principles were based on a lesson we learned in our years of helping companies around the world get Linkerd 1.x into production: _while our users were getting tremendous value from Linkerd, they were paying a heavy price to get there_. This price was the time spent configuring, understanding, tuning, and operating Linkerd 1.x.

To address this, our design process for 2.0 started by writing down a set of design principles that would ensure we did right by our users. These principles were brief:

1. **Keep it simple**. Linkerd should be operationally simple with low cognitive overhead. Operators should find its components clear and its behavior understandable and predictable, with a minimum of magic.

2. **Minimize resource requirements**. Linkerd should impose as minimal a performance and resource cost as possible–especially at the data plane layer.

3. **Just work**. Linkerd should not break existing applications, nor should it require complex configuration to get started or to do something simple.

These three principles have one thing in common: they all _reduce the operational cost_ of running Linkerd. Whether it's measured in compute resources or, far more importantly, in time spent by human beings, these principles require Linkerd to stay true to the goal of keeping the cost of running the service mesh as low as possible.

This focus on cost is so critical because _Linkerd is fundamentally a product for human beings_: operators, SREs, and platform owners. Seen this way, reducing operational cost isn't just a nice idea---it's a reflection of how actual human beings are going to spend their time and energy with our project. For us _not_ to minimize the operational cost would do our users a tremendous disservice.

For more detail about these principles and some examples of them in action, check out the [Linkerd design principles documentation](https://linkerd.io/2/design-principles/).

Linkerd is a community project and is hosted by the [Cloud Native Computing Foundation](https://cncf.io). If you have feature requests, questions, or comments, we'd love to have you join our rapidly-growing community! Linkerd is hosted on [GitHub](https://github.com/linkerd/), and we have a thriving community on [Slack](https://slack.linkerd.io), [Twitter](https://twitter.com/linkerd), and the [mailing lists](https://linkerd.io/2/get-involved/). Come and join the fun!

_Image credit: [Dimitry B.](https://www.flickr.com/photos/ru_boff/)_
