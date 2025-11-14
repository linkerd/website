---
title: Retries and Timeouts
description: Linkerd can perform service-specific retries and timeouts.
weight: 3
---

Automatic retries are one the most powerful and useful mechanisms a service mesh
has for gracefully handling partial or transient application failures. If
implemented incorrectly retries can amplify small errors into system wide
outages. For that reason, we made sure they were implemented in a way that would
increase the reliability of the system while limiting the risk.

Timeouts work hand in hand with retries. Once requests are retried a certain
number of times, it becomes important to limit the total amount of time a client
waits before giving up entirely. Imagine a number of retries forcing a client to
wait for 10 seconds.

A [service profile](service-profiles/) may define certain routes as retryable or
specify timeouts for routes. This will cause the Linkerd proxy to perform the
appropriate retries or timeouts when calling that service. Retries and timeouts
are always performed on the _outbound_ (client) side.

{{< note >}}

If working with headless services, service profiles cannot be retrieved. Linkerd
reads service discovery information based off the target IP address, and if that
happens to be a pod IP address then it cannot tell which service the pod belongs
to.

{{< /note >}}

These can be setup by following the guides:

- [Configuring Retries](../tasks/configuring-retries/)
- [Configuring Timeouts](../tasks/configuring-timeouts/)

## How Retries Can Go Wrong

Traditionally, when performing retries, you must specify a maximum number of
retry attempts before giving up. Unfortunately, there are two major problems
with configuring retries this way.

### Choosing a maximum number of retry attempts is a guessing game

You need to pick a number that’s high enough to make a difference; allowing more
than one retry attempt is usually prudent and, if your service is less reliable,
you’ll probably want to allow several retry attempts. On the other hand,
allowing too many retry attempts can generate a lot of extra requests and extra
load on the system. Performing a lot of retries can also seriously increase the
latency of requests that need to be retried. In practice, you usually pick a
maximum retry attempts number out of a hat (3?) and then tweak it through trial
and error until the system behaves roughly how you want it to.

### Systems configured this way are vulnerable to retry storms

A [retry storm](https://twitter.github.io/finagle/guide/Glossary.html) begins
when one service starts (for any reason) to experience a larger than normal
failure rate. This causes its clients to retry those failed requests. The extra
load from the retries causes the service to slow down further and fail more
requests, triggering more retries. If each client is configured to retry up to 3
times, this can quadruple the number of requests being sent! To make matters
even worse, if any of the clients’ clients are configured with retries, the
number of retries compounds multiplicatively and can turn a small number of
errors into a self-inflicted denial of service attack.

## Retry Budgets to the Rescue

To avoid the problems of retry storms and arbitrary numbers of retry attempts,
retries are configured using retry budgets. Rather than specifying a fixed
maximum number of retry attempts per request, Linkerd keeps track of the ratio
between regular requests and retries and keeps this number below a configurable
limit. For example, you may specify that you want retries to add at most 20%
more requests. Linkerd will then retry as much as it can while maintaining that
ratio.

Configuring retries is always a trade-off between improving success rate and not
adding too much extra load to the system. Retry budgets make that trade-off
explicit by letting you specify exactly how much extra load your system is
willing to accept from retries.
