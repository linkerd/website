---
title: Retries and Timeouts
description: Linkerd can retry and timeout HTTP and gRPC requests.
weight: 3
---

Timeouts and automatic retries are two of the most powerful mechanisms a service
mesh has for gracefully handling partial or transient application failures.

- **Timeouts** allow Linkerd to cancel a request that is exceeding a time limit.
- **Retries** allow Linkerd to automatically retry failed requests, potentially
  sending it to a different endpoint.

Timeouts and retries are configured with a set of annotations, e.g
`retry.linkerd.io/http` and `timeout.linkerd.io/request`. These annotations are
placed on [HTTPRoute] or [GRPCRoute] resources to configure behavior on HTTP or
gRPC requests that match those resources. Alternatively, they can be placed on
`Service` resources configure retries and timeouts for all traffic to that
service.

As of Linkerd 2.16, timeouts and retries _compose_: requests that timeout are
eligible for being retried.

{{< note >}}

Note that retries and timeouts are performed on the _outbound_ (client) side.
This means that regardless of where the annotations are placed, the source of
the traffic must be meshed.

{{< /note >}}

{{< note >}}

Retries and timeouts do not work with headless services. This is because Linkerd
reads service discovery information based off the target IP address, and if that
happens to be a pod IP address then it cannot tell which service the pod belongs
to.

{{< /note >}}

{{< warning >}}

Prior to Linkerd 2.16, retries and timeouts were configured with
[ServiceProfile](../reference/service-profiles/)s. While service profiles are
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

The exact configuration of retry behavior to improve overall reliability without
significantly increasing risk will require some care on the part of the user.

## Per-request policies

In addition to the annotation approach outlined above, retries and timeouts can
be set on a per-request basis by setting specific HTTP headers.

In order to enable this per-request policy, Linkerd must be installed with the
`--set policyController.additionalArgs="--allow-l5d-request-headers"` flag or
the corresponding Helm value.

{{< warning >}}

Per-request policies should **not** be enabled if your application accepts
unfiltered requests from untrusted sources. For example, if you mesh an ingress
controller which takes unfiltered Internet traffic (and you do not use
`skip-inbound-ports` to instruct Linkerd to skip handling inbound traffic to the
pod), untrusted clients will be able to specify Linkerd retry and timeout policy
on their requests.

{{< /warning >}}

Once per-request policy is enabled, you can set timeout and retry policy on
individual requests by setting these headers:

- `l5d-retry-http`: Overrides the `retry.linkerd.io/http` annotation
- `l5d-retry-grpc`: Overrides the `retry.linkerd.io/grpc` annotation
- `l5d-retry-limit`: Overrides the `retry.linkerd.io/limit` annotation
- `l5d-retry-timeout`: Overrides the `retry.linkerd.io/timeout` annotation
- `l5d-timeout`: Overrides the `timeout.linkerd.io/request` annotation
- `l5d-response-timeout`: Overrides the `timeout.linkerd.io/response` annotation

## Further reading

- [Retries reference](../reference/retries/)
- [Timeout reference](../reference/timeouts/)
- The [Debugging HTTP applications with per-route metrics](../tasks/books/)
  contains examples of retries and timeout annotations.

[HTTPRoute]: ../reference/httproute/
[GRPCRoute]: ../reference/grpcroute/
