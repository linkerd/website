---
title: Frequently Asked Questions
include_toc: true
weight: 9
aliases:
  - '/doc/0.1.0/faq/'
  - '/2/roadmap/'
sitemap:
  - priority = 1.0
schema: |
  {
    "@context": "https://schema.org",
    "@type": "FAQPage",
    "mainEntity": [{
      "@type": "Question",
      "name": "What is Linkerd?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Linkerd is a service mesh. It adds observability, reliability, and security to cloud native applications without requiring code changes. For example, Linkerd can monitor and report per-service success rates and latencies, can automatically retry failed requests, and can encrypt and validate connections between services, all without requiring any modification of the application itself."
      }
    }, {
      "@type": "Question",
      "name": "What's the difference between Linkerd and Istio?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Linkerd is committed to open governance and is hosted by a neutral foundation. Istio is primarily controlled by Google."
      }
    }, {
      "@type": "Question",
      "name": "What's the difference between Linkerd and Envoy?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Envoy is a proxy, not a service mesh. Linkerd is a service mesh: it has a control plane and a data plane, and the data plane is implemented with proxies. Envoy can be used as a component of a service mesh, but Linkerd uses a different proxy, simply called linkerd2-proxy."
      }
    }, {
      "@type": "Question",
      "name": "Why doesn't Linkerd use Envoy?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Envoy is a general-purpose proxy. By using linkerd2-proxy, which is built specifically for the service mesh sidecar use case, Linkerd can be significantly smaller and faster than Envoy-based service meshes. Additionally, the choice of Rust for linkerd2-proxy allows Linkerd to avoid a whole class of CVEs and vulnerabilities that can impact proxies written in non-memory-safe languages like C++—a critical requirement for security-focused projects like Linkerd."
      }
    }, {
      "@type": "Question",
      "name": "Who owns Linkerd?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Linkerd is hosted by the Cloud Native Computing Foundation (CNCF) project. The CNCF owns the trademark; the copyright is held by the Linkerd authors themselves."
      }
    }, {
      "@type": "Question",
      "name": "Who is Linkerd for?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Linkerd is for everyone—see Linkerd's Commitment to Open Governance. In practice, Linkerd has certain technical prerequisites, such as Kubernetes."
      }
    }, {
      "@type": "Question",
      "name": "How do I pronounce Linkerd?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "The “d” is pronounced separately, i.e. Linker-DEE. It's a UNIX thing."
      }
    }, {
      "@type": "Question",
      "name": "Who maintains Linkerd?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "See the 2.x maintainers file, and the 1.x maintainers file."
      }
    }, {
      "@type": "Question",
      "name": "Is there an Enterprise edition, or a commercial edition?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Linkerd is fully open source. Some companies provide commercial packages or support for Linkerd."
      }
    }, {
      "@type": "Question",
      "name": "What's the difference between Linkerd 1.x and 2.x?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Linkerd 1.x is built on the “Twitter stack”: Finagle, Netty, Scala, and the JVM. Linkerd 2. x is built in Rust and Go.It is significantly faster and lighter weight than 1. x, but currently only supports Kubernetes."
      }
    }, {
      "@type": "Question",
      "name": "Is Linkerd 1.x still supported?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Yes, the 1.x branch of Linkerd is under active development, and continues to power the production infrastructure of companies around the globe."
      }
    }, {
      "@type": "Question",
      "name": "Does Linkerd require Kubernetes?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Linkerd 2.x currently requires Kubernetes. Linkerd 1.x can be installed on any platform, and supports Kubernetes, DC/OS, Mesos, Consul, and ZooKeeper-based environments."
      }
    }, {
      "@type": "Question",
      "name": "Where's the Linkerd roadmap?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "As a community project, there is no formal roadmap, but a glance at the active GitHub issues will give you a sense of what is in store for the future."
      }
    }, {
      "@type": "Question",
      "name": "How secure is Linkerd?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Very secure. A third party security audit of Linkerd 2.x was completed in June 2019, and Linkerd passed with flying colors."
      }
    }, {
      "@type": "Question",
      "name": "How fast is Linkerd?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Very fast. A third party performance evaluation of Linkerd vs Istio was performed in May of 2019, and showed that Linkerd significantly outperformed Istio."
      }
    }, {
      "@type": "Question",
      "name": "How do I use Linkerd to route traffic between services?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Linkerd doesn't change the way routing works. You address other services just as you would without Linkerd, e.g. service-name.namespace.svc.cluster.local, or service-name if within the same namespace."
      }
    }, {
      "@type": "Question",
      "name": "How does Linkerd handle ingress?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "For reasons of simplicity, Linkerd doesn't provide ingress itself, but instead works in conjunction with the ingress controller of your choice."
      }
    }, {
      "@type": "Question",
      "name": "What happens to Linkerd's proxies if the control plane is down?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "If new proxies are deployed when the control plane is unreachable, these new proxies will not be able to operate. They will timeout all new requests until such time as they can reach the control plane."
      }
    }]
  }
---

<!-- markdownlint-disable MD026 -->

## What is Linkerd?

Linkerd is a [service
mesh](https://blog.buoyant.io/2017/04/25/whats-a-service-mesh-and-why-do-i-need-one/).
It adds observability, reliability, and security to cloud native applications
without requiring code changes. For example, Linkerd can monitor and report
per-service success rates and latencies, can automatically retry failed
requests, and can encrypt and validate connections between services, all
without requiring any modification of the application itself.

Linkerd works by inserting ultralight proxies (collectively, the "data plane")
alongside each application instance. Linkerd's control plane provides operators
with a uniform point at which they can control and measure the behavior of the
data plane. Operators typically interact with Linkerd using the [CLI](/2/cli/)
and the [web dashboard UI](/2/getting-started/#step-4-explore-linkerd).

## What's the difference between Linkerd and Istio?

Linkerd and [Istio](https://istio.io) are both service meshes. While the two
projects share similar goals, there are some significant design differences:

1. Linkerd is focused on simplicity, speed, and low resource usage. It is
significantly [smaller and
faster](https://linkerd.io/2019/05/18/linkerd-benchmarks) than Istio, though it
currently has fewer features.

2. Linkerd is built for security from the ground up, ranging from features like
[on-by-default mTLS](https://linkerd.io/2/features/automatic-mtls/), a data
plane that is [built in a memory-safe
language](https://github.com/linkerd/linkerd2-proxy), and [regular security
audits](https://github.com/linkerd/linkerd2/blob/main/SECURITY_AUDIT.pdf).

3. Linkerd is [committed to open
governance](https://linkerd.io/2019/10/03/linkerds-commitment-to-open-governance/)
and is hosted by [a neutral foundation](https://cncf.io). Istio is [primarily
controlled by Google](https://www.protocol.com/google-open-source-istio).

Of course, the choice of which service mesh to use depends on the specifics of
the situation. Both Linkerd and Istio operate at the cluster level, and so it's
possible (and not unheard of) to run both within the same organization.

## What's the difference between Linkerd and Envoy?

[Envoy](https://envoyproxy.io) is a proxy, not a service mesh. Linkerd is a
service mesh: it has a control plane and a data plane, and the data plane is
implemented with proxies. Envoy can be used as a *component* of a service mesh,
but Linkerd uses a different proxy, simply called
[linkerd2-proxy](https://github.com/linkerd/linkerd2-proxy).

## Why doesn't Linkerd use Envoy?

Envoy is a general-purpose proxy. By using
[linkerd2-proxy](https://github.com/linkerd/linkerd2-proxy), which is built
specifically for the service mesh sidecar use case, Linkerd can be
significantly smaller and faster than Envoy-based service meshes. Additionally,
the choice of Rust for linkerd2-proxy allows Linkerd to avoid a whole class of
CVEs and vulnerabilities that can impact proxies written in non-memory-safe
languages like C++&mdash;a critical requirement for security-focused projects
like Linkerd.

## Who owns Linkerd and how is it licensed?

Linkerd is hosted by the [Cloud Native Computing Foundation](https://cncf.io)
(CNCF) project. The CNCF owns the trademark; the copyright is held by the
Linkerd authors themselves.

Linkerd is licensed under [Apache
2.0](https://github.com/linkerd/linkerd2/blob/main/LICENSE).

## Who is Linkerd for?

Linkerd is for everyone&mdash;see [Linkerd's Commitment to Open
Governance](https://linkerd.io/2019/10/03/linkerds-commitment-to-open-governance/).
In practice, Linkerd has certain technical prerequisites, such as Kubernetes.

## How do I pronounce Linkerd?

The "d" is pronounced separately, i.e. "Linker-DEE". (It's a UNIX thing.)

## How do I write Linkerd?

Just like this: Linkerd. Capital "L", lower-case everything else.

## Who maintains Linkerd?

See the [2.x
maintainers](https://github.com/linkerd/linkerd2/blob/main/MAINTAINERS.md)
file, and the [1.x
maintainers](https://github.com/linkerd/linkerd/blob/main/MAINTAINERS.md)
file.

## Is there an Enterprise edition, or a commercial edition?

Linkerd is fully open source. Some companies provide
[commercial packages or support for Linkerd](https://linkerd.io/enterprise/).

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

Linkerd 2.x currently requires Kubernetes. Linkerd 1.x can be installed on any
platform, and supports Kubernetes, DC/OS, Mesos, Consul, and ZooKeeper-based
environments.

## Where's the Linkerd roadmap?

As a community project, there is no formal roadmap, but a glance at the [active
GitHub issues](https://github.com/linkerd/linkerd2/issues) will give you a
sense of what is in store for the future.

The public [Linkerd Meetup
slides](https://docs.google.com/presentation/d/1qseWDYWD4KzYFhb4bcp8WuDPYFVwB8sYeNnjCsgDUOw/edit)
also provide a coarse-grained roadmap.

## How secure is Linkerd?

Very secure. A [third party security audit of Linkerd
2.x](https://github.com/linkerd/linkerd2/blob/main/SECURITY_AUDIT.pdf) was
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

## How do I get involved?

See our [Linkerd Community](/community/) page!

<!-- markdownlint-enable MD026 -->
