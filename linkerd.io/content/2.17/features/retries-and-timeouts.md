---
title: Retries and Timeouts
description: Linkerd can perform service-specific retries and timeouts.
weight: 3
---

Timeouts and automatic retries are two of the most powerful mechanisms a service
mesh has for gracefully handling partial or transient application failures.

* **Timeouts** allow Linkerd to cancel a request that is exceeding a time
  limit.
* **Retries** allow Linkerd to automatically retry failed requests, potentially
  sending it to a different endpoint.

Timeouts and retries are configured with a set of annotations, e.g
`retry.linkerd.io/http` and `timeout.linkerd.io/request`. These annotations are
placed on [HTTPRoute] or [GRPCRoute] resources to configure behavior on HTTP or
gRPC requests that match those resources. Alternatively, they can be placed on
`Service` resources configure retries and timeouts for all traffic to that
service.

As of Linkerd 2.16, timeouts and retries *compose*: requests that timeout are
eligible for being retried.

{{< note >}}
Note that retries and timeouts are performed on the *outbound* (client) side.
This means that regardless of where the annotations are placed, the source of
the traffic must be meshed.
{{< /note >}}

{{< note >}}
Retries and timeouts do not work with headless services.  This is because
Linkerd reads service discovery information based off the target IP address, and
if that happens to be a pod IP address then it cannot tell which service the pod
belongs to.
{{< /note >}}

{{< warning >}}
Prior to Linkerd 2.16, retries and timeouts were configured with
[ServiceProfile](../../reference/service-profiles)s. While service profiles are
still supported, retries configured with HTTPRoute or GPRCRoute are
**incompatible with ServiceProfiles**. If a ServiceProfile is defined for a
Service, proxies will use the ServiceProfile retry configuration and ignore any
retry annotations.
{{< /warning >}}

## Using retries safely

Retries are an opt-in behavior that require some thought and planning. Misuse
can be dangerous. First, automatically retrying a request that changes system
state each time it is called can be disastrous. Thus, retries should only be
used on _idempotent_ methods, i.e. methods that have the same effect even if
called multiple times.

Second, retries by definition will increase the load on your system. A set of
services that have requests being constantly retried could potentially get taken
down by the retries instead of being allowed time to recover.

The exact configuration of retry behavior to improve overall reliability
without significantly increasing risk will require some care on the part of the
user.

## Further reading

* [Retries reference](../../reference/retries/)
* [Timeout reference](../../reference/timeouts/)
* The [Debugging HTTP applications with per-route
  metrics](../../tasks/books/) contains examples of retries and timeout
  annotations.

[HTTPRoute]: ../../reference/httproute/
[GRPCRoute]: ../../reference/grpcroute/
