---
title: Frequently Asked Questions
description: |-
  What is Linkerd? What’s the difference between Linkerd and Istio? Why doesn’t
  Linkerd use Envoy? Get answers to these questions and more.
type: docs
sitemap:
  priority: 1.0
---

{{< docs/toc >}}

## What is Linkerd?

Linkerd is a [service mesh](/what-is-a-service-mesh/). It adds observability,
reliability, and security to Kubernetes applications without code changes. For
example, Linkerd can monitor and report per-service success rates and latencies,
can automatically retry failed requests, and can encrypt and validate
connections between services, all without requiring any modification of the
application itself.

## What's the difference between Linkerd and Istio?

Linkerd is significantly lighter and simpler than Istio. Linkerd is built for
security from the ground up, ranging from features like
[on-by-default mTLS](https://linkerd.io/2/features/automatic-mtls/), a data
plane that is
[built in a Rust, memory-safe language](https://github.com/linkerd/linkerd2-proxy),
and
[regular security audits](https://github.com/linkerd/linkerd2/blob/main/SECURITY_AUDIT.pdf).
Finally, Linkerd has publicly
[committed to open governance](/2019/10/03/linkerds-commitment-to-open-governance/)
and is hosted by [the CNCF](https://cncf.io).

## What's the difference between Linkerd and Envoy?

Envoy is a proxy; Linkerd is a [service mesh](/what-is-a-service-mesh/). Linkerd
has a control plane and a data plane, and uses a proxy is a component of the
data plane. While Envoy can be used as a component of a service mesh, Linkerd
uses an ultralight "micro-proxy" called
[Linkerd2-proxy](https://github.com/linkerd/linkerd2-proxy), which is built in
Rust for safety and performance.

## Why doesn't Linkerd use Envoy?

Envoy is a complex general-purpose proxy. Linkerd uses a simple and ultralight
"micro-proxy" called [Linkerd2-proxy](https://github.com/linkerd/linkerd2-proxy)
that is built specifically for the service mesh sidecar use case. This allows
Linkerd to be significantly smaller and simpler than Envoy-based service meshes.
The choice of Rust also allows Linkerd to avoid a whole class of CVEs and
vulnerabilities that can impact proxies written in non-memory-safe languages
like C++. See
[Why Linkerd doesn't use Envoy](/2020/12/03/why-linkerd-doesnt-use-envoy/) for
more.

## Who owns Linkerd and how is it licensed?

Linkerd is hosted by the
[Cloud Native Computing Foundation (CNCF)](https://cncf.io). The CNCF owns the
trademark; the copyright is held by the Linkerd authors themselves. Linkerd is
licensed under the
[Apache 2.0](https://github.com/linkerd/linkerd2/blob/main/LICENSE) license.

## Who created Linkerd?

Linkerd was originally created by [Buoyant](https://buoyant.io/linkerd). Buoyant
is the primary sponsor of the project and provides commercial support.

## Who is Linkerd for?

Linkerd is for everyone. (See
[Linkerd's Commitment to Open Governance](/2019/10/03/linkerds-commitment-to-open-governance/).)
In practice, Linkerd has certain technical prerequisites, such as Kubernetes.

## How do I pronounce Linkerd?

Linkerd rhymes with "Cardi B". The "d" is pronounced separately, as in
"Linker-DEE".

## How do I write Linkerd?

Just like this: Linkerd. Capital "L", lower-case everything else.

## Is there a Linkerd enterprise edition?

Yes, enterprise distributions of Linkerd are available from Buoyant (creators of
Linkerd) as well as other companies. See the list of companies that provide
[commercial distributions of Linkerd](/enterprise/).

## Can I get commercial support?

Yes. See the list of companies that provide
[commercial support for Linkerd](/enterprise/).

## What's on the Linkerd roadmap?

See the
[Linkerd project roadmap](https://github.com/linkerd/linkerd2/blob/main/ROADMAP.md).
You may also review the
[active GitHub issues](https://github.com/linkerd/linkerd2/issues) for
shorter-term objectives.

## Can I present Linkerd to my team / company / meetup group?

Certainly! The public
[Linkerd meetup slides](https://docs.google.com/presentation/d/1qseWDYWD4KzYFhb4bcp8WuDPYFVwB8sYeNnjCsgDUOw/edit)
might be helpful.

## How do I use Linkerd to route traffic between services?

Linkerd is designed to be fully transparent. You address other services just as
you would without Linkerd, e.g. `service-name.namespace.svc.cluster.local`, or
`service-name` if within the same namespace.

## Does Linkerd handle ingress traffic?

" No. For reasons of simplicity, Linkerd doesn't provide ingress itself, but
instead
[works in conjunction with the ingress controller](https://linkerd.io/2/features/ingress/)
of your choice."

## What happens to Linkerd's proxies if the control plane is down?

Linkerd's proxies do not integrate with Kubernetes directly, but rely on the
control plane for service discovery information. The proxies are designed to
continue operating even if they can't reach the control plane. If the control
plane dies, existing proxies will continue to operate with the latest service
discovery information. Additionally, they will fall back to DNS if asked to
route to a service they don't have information for. (Thus, if the control plane
is down, but new services are created, you may notice different load balancing
behavior until the control plane resumes.) Once the control plane is functional,
the Linkerd proxies will resume communication as normal. If _new_ proxies are
deployed when the control plane is unreachable, these new proxies will not be
able to operate. They will timeout all new requests until such time as they can
reach the control plane.

## What CPU architectures can Linkerd run on?

Linkerd uses multi-arch container images with support for x86, amd64, arm64, and
arm.

## How can I get involved?

We'd love to have you get involved! See our
[Linkerd Community page](/community/get-involved/).
