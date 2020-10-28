+++
title = "Load Balancing"
description = "Linkerd automatically load balances requests across all destination endpoints on HTTP, HTTP/2, and gRPC connections."
weight = 9
+++

For HTTP, HTTP/2, and gRPC connections, Linkerd automatically load balances
requests across all destination endpoints without any configuration required.
(For TCP connections, Linkerd will balance connections.)

Linkerd uses an algorithm called EWMA, or *exponentially weighted moving average*,
to automatically send requests to the fastest endpoints. This load balancing can
improve end-to-end latencies.

## Service discovery

For destinations that are not in Kubernetes, Linkerd will balance across
endpoints provided by DNS.

For destinations that *are* in Kubernetes, Linkerd will read service discovery
information based off the tarpet IP address rather than relying on DNS. If the
IP address is not assigned to a Service, then there will be no discovery
information.

{{< note >}}
This means that load balancing will not work if the service is exposed as a
headless service. There is no way to tell which service the pod IP address
belongs to and therefore it cannot retrieve all available endpoints.
{{< /note >}}

## Load balancing gRPC

Linkerd's load balancing is particularly useful for gRPC (or HTTP/2) services
in Kubernetes, for which [Kubernetes's default load balancing is not
effective](https://kubernetes.io/blog/2018/11/07/grpc-load-balancing-on-kubernetes-without-tears/).
