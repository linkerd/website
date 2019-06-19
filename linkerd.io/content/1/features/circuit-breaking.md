+++
aliases = ["/features/circuit-breaking"]
description = "Linkerd includes automatic circuit breaking that will stop sending traffic to instances that are deemed to be unhealthy, giving them a chance to recover and avoiding cascading failures."
title = "Circuit breaking"
weight = 3
[menu.docs]
parent = "features"
weight = 18

+++
Circuit breaking is a mechanism used by Linkerd to remove unhealthy service
instances from [load balancing]({{% ref "/1/features/load-balancing.md" %}}).
Unhealthy instances can be detected at both the connection level and the request
level. By employing circuit breaking, Linkerd can minimize the amount of time
spent trying to route requests that ultimately fail, thereby freeing up
resources and avoiding a common cause of cascading failures.

The two types of circuit breaking that Linkerd provides are described below.
They're also addressed more extensively in Finagle's [circuit breaking](
https://twitter.github.io/finagle/guide/Clients.html#circuit-breaking)
documentation.

## Fail fast

Fail fast circuit breaking happens at the connection level. When fail fast is
enabled, if Linkerd sees a connection error when attempting to send a request to
one of your service's hosts, Linkerd will remove that connection from its
connection pool. In the background, Linkerd attempts to reestablish the
connection, without actively trying to send it traffic. Only once the connection
is successfully reestablished will it be added back into the pool and start
receiving traffic again.

Fail fast is disabled by default in Linkerd, since it can be problematic when
proxying requests to services with a small number of hosts. If a service has
only one host, removing the only connection to that host from the load balancer
pool would fail all requests to that service until the connection can be
reestablished. In that case it's better to leave the connection in the pool and
continue to send requests. For larger services, however, fail fast can be
useful, and it can be enabled on a per-router basis by [setting the `failFast`
parameter]({{% linkerdconfig "router-parameters" %}}) when configuring routers.

## Failure accrual

Failure accrual circuit breaking operates at the request level, based on the
number of requests that have failed for a given host. By default, if Linkerd
receives 5 consecutive failures from a host, it will temporarily mark the host
as dead, giving it a grace period to recover before resending requests. Once a
host has been marked dead, Linkerd will attempt to resend traffic to that host
based on a backoff interval. Both the threshold for marking a host as dead and
the backoff interval are fully configurable by [setting the client
`failureAccrual` parameter]({{% linkerdconfig "failure-accrual" %}}). In
addition to consecutive failures, other available threshold calculations include
observed success rate over a given number of requests, and observed success rate
over a given time window.

Failure accrual uses response classification to determine which types of
responses count as failures. Response classification can be configured on a
per-router basis by [setting the router `responseClassifier` parameter](
{{% linkerdconfig "http-response-classifiers" %}}) when configuring routers.

## More information

If you'd like to learn more about the performance impacts of various
circuit breaking settings, check out Buoyant's blog post on the topic:
[Making microservices more resilient with circuit breaking](
https://blog.buoyant.io/2017/01/13/making-microservices-more-resilient-with-circuit-breaking/).
