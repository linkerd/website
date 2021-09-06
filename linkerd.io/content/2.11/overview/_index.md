+++
title = "Overview"
aliases = [
  "/docs",
  "/documentation",
  "/2.11/",
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

Linkerd has three basic components: a UI, a *data plane*, and a *control
plane*. You run Linkerd by:

1. [Installing the CLI on your local system](../getting-started/#step-1-install-the-cli);
1. [Installing the control plane into your cluster](../getting-started/#step-3-install-linkerd-onto-the-cluster);
1. [Adding your services to Linkerd's data plane](../tasks/adding-your-service/).

Once a service is running with Linkerd, you can use [Linkerd's
UI](../getting-started/#step-4-explore-linkerd) to inspect and
manipulate it.

You can [get started](../getting-started/) in minutes!

## How it works

Linkerd works by installing a set of ultralight, transparent proxies next to
each service instance. These proxies automatically handle all traffic to and
from the service. Because they're transparent, these proxies act as highly
instrumented out-of-process network stacks, sending telemetry to, and receiving
control signals from, the control plane. This design allows Linkerd to measure
and manipulate traffic to and from your service without introducing excessive
latency.

In order to be as small, lightweight, and safe as possible, Linkerd's proxies
are written in [Rust](https://www.rust-lang.org/) and specialized for Linkerd.
You can learn more about the proxies in the [Linkerd proxy
repo](https://github.com/linkerd/linkerd2-proxy).

## Versions and channels

Linkerd is currently published in several tracks:

* [Linkerd 2.x stable releases](/edge/)
* [Linkerd 2.x edge releases.](/edge/)
* [Linkerd 1.x.](/1/overview/)

## Next steps

[Get started with Linkerd](../getting-started/) in minutes, or check out the
[architecture](../reference/architecture/) for more details on Linkerd's
components and how they all fit together.
