---
title: Load Balancing
description: Linkerd automatically load balances requests across all destination endpoints
  on HTTP, HTTP/2, and gRPC connections.
weight: 9
---

For HTTP, HTTP/2, and gRPC connections, Linkerd automatically load balances
requests across all destination endpoints without any configuration required.
(For TCP connections, Linkerd will balance connections.)

Linkerd uses an algorithm called EWMA, or *exponentially weighted moving average*,
to automatically send requests to the fastest endpoints. This load balancing can
improve end-to-end latencies.

## Service discovery

For destinations that are not in Kubernetes, Linkerd will balance across
endpoints provided by DNS.

For destinations that are in Kubernetes, Linkerd will look up the IP address in
the Kubernetes API. If the IP address corresponds to a Service, Linkerd will
load balance across the endpoints of that Service and apply any policy from that
Service's [Service Profile](../service-profiles/). On the other hand,
if the IP address corresponds to a Pod, Linkerd will not perform any load
balancing or apply any [Service Profiles](../service-profiles/).

{{< note >}}
If working with headless services, endpoints of the service cannot be retrieved.
Therefore, Linkerd will not perform load balancing and instead route only to the
target IP address.
{{< /note >}}

## Load balancing gRPC

Linkerd's load balancing is particularly useful for gRPC (or HTTP/2) services
in Kubernetes, for which [Kubernetes's default load balancing is not
effective](https://kubernetes.io/blog/2018/11/07/grpc-load-balancing-on-kubernetes-without-tears/).
