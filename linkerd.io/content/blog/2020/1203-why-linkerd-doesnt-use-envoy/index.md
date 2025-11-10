---
date: 2020-12-03T00:00:00Z
title: Why Linkerd doesn't use Envoy
keywords: [linkerd]
params:
  author: william
  showCover: true
---

## Why Linkerd doesn't use Envoy

In this article I'm going to describe why Linkerd isn't built on
[Envoy](https://www.envoyproxy.io).

This is a bit of a weird article to write. After all, there are a million
projects that Linkerd _doesn't_ use, and none of those decisions deserve a blog
post. But the fact that Linkerd doesn't use Envoy specifically has become a
common enough topic of discussion that it probably deserves a good explanation.

Let me also state upfront that this is not an "Envoy sucks" blog post. Envoy is
a great project, is clearly a popular choice for many, and we have nothing but
respect for the fine folks who work on it. We recommend Envoy to Linkerd users
every day in the form of ingress controllers like
[Ambassador](https://github.com/datawire/ambassador), and there are production
systems around the world today where you can find Envoy and Linkerd working side
by side.

But we chose not to build Linkerd on top of Envoy. Instead, we built a dedicated
"micro-proxy", called simply
[Linkerd2-proxy](https://github.com/linkerd/linkerd2-proxy), which is optimized
for the service mesh sidecar use case. In the increasingly crowded field of
similar-sounding service mesh projects, Linkerd is unique in this regard. But
why did we go this route?

The full answer to this question is nuanced and technical at heart—exactly the
kind of content that tends to get swept away in the faddish, blog-post-driven
world of cloud native adoption.[^1] So in this article I'm going to do my best
to lay out the reasons why in a frank and engineering-focused way. After all,
Linkerd is built _by_ engineers and _for_ engineers, and if there's one thing
I'm proud of, it's that we've made decisions on the basis of engineering
tradeoffs rather than marketing pressure.

In short: **Linkerd doesn't use Envoy because using Envoy wouldn't allow us to
build the lightest, simplest, and most secure Kubernetes service mesh in the
world.**

Being the lightest, simplest, most secure Kubernetes service mesh is Linkerd's
promise to our users, and that's also what makes Linkerd unique among service
meshes: it _is_ dramatically simpler, lighter, and more secure. And the reason
we've been able to accomplish that is—you guessed it—because we build on
Linkerd2-proxy instead of Envoy. Not because Envoy is bad, but because
Linkerd2-proxy is _better_—at least, for the very specific and limited use case
of being a Kubernetes sidecar proxy.

Let's take a look at why.

### What is Linkerd2-proxy?

Before we get into the details, it's helpful to understand a bit more about
Linkerd2-proxy.

Linkerd2-proxy is a "micro-proxy" designed specifically for the service mesh
sidecar use case. Linkerd2-proxy is built on, and has driven many of the
requirements for, the world's most modern network programming environment circa
2020: the Rust asynchronous network ecosystem, including libraries like
[Tokio](https://tokio.rs/), [Tower](https://github.com/tower-rs), and
[Hyper](https://github.com/hyperium/hyper). In terms of sheer technical
advancement, Linkerd2-proxy is one of the most advanced pieces of technology in
the entire CNCF landscape.

Like Envoy, Linkerd2-proxy is a 100% open source Apache v2 CNCF project that
features regular third-party audits, an active community, and high-scale
production usage in mission-critical systems around the world. Unlike Envoy,
Linkerd2-proxy is designed for only one use case: proxying requests to and from
a single Kubernetes pod while receiving configuration from the Linkerd control
plane. And unlike Envoy, Linkerd2-proxy is designed to be an _implementation
detail_: it's not user-facing, it's not usable as a generic building block, and
it has a boring name. This means Linkerd2-proxy tends to go unnoticed, though
we've tried to shed a little more light on it recently with articles looking
[under the hood](/2020/07/23/under-the-hood-of-linkerds-state-of-the-art-rust-proxy-linkerd2-proxy/)
and at [the roadmap](/2020/09/02/the-road-ahead-for-linkerd2-proxy/)).

So why "micro-proxy"? Loathe as we are to introduce another term into the
lexicon,[^2] the word "proxy" doesn't do Linkerd2-proxy justice. A proxy is
something like Envoy, NGINX, Apache, or httproxy. These projects can do a huge
variety of things ("send HTTP requests with a path that matches this wildcard to
this backend while rewriting these headers, compressing any Javascript files,
and rotating the access logs") and they have a configuration and tuning surface
area to match. Using a proxy in production requires significant operational
investment: if you're running Apache, you're going to end up with an Apache
expert somewhere in the house.

But Linkerd2-proxy is different. It's designed to be an implementation detail
that doesn't require specialized knowledge or dedicated operational investment
(though Linkerd as a whole, of course, does require it). There's no user-facing
YAML; instead, Linkerd2-proxy is configured automatically through a handful of
environment variables set at injection time and by the Linkerd control plane at
runtime. We've kept Linkerd2-proxy's tuning surface area to a bare minimum so
that end users rarely have to touch it directly. In short: Linkerd2-proxy is
designed to stay behind the scenes, to be an implementation detail, and to just
work.

_Tl;dr_: Linkerd2-proxy is dramatically different from proxies like Envoy,
NGINX, and Apache, and the word "proxy" doesn't do it justice.

### Complexity

So why did we build Linkerd2-proxy rather than using Envoy? One big reason is
complexity.

Envoy is a flexible and general-purpose proxy, and that's much of the reason for
its popularity. You can use Envoy as an ingress, as an egress, as a service mesh
sidecar, and in many other ways. But with this flexibility comes complexity.

As a point of comparison, as of November 2020, the Envoy repo weighs in at **172
KLOC** of C++ code, with a "complexity score" (measured in terms of branches and
loops) of **19k**.[^3] By contrast, Linkerd2-proxy comes in at **30 KLOC** and
has a complexity score of **1.5k**. In other words: the Linkerd2-proxy codebase
is 5 times smaller than Envoy and, by this measure, its complexity is ten times
less than Envoy's.[^4]

This isn't an apples-to-apples calculation, of course. It doesn't capture the
libraries or dependencies outside the repos; the complexity score numbers are
not strictly portable across languages; and so on. But it should give you a
general sense of the relative size of these projects: internally, Linkerd2-proxy
is _orders of magnitude smaller and simpler than Envoy_.

Is this complexity a moral failing in Envoy? No. Again, Envoy has a lot of
complex code because it can do a lot of complex things. However, this complexity
is a very difficult foundation upon which to build a project that is focused on
simplicity, especially operational simplicity.[^5]

_Tl;dr_: Envoy is a Swiss Army knife. Linkerd2-proxy is a needle.

### Resource consumption

One thing is clear with any sidecar-based service mesh: you're going to have a
lot of proxies.

That means that the aggregate CPU and memory consumed by the data plane are a
critical component of the _cost_ of running a service mesh, especially as the
application scales.

Using Linkerd2-proxy allows us to keep tight reins on Linkerd's resource
consumption. In our internal benchmarks of Linkerd and Istio using
[Kinvolk's open source benchmark harness](https://github.com/kinvolk/service-mesh-benchmark),
for example, at 4,000 RPS (requests per second) of ingress traffic, we see
Linkerd2-proxy instances consistently between **14mb** and **15mb** of memory,
while Istio's Envoy ranged between **135mb** and **175mb**—ten times the size.
Similarly, Linkerd2-proxy's CPU usage for the test run was consistently at
**15ms** (CPU milliseconds) per instance, while Istio's Envoy ranged from
**22ms** to **156ms**—from 50% more to 10x more.

Again, this is not an entirely fair comparison. These are internal benchmarks
against one particular application and one particular configuration, and
undoubtedly some of Istio's design decisions played a big role here. But Istio
is built by world-class engineers, and the point is: if Linkerd were built on
Envoy, we'd have to make many of those same design decisions ourselves.

_Tl;dr_: In practice, in the service mesh context, Linkerd2-proxy uses a
fraction of the system resources that Envoy does.

### Security

The last point is perhaps the most philosophical: security. The security of the
data plane is a _huge_ concern for any service mesh. Linkerd, for example, is
used in production around the world to handle extraordinarily sensitive data,
from health information to personally-identifiable details to financial
transactions.

We have no reason to believe that Envoy is insecure. But to the extent that it
_is_ secure (especially at 170+ KLOC of C++ code), it's secure via the manual
and expensive process of getting a lot of very smart engineers using it,
examining it, filing CVEs, fixing bugs, and repeating. This is the "traditional
process" for software security, and it works—at least, in the fullness of time.
It is also expensive, difficult, and failure prone. C++ code is
[notoriously](https://www.vice.com/en/article/a3mgxb/the-internet-has-a-huge-cc-problem-and-developers-dont-want-to-deal-with-it)
[difficult](https://en.wikipedia.org/wiki/Buffer_overflow#Choice_of_programming_language)
to
[secure](https://alexgaynor.net/2020/may/27/science-on-memory-unsafety-and-security/),
even for the most experienced programmers.

More fundamentally, this is not the security model we want to rely on for
Linkerd and not what we believe is the future of systems programming security.
Our choice of Rust for Linkerd2-proxy was intentional: Rust's memory safety
allows us to confidently write secure code in Linkerd2-proxy in a way that
minimizes our reliance on humans catching the problems. Which is not to say that
Linkerd2-proxy cannot have security vulnerabilities, of course! Rather, that it
will have fewer; that we will need to rely less on our own humble talents to
avoid them; and that we will less often need to impose on our users to upgrade
their systems with critical updates in order to remain secure.

_Tl;dr_: Linkerd2-proxy's Rust foundations give us confidence in the security of
Linkerd's data plane.

## Could Linkerd use Envoy?

Simplicity, resource consumption, and security were the driving factors in our
decision to not adopt Envoy. However, we do believe that the choice of proxy is
ultimately an implementation detail. While we've invested tremendous amounts in
Linkerd2-proxy, we do periodically re-evaluate Envoy. I can say with clarity
that if the tradeoff for our users ever tips in Envoy's favor, we will adopt it
without qualms.

Our advice to would-be service mesh adopters, though, is simple: ignore the
noise. Your job is not to "use a service mesh" or "adopt Envoy" or even "use
only CNCF technology". Your job is to clearly understand the problem you're
trying to solve and then to pick the solution that solves it best. And whatever
you pick, you're going to have to live with it—so make sure you're making a
decision based on concrete requirements and well-understood engineering
tradeoffs, not on fashion or trends.

## FAQ

### So why _do_ so many service meshes use Envoy?

Because writing your own modern, scalable, high-performance network
(micro-)proxy is _hard_. It's _really hard_. Building out Linkerd2-proxy and the
Rust networking libraries that make it possible has been a tremendous effort
from a many people for the past several years. Unless your project has both the
technical prowess and the _desire_ to tackle this challenge, it's much easier to
just use Envoy.

### But isn't Envoy a "standard" for service meshes?

No.[^6] A _standard_ is something that is necessary for interoperability. The
_standard_ that matters for service meshes is TCP, or HTTP, or things like
[SMI](https://smi-spec.io/) that allow tools to be built on top of the service
mesh. (E.g. this excellent example of
[Argo driving Linkerd via SMI for canary rollouts](https://argoproj.github.io/argo-rollouts/getting-started/smi/).)

Envoy being a popular choice of service mesh data plane proxy is not a standard,
it's simply a commonality. What would it mean for Envoy to be a "service mesh
standard"? That we could keep our data plane in place, and swap out the control
plane? That we can have different control planes operate the same data plane?
These are far-fetched use cases at best.

### But what if we have a requirement to use Envoy?

I would argue that's not a real requirement. Your job is not to adopt a
particular piece of technology. Your job is to solve a problem.

And if your problem is "we need to build a reliable, secure, and observable
Kubernetes platform without paying an insane complexity cost" then I highly
suggest you consider taking a look at Linkerd.

### Who uses Linkerd2-proxy in production today?

Everyone who uses Linkerd uses Linkerd2-proxy. That means that you can find
Linkerd2-proxy powering the critical production architecture of companies like
Nordstrom, Microsoft, H-E-B, Chase, Clover Health, HP, any many more.

### Could other service mesh projects use Linkerd2-proxy?

Not really. But anyone who is interested in building a high performance
ultralight network proxy could certainly make use of the underlying Rust network
libraries that power Linkerd.

### Sounds amazing! How can I get started with Linkerd?

I never thought you'd ask. You can install Linkerd in about 5 minutes, including
mutual TLS, with zero configuration required. Start with our
[getting started guide](/2/getting-started/).

## Linkerd is for everyone

Linkerd is a community project and is hosted by the
[Cloud Native Computing Foundation](https://cncf.io/). Linkerd is
[committed to open governance](/2019/10/03/linkerds-commitment-to-open-governance/).
If you have feature requests, questions, or comments, we'd love to have you join
our rapidly-growing community! Linkerd is hosted on
[GitHub](https://github.com/linkerd/), and we have a thriving community on
[Slack](https://slack.linkerd.io/), [Twitter](https://twitter.com/linkerd), and
the [mailing lists](/community/get-involved/). Come and join the fun!

(Photo by
[Paul Felberbauer](https://unsplash.com/@servuspaul?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText)
on
[Unsplash](https://unsplash.com/?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText)).

## Footnotes

[^1]:
    And while Envoy is great, the recent crop of low-calorie vendors who attach
    themselves to Envoy, promote Envoy as the one true path to the service mesh,
    take swipes at Linkerd because it doesn't "support" Envoy (as if that were
    somehow a requirement), etc, are most decidedly _not_ great.

[^2]:
    After all, Linkerd invented the term "service mesh", and look where it got
    us.

[^3]:
    As measured with the excellent [scc](https://github.com/boyter/scc) tool by
    running `scc source include` inside the Envoy repo circa November 2020.

[^4]:
    Similarly measured by running `scc linkerd linkerd2-proxy` inside the
    linkerd2-proxy repo circa November 2020.

[^5]:
    Code complexity does not necessarily translate to user-facing complexity, of
    course. One might ask: can an Envoy-based service mesh successfully _wrap_
    Envoy's complexity, so that end users can avoid the necessity of developing
    operational expertise? Answering this question fully is outside the scope of
    this article (which is about Linkerd, after all!) but a perusal of the
    [300+ open issues in Istio that refer to Envoy](https://github.com/istio/istio/issues?q=is%3Aissue+is%3Aopen+envoy+sort%3Acomments-desc)
    suggests that, at a minimum, it is not trivial.

[^6]:
    We hear this particular argument put forth by vendors of Envoy-based service
    meshes, usually because they don't have a good technical argument to fall
    back to.
