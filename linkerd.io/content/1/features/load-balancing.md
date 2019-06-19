+++
aliases = ["/features/load-balancing"]
description = "Linkerd provides multiple load-balancing algorithms that use real-time performance metrics to distribute load and reduce tail latencies across your application."
title = "Load balancing"
weight = 2
[menu.docs]
parent = "features"
weight = 11

+++
Load balancing is a critical component of any scalable software system. By
distributing traffic intelligently across a set of endpoints---even as that set
changes dynamically, and as endpoints fail or slow down---good load balancing
can reduce tail latencies and increase reliability. Linkerd offers a variety of
powerful load-balancing algorithms, including *least loaded*, *EWMA*, and
*aperture*. These algorithms have been tested at scale at Twitter and other
companies.

Because Linkerd operates at the RPC layer, it can balance load based on observed
RPC latencies and queue sizes, rather than heuristics such as LRU or TCP
activity. This means it can optimize traffic flow and reduce tail latencies
across the application. Because Linkerd is built on top of Finagle, it can take
advantage of a variety of load-balancing algorithms, which are designed to
maximize the number of requests that are served successfully while minimizing
latencies.

The load-balancing algorithms available to Linkerd are described below. They're
also covered in more detail in Finagle's [load balancing](
https://twitter.github.io/finagle/guide/Clients.html#load-balancing)
documentation.

## Load balancer options

Picking the right load balancer for your setup depends at least partly on your
application topology. Linkerd provides a sane default for most installs and
allows you to swap in other balancers as needed.

### Power of Two Choices (P2C): Least Loaded

This is Linkerd's default load balancer, and it is surprisingly simple. When
determining where to send a request, Linkerd picks two replicas from the load
balancer pool at random, and it selects the one that is the least loaded of the
two. Load is determined by the number of outstanding requests to each replica.
This algorithm provides a manageable upper bound on load for individual
replicas. It does so using less overhead than other algorithms with similar
performance.

### Power of Two Choices: Peak EWMA

This load balancer is a variation on the P2C: Least Loaded strategy from above,
in that it is still picking between two replicas when sending a request. To make
that decision, it maintains a moving average of observed latencies, and uses
that to weight the number of outstanding requests to each replica. This approach
is more sensitive to fluctuations in latency and allows slower backends time to
recover by sending them fewer requests. The latency window is configurable.

### Aperture: Least Loaded

The aperture load balancer is appropriate for clients that are sending a
relatively small amount of traffic to a backend with a relatively large amount
of replicas. It constrains the number of replicas to which it sends traffic to
some subset of the full replica set, and then picks the replica that has the
least number of outstanding requests. This approach ensures a higher rate of
connection reuse at low traffic volumes.

### Heap: Least Loaded

This load balancer uses a min heap to track the number of outstanding requests
to all replicas. It sends all requests to the top replica in the heap, which is
the one that is the least loaded at time of request, and will change over time.
One notable limitation of this approach is that the heap is a shared resource
across all requests, and therefore will cause contention issues with high
volumes of traffic.

## More information

If you'd like to learn more about how various different load-balancing
algorithms compare performance-wise, check out Buoyant's blog post on the topic:
[Beyond Round Robin: Load Balancing for Latency](
https://blog.buoyant.io/2016/03/16/beyond-round-robin-load-balancing-for-latency/).

If you're ready to start configuring load balancing in your setup, see the [Load
Balancer]({{% linkerdconfig "load-balancer" %}}) section of the Linkerd
configuration reference.
