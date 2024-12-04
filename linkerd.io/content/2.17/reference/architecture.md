---
title: Architecture
description: Deep dive into the architecture of Linkerd.
---

At a high level, Linkerd consists of a **control plane** and a **data plane**.

The **control plane** is a set of services that and provide control over
Linkerd as a whole.

The **data plane** consists of transparent _micro-proxies_ that run "next" to
each service instance, as sidecar containers in the pods. These proxies
automatically handle all TCP traffic to and from the service, and communicate
with the control plane for configuration.

Linkerd also provides a **CLI** that can be used to interact with the control
and data planes.

![Linkerd's architecture](/docs/images/architecture/control-plane.png "Linkerd's architecture")

## CLI

The Linkerd CLI is typically run outside of the cluster (e.g. on your local
machine) and is used to interact with the Linkerd.

## Control plane

The Linkerd control plane is a set of services that run in a dedicated
Kubernetes namespace (`linkerd` by default). The control plane has several
components, enumerated below.

### The destination service

The destination service is used by the data plane proxies to determine various
aspects of their behavior. It is used to fetch service discovery information
(i.e. where to send a particular request and the TLS identity expected on the
other end); to fetch policy information about which types of requests are
allowed; to fetch service profile information used to inform per-route metrics,
retries, and timeouts; and more.

### The identity service

The identity service acts as a [TLS Certificate
Authority](https://en.wikipedia.org/wiki/Certificate_authority) that accepts
[CSRs](https://en.wikipedia.org/wiki/Certificate_signing_request) from proxies
and returns signed certificates. These certificates are issued at proxy
initialization time and are used for proxy-to-proxy connections to implement
[mTLS](../../features/automatic-mtls/).

### The proxy injector

The proxy injector is a Kubernetes [admission
controller](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/)
that receives a webhook request every time a pod is created. This injector
inspects resources for a Linkerd-specific annotation (`linkerd.io/inject:
enabled`). When that annotation exists, the injector mutates the pod's
specification and adds the `proxy-init` and `linkerd-proxy` containers to the
pod, along with the relevant start-time configuration.

## Data plane

The Linkerd data plane comprises ultralight _micro-proxies_ which are deployed
as sidecar containers inside application pods. These proxies transparently
intercept TCP connections to and from each pod, thanks to iptables rules put in
place by the [linkerd-init](#linkerd-init-container) (or, alternatively, by
Linkerd's [CNI plugin](../../features/cni/)).

### Proxy

The Linkerd2-proxy is an ultralight, transparent _micro-proxy_ written in
[Rust](https://www.rust-lang.org/). Linkerd2-proxy is designed specifically for
the service mesh use case and is not designed as a general-purpose proxy.

The proxy's features include:

* Transparent, zero-config proxying for HTTP, HTTP/2, and arbitrary TCP
  protocols.
* Automatic Prometheus metrics export for HTTP and TCP traffic.
* Transparent, zero-config WebSocket proxying.
* Automatic, latency-aware, layer-7 load balancing.
* Automatic layer-4 load balancing for non-HTTP traffic.
* Automatic TLS.
* An on-demand diagnostic tap API.
* And lots more.

The proxy supports service discovery via DNS and the
[destination gRPC API](https://github.com/linkerd/linkerd2-proxy-api).

You can read more about these micro-proxies here:

* [Why Linkerd doesn't use Envoy](/2020/12/03/why-linkerd-doesnt-use-envoy/)
* [Under the hood of Linkerd's state-of-the-art Rust proxy,
  Linkerd2-proxy](/2020/07/23/under-the-hood-of-linkerds-state-of-the-art-rust-proxy-linkerd2-proxy/)

### Meshed Conncections

When one pod establishes a TCP connection to another pod and both of those pods
are injected with the Linkerd proxy, we say that the connection is *meshed*.
The proxy in the pod that initiated the connection is called the *outbound*
proxy and the proxy in the pod that accepted the connection is called the
*inbound* proxy.

The *outbound* proxy is responsible for service discovery, load balancing,
circuit breakers, retries, and timeouts. The *inbound* proxy is responsible for
enforcing authorization policy. Both *inbound* and *outbound* proxies report
traffic metrics about the traffic they send and receive.

### Linkerd init container

The `linkerd-init` container is added to each meshed pod as a Kubernetes [init
container](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)
that runs before any other containers are started. It [uses
iptables](../iptables/) to route all TCP traffic to and from the pod through
the proxy. Linkerd's init container can be run in [different
modes](../../features/nft/) which determine what iptables variant is used.
