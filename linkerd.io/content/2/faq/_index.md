+++
title = "Frequently Asked Questions"
include_toc = true
weight = 9
aliases = [
  "/doc/0.1.0/faq/",
  "/2/roadmap/"
]
[sitemap]
  priority = 1.0
+++

<!-- markdownlint-disable MD026 -->

## What is Linkerd?

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
data plane. Operators typically interact with Linkerd using the [CLI](/2/cli/)
and the [web dashboard UI](/2/getting-started/#step-4-explore-linkerd).

## Who owns Linkerd and how is it licensed?

Linkerd is hosted by the [Cloud Native Computing Foundation](https://cncf.io)
(CNCF) project. The CNCF owns the trademark; the copyright is held by the
Linkerd authors themselves.

Linkerd is licensed under [Apache
2.0](https://github.com/linkerd/linkerd2/blob/master/LICENSE).

## Who is Linkerd for?

Linkerd is for everyone. In practice, Linkerd has certain technical
prerequisites. Read on below.

## How do I pronounce Linkerd?

The "d" is pronounced separately, i.e. "Linker-DEE". (It's a UNIX thing.)

## How do I write Linkerd?

Just like this: Linkerd. Capital "L", lower-case everything else.

## Who maintains Linkerd?

See the [2.x
maintainers](https://github.com/linkerd/linkerd2/blob/master/MAINTAINERS.md)
file, and the [1.x
maintainers](https://github.com/linkerd/linkerd/blob/master/MAINTAINERS.md)
file.

## Is there an Enterprise edition, or a commercial edition?

No. Everything in Linkerd is fully open source. Some companies provide
[commercial support for Linkerd](https://linkerd.io/enterprise/).

## What's the difference between Linkerd 1.x and 2.x?

Linkerd 1.x is built on the "Twitter stack": Finagle, Netty, Scala, and the
JVM.

Linkerd 2.x is built in Rust and Go. It is significantly faster and
lighter weight than 1.x, but currently only supports Kubernetes.

## Is Linkerd 1.x still supported?

Yes, the 1.x branch of Linkerd is under active development, and continues
to power the production infrastructure of companies around the globe.

[The full Linkerd 1.x documentation is here](/1/).

## Does Linkerd require Kubernetes?

Linkerd 2.x currently requires Kubernetes, though this will change in the
future. Linkerd 1.x can be installed on any platform, and supports Kubernetes,
DC/OS, Mesos, Consul, and ZooKeeper-based environments.

## Where's the Linkerd roadmap?

As a community project, there is no official roadmap. A glance at the [active
GitHub issues](https://github.com/linkerd/linkerd2/issues) will give you a
sense of what is in store for the future.

The public [Linkerd Meetup
slides](https://docs.google.com/presentation/d/1qseWDYWD4KzYFhb4bcp8WuDPYFVwB8sYeNnjCsgDUOw/edit)
also provides a coarse-grained roadmap.

## How secure is Linkerd?

Very secure. A [third party security audit of Linkerd
2.x](https://github.com/linkerd/linkerd2/blob/master/SECURITY_AUDIT.pdf) was
completed in June 2019, and Linkerd passed with flying colors.

## How fast is Linkerd?

Very fast. A [third party performance evaluation of Linkerd vs
Istio](https://linkerd.io/2019/05/18/linkerd-benchmarks/) was performed in May
of 2019, and showed that Linkerd significantly outperformed Istio.

## How do I use Linkerd to route traffic between services?

(2.x) Linkerd doesn't change the way routing works. You address other services just
as you would without Linkerd, e.g. `service-name.namespace.svc.cluster.local`,
or `service-name` if within the same namespace.

## How does Linkerd handle ingress?

(2.x) For reasons of simplicity, Linkerd doesn't provide ingress itself, but
instead [works in conjunction with the ingress
controller](https://linkerd.io/2/features/ingress/) of your choice.

## What happens to Linkerd's proxies if the control plane is down?

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

<!-- markdownlint-enable MD026 -->
