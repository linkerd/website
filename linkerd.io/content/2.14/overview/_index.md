+++
title = "Overview"
aliases = [
  "/docs",
  "/documentation",
  "/2.15/",
  "../docs/",
  "/doc/network-performance/",
  "/in-depth/network-performance/",
  "/in-depth/debugging-guide/",
  "/in-depth/concepts/"
]
weight = 1
+++

Linkerd is a _service mesh_ for Kubernetes. It makes running services easier
and safer by giving you runtime debugging, observability, reliability, and
security&mdash;all without requiring any changes to your code.

For a brief introduction to the service mesh model, we recommend reading [The
Service Mesh: What Every Software Engineer Needs to Know about the World's Most
Over-Hyped Technology](https://servicemesh.io/).

Linkerd is fully open source, licensed under [Apache
v2](https://github.com/linkerd/linkerd2/blob/main/LICENSE), and is a [Cloud
Native Computing Foundation](https://cncf.io) graduated project. Linkerd is
developed in the open in the [Linkerd GitHub organization](https://github.com/linkerd).

Linkerd has two basic components: a *control plane* and a *data plane*. Once
Linkerd's control plane has been installed on your Kubernetes cluster, you add
the data plane to your workloads (called "meshing" or "injecting" your
workloads) and voila! Service mesh magic happens.

You can [get started with Linkerd](../getting-started/) in minutes!

## How it works

Linkerd works by installing a set of ultralight, transparent "micro-proxies"
next to each service instance. These proxies automatically handle all traffic to
and from the service. Because they're transparent, these proxies act as highly
instrumented out-of-process network stacks, sending telemetry to, and receiving
control signals from, the control plane. This design allows Linkerd to measure
and manipulate traffic to and from your service without introducing excessive
latency.

In order to be as small, lightweight, and safe as possible, Linkerd's
micro-proxies are written in [Rust](https://www.rust-lang.org/) and specialized
for Linkerd. You can learn more about the these micro-proxies in our blog post,
[Under the hood of Linkerd's state-of-the-art Rust proxy,
Linkerd2-proxy](/2020/07/23/under-the-hood-of-linkerds-state-of-the-art-rust-proxy-linkerd2-proxy/),
(If you want to know why Linkerd doesn't use Envoy, you can learn why in our blog
post, [Why Linkerd doesn't use
Envoy](/2020/12/03/why-linkerd-doesnt-use-envoy/).)

## Versions and channels

Linkerd is currently published in several tracks:

* [Linkerd 2.x stable releases](/edge/)
* [Linkerd 2.x edge releases](/edge/)
* [Linkerd 1.x.](/1/overview/)

## Next steps

[Get started with Linkerd](../getting-started/) in minutes, or check out the
[architecture](../reference/architecture/) for more details on Linkerd's
components and how they all fit together.
