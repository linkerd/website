---
title: Design Principles
type: docs
---

Linkerd is built for you, the operator, SRE, architect, and platform owner. It's
designed to give you power over your own fate: to provide fundamental
visibility, reliability, and security capabilities at the platform level. The
goal of Linkerd is to give you these powers in a way that's uniform across all
code running in the entire compute environment, and totally independent of
application code or developer teams.

Since Linkerd is built for operators, this also means that Linkerd has do all
that while also imposing the absolute minimum operational complexity. To do
this, we've designed Linkerd with three core principles in mind:

1. **Keep it simple**. Linkerd should be operationally simple with low cognitive
   overhead. Operators should find its components clear and its behavior
   understandable and predictable, with a minimum of magic.

2. **Minimize resource requirements**. Linkerd should impose as minimal a
   performance and resource cost as possible--especially at the data plane
   layer.

3. **Just work**. Linkerd should not break existing applications, nor should it
   require complex configuration to get started or to do something simple.

The first principle is the most important: _keep it simple_. Simplicity doesn't
mean that Linkerd can't have powerful features, or that it has to have one-click
wizards take care of everything for you. In fact, it means the opposite: every
aspect of Linkerd's behavior should be explicit, clear, well-defined, bounded,
understandable, and introspectable. For example, Linkerd's
[control plane](/2/reference/architecture/#control-plane) is split into several
operational components based on their functional boundaries ("web”, "api”, etc.)
These components aren't just exposed directly to you in the Linkerd dashboard
and CLI, they run on the same data plane as your application does, allowing you
to use the same tooling to inspect their behavior.

_Minimize resource requirements_ means that Linkerd, and especially Linkerd's
[data plane proxies](/2/reference/architecture/#data-plane), should consume the
smallest amount of memory and CPU possible. On the control plane side, we've
taken care to ensure that components scale gracefully in the presence of
traffic. On the data plane side, we've build Linkerd's proxy (called simply
"linkerd-proxy”) for performance, safety, and low resource consumption. Today, a
single linkerd-proxy instance can proxy many thousands of requests per second in
under 10mb of memory and a quarter of a core, all with a p99 tail latency of
under 1ms. In the future, we can probably improve even that!

Finally, _just work_ means that adding Linkerd to a functioning Kubernetes
application shouldn't break anything, and shouldn't even require configuration.
(Of course, configuration will be necessary to customize Linkerd's behavior--but
it shouldn't be necessary simply to get things working.) To do this, we've
invested heavily in things like
[automatic L7 protocol detection](/2/features/protocol-detection/), and
[automatic re-routing of TCP traffic within a pod](/2/features/proxy-injection/).

Together, these three principles give us a framework for weighing product and
engineering tradeoffs in Linkerd. We hope they're also useful for understanding
why Linkerd works the way it does.
