+++
date = "2018-09-17T08:00:00-07:00"
title = "Frequently Asked Questions"
[sitemap]
  priority = 1.0
[menu.l5d2docs]
  name = "Frequently Asked Questions"
  identifier = "faq"
  weight = 9
+++

# What is Linkerd?

Linkerd is a [service
mesh](https://blog.buoyant.io/2017/04/25/whats-a-service-mesh-and-why-do-i-need-one/).
It adds observability, reliability, and security to cloud native applications,
without requiring code changes. For example, Linkerd can monitor and report
per-service success rates and latencies, can automatically retry failed
requests, and can encrypt and validate connections between services, all
without requiring any modification of the application itself.

Linkerd works by inserting ultralight proxies (collectively, the "data plane")
alongside each application instance. Linkerd's control plane provides operators
with a uniform point at which they can control and measure the behavior of the
data plane. Operators typically interact with Linkerd using the [CLI](../cli)
and the [web dashboard UI](../getting-started/#step-4-explore-linkerd).

# Who owns Linkerd and how is it licensed?

Linkerd is licensed under Apache v2 and is a [Cloud Native Computing
Foundation](https://cncf.io) (CNCF) project. The CNCF owns the trademark; the
copyright is held by the Linkerd authors themselves.

# Who maintains Linkerd?

See the [2.x
maintainers](https://github.com/linkerd/linkerd2/blob/master/MAINTAINERS.md)
file, and the [1.x
maintainers](https://github.com/linkerd/linkerd/blob/master/MAINTAINERS.md)
file.

# Is there an Enterprise edition, or a commercial edition?

No. Everything in Linkerd is fully open source.

# How do I pronounce Linkerd?

The "d" is pronounced separately, i.e. "Linker-DEE". (It's a UNIX thing.)

# What's the difference between Linkerd 1.x and 2.x?

Linkerd 1.x is built on the "Twitter stack": Finagle, Netty, Scala, and the
JVM. Linkerd 2.x is built in Rust and Go, and is significantly faster and
lighter-weight. However, Linkerd 2.x currently does not have the full platform
support or featureset of 1.x. (See [the full list of supported
platforms](../../choose-your-platform) across both versions.)

# Is Linkerd 1.x still supported?

Yes, the 1.x branch of Linkerd is under active development, and continues
to power the production infrastructure of companies around the globe.

[The full Linkerd 1.x documentation is here](/1/).

# Does Linkerd require Kubernetes?

Linkerd 2.x currently requires Kubernetes, though this will change in the
future. Linkerd 1.x can be installed on any platform, and supports Kubernetes,
DC/OS, Mesos, Consul, and ZooKeeper-based environments.

# Where's the Linkerd roadmap?

As a community project, there is no official roadmap, but a glance at the
[active GitHub issues](https://github.com/linkerd/linkerd2/issues) will give
you a sense of what is in store for the future.

# What happens to Linkerd's proxies if the control plane is down?

Linkerd's proxies do not integrate with Kubernetes directly, but rely on the
control plane for service discovery information. The proxies are designed to
continue operating even if they can't reach the control plane.

If the control plane dies, existing proxies will continue to operate with the
latest service discovery information. If Additionally, they will fall back to
DNS if asked to route to a service they don't have information for. (Thus, if
the control plane is down, but new services are created, you may notice
different load balancing behavior until the control plane resumes.) Once the
control plane is functional, the Linkerd proxies will resume communication as
normal.

If *new* proxies are deployed when the control plane is unreachable, these new
proxies will not be able to operate. They will timeout all new requests until
such time as they can reach the control plane.

