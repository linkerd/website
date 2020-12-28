---
title: Frequently Asked Questions
include_toc: true
weight: 9
aliases:
  - '/doc/0.1.0/faq/'
  - '/2/roadmap/'
sitemap:
  - priority = 1.0
---

<!-- markdownlint-disable MD026 -->

## What is Linkerd?

Linkerd is a [service
mesh](https://buoyant.io/2020/10/12/what-is-a-service-mesh/). It adds
observability, reliability, and security to Kubernetes applications without
code changes. For example, Linkerd can monitor and report per-service success
rates and latencies, can automatically retry failed requests, and can encrypt
and validate connections between services, all without requiring any
modification of the application itself.

## What's the difference between Linkerd and Istio?

Linkerd is significantly lighter and simpler than Istio. Both projects are
service meshes and espouse similar features. Linkerd is built for security from
the ground up, ranging from features like [on-by-default
mTLS](https://linkerd.io/2/features/automatic-mtls/), a data plane that is
[built in a memory-safe language](https://github.com/linkerd/linkerd2-proxy),
and [regular security
audits](https://github.com/linkerd/linkerd2/blob/main/SECURITY_AUDIT.pdf).

Finally, Linkerd is [committed to open
governance](https://linkerd.io/2019/10/03/linkerds-commitment-to-open-governance/)
and is hosted by [a neutral foundation](https://cncf.io).

## What's the difference between Linkerd and Envoy?

Envoy is a proxy, not a service mesh. Linkerd is a [service
mesh](https://buoyant.io/2020/10/12/what-is-a-service-mesh/): it has a control
plane and a data plane, of which the proxy is one component. Envoy can be used
as a component of a service mesh, but Linkerd uses a different proxy, simply
called [Linkerd2-proxy](https://github.com/linkerd/linkerd2-proxy).

## Why doesn't Linkerd use Envoy?

Envoy is a complex, general-purpose proxy. Linkerd instead uses
[Linkerd2-proxy](https://github.com/linkerd/linkerd2-proxy), a simple and
ultralight "micro-proxy" built specifically for the service mesh sidecar use
case. This allows Linkerd to be significantly smaller and simpler than
Envoy-based service meshes. Additionally, the choice of Rust for Linkerd2-proxy
allows Linkerd to avoid a whole class of CVEs and vulnerabilities that can
impact proxies written in non-memory-safe languages like C++.

See [Why Linkerd doesn't use
Envoy](https://linkerd.io/2020/12/03/why-linkerd-doesnt-use-envoy/) for more.

## Who owns Linkerd and how is it licensed?

Linkerd is hosted by the [Cloud Native Computing Foundation](https://cncf.io)
(CNCF) project. The CNCF owns the trademark; the copyright is held by the
Linkerd authors themselves.

Linkerd is licensed under the [Apache
2.0](https://github.com/linkerd/linkerd2/blob/main/LICENSE) license.

## Who created Linkerd?

Linkerd was originally created by [Buoyant](https://buoyant.io/linkerd).  While
Linkerd is a CNCF project, Buoyant continues to be a primary maintainer and
sponsor.

## Who is Linkerd for?

Linkerd is for everyone. See [Linkerd's Commitment to Open
Governance](https://linkerd.io/2019/10/03/linkerds-commitment-to-open-governance/).
In practice, Linkerd has certain technical prerequisites, such as Kubernetes.

## How do I pronounce Linkerd?

"Linkerd" rhymes with "Cardi B". The "d" is pronounced separately, as in
"Linker-DEE".

## How do I write Linkerd?

Just like this: Linkerd. Capital "L", lower-case everything else.

## Is there an "enterprise edition"?

No. Linkerd is fully open source with everything you need to run it in
production as part of the open source project.

## Can I get commercial support?

Yes. See the list of companies that provide [commercial support for
Linkerd](https://linkerd.io/enterprise/).

## What's on the Linkerd roadmap?

As a community project, there is no formal roadmap, but a glance at the [active
GitHub issues](https://github.com/linkerd/linkerd2/issues) will give you a
sense of what is in store for the future.

## Can I present Linkerd to my team / company / meetup group?

Certainly. Linkerd is for everyone. The public [Linkerd meetup
slides](https://docs.google.com/presentation/d/1qseWDYWD4KzYFhb4bcp8WuDPYFVwB8sYeNnjCsgDUOw/edit)
might be helpful.

## How do I use Linkerd to route traffic between services?

Linkerd is designed to be fully transparent. You address other services just as
you would without Linkerd, e.g. `service-name.namespace.svc.cluster.local`, or
`service-name` if within the same namespace.

## Does Linkerd handle ingress traffic?

No. For reasons of simplicity, Linkerd doesn't provide ingress itself, but
instead [works in conjunction with the ingress
controller](https://linkerd.io/2/features/ingress/) of your choice.

## What happens to Linkerd's proxies if the control plane is down?

Linkerd's proxies do not integrate with Kubernetes directly, but rely on the
control plane for service discovery information. The proxies are designed to
continue operating even if they can't reach the control plane.

If the control plane dies, existing proxies will continue to operate with the
latest service discovery information. Additionally, they will fall back to DNS
if asked to route to a service they don't have information for. (Thus, if the
control plane is down, but new services are created, you may notice different
load balancing behavior until the control plane resumes.) Once the control
plane is functional, the Linkerd proxies will resume communication as normal.

If *new* proxies are deployed when the control plane is unreachable, these new
proxies will not be able to operate. They will timeout all new requests until
such time as they can reach the control plane.

## What CPU architectures can Linkerd run on?

Linkerd uses multi-arch container images with support for x86, amd64, arm64,
and arm.

## How can I get involved?

We'd love to have your involvement! See our [Linkerd Community page](/community/).

<!-- markdownlint-enable MD026 -->
