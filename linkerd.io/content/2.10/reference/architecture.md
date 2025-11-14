---
title: Architecture
description: Deep dive into the architecture of Linkerd.
---

At a high level, Linkerd consists of a _control plane_ and a _data plane_.

The _control plane_ is a set of services that run in a dedicated namespace.
These services accomplish various things---aggregating telemetry data, providing
a user-facing API, providing control data to the data plane proxies, etc.
Together, they drive the behavior of the data plane.

The _data plane_ consists of transparent proxies that are run next to each
service instance. These proxies automatically handle all traffic to and from the
service. Because they're transparent, these proxies act as highly instrumented
out-of-process network stacks, sending telemetry to, and receiving control
signals from, the control plane.

![Linkerd's architecture](/docs/images/architecture/control-plane.png "Linkerd's architecture")

## CLI

The Linkerd CLI is typically run outside of the cluster (e.g. on your local
machine) and is used to interact with the Linkerd control planes.

## Control Plane

The Linkerd control plane is a set of services that run in a dedicated
Kubernetes namespace (`linkerd` by default). The control plane has several
components, enumerated below.

### Controller

The controller component provides an API for the CLI to interface with.

### Destination

The destination component is used by data plane proxies to look up where to send
requests. The destination deployment is also used to fetch service profile
information used for per-route metrics, retries and timeouts.

### Identity

The identity component acts as a
[TLS Certificate Authority](https://en.wikipedia.org/wiki/Certificate_authority)
that accepts [CSRs](https://en.wikipedia.org/wiki/Certificate_signing_request)
from proxies and returns signed certificates. These certificates are issued at
proxy initialization time and are used for proxy-to-proxy connections to
implement [mTLS](../features/automatic-mtls/).

### Proxy Injector

The proxy injector is a Kubernetes [admission controller][admission-controller]
which receives a webhook request every time a pod is created. This injector
inspects resources for a Linkerd-specific annotation
(`linkerd.io/inject: enabled`). When that annotation exists, the injector
mutates the pod's specification and adds the `proxy-init` and `linkerd-proxy`
containers to the pod.

### Service Profile Validator (sp-validator)

The validator is a Kubernetes [admission controller][admission-controller],
which validates new [service profiles](service-profiles/) before they are saved.

[admission-controller]:
  https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/

## Data Plane

The Linkerd data plane comprises ultralight _micro-proxies_, written in Rust,
which are deployed as sidecar containers alongside each instance of your service
code.

These proxies transparently intercept communication to and from each pod by
utilizing iptables rules that are automatically configured by
[linkerd-init](#linkerd-init-container). These proxies are not designed to be
configured by hand. Rather, their behavior is driven by the control plane.

You can read more about these micro-proxies here:

- [Why Linkerd doesn't use Envoy](/2020/12/03/why-linkerd-doesnt-use-envoy/)
- [Under the hood of Linkerd's state-of-the-art Rust proxy, Linkerd2-proxy](/2020/07/23/under-the-hood-of-linkerds-state-of-the-art-rust-proxy-linkerd2-proxy/)

### Proxy

An ultralight transparent _micro-proxy_ written in
[Rust](https://www.rust-lang.org/), the proxy is installed into each pod of a
meshed workload, and handles all incoming and outgoing TCP traffic to/from that
pod. This model (called a "sidecar container" or "sidecar proxy") allows it to
add functionality without requiring code changes.

The proxy's features include:

- Transparent, zero-config proxying for HTTP, HTTP/2, and arbitrary TCP
  protocols.
- Automatic Prometheus metrics export for HTTP and TCP traffic.
- Transparent, zero-config WebSocket proxying.
- Automatic, latency-aware, layer-7 load balancing.
- Automatic layer-4 load balancing for non-HTTP traffic.
- Automatic TLS.
- An on-demand diagnostic tap API.
- And lots more.

The proxy supports service discovery via DNS and the
[destination gRPC API](https://github.com/linkerd/linkerd2-proxy-api).

### Linkerd Init Container

The `linkerd-init` container is added to each meshed pod as a Kubernetes
[init container](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)
that runs before any other containers are started. It
[uses iptables](https://github.com/linkerd/linkerd2-proxy-init) to route all TCP
traffic to and from the pod through the pod.

There are two main rules that `iptables` uses:

- Any traffic being sent to the pod's external IP address (10.0.0.1 for example)
  is forwarded to a specific port on the proxy (4143). By setting
  `SO_ORIGINAL_DST` on the socket, the proxy is able to forward the traffic to
  the original destination port that your application is listening on.
- Any traffic originating from within the pod and being sent to an external IP
  address (not 127.0.0.1) is forwarded to a specific port on the proxy (4140).
  Because `SO_ORIGINAL_DST` was set on the socket, the proxy is able to forward
  the traffic to the original recipient (unless there is a reason to send it
  elsewhere). This does not result in a traffic loop because the `iptables`
  rules explicitly skip the proxy's UID.

{{< note >}}

By default, most ports are forwarded through the proxy. This is not always
desirable and it is possible to have specific ports skip the proxy entirely for
both incoming and outgoing traffic. See the
[protocol detection](../features/protocol-detection/) documentation.

{{< /note >}}
