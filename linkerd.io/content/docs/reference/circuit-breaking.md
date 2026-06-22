---
title: Circuit Breaking
description: How Linkerd implements circuit breaking.
---

[_Circuit breaking_][circuit-breaker] is a pattern for improving the reliability
of distributed applications. In circuit breaking, an application which makes
network calls to remote backends monitors whether those calls succeed or fail,
in an attempt to determine whether that backend is in a failed state. If a given
backend is believed to be in a failed state, its circuit breaker is "tripped",
and no subsequent requests are sent to that backend until it is determined to
have returned to normal.

The Linkerd proxy is capable of performing endpoint-level circuit breaking on
HTTP requests using a configurable failure accrual strategy. This means that the
Linkerd proxy performs circuit breaking at the level of individual endpoints in
a [load balancer](../features/load-balancing/) (i.e., each Pod in a given
Service), and failures are tracked at the level of HTTP response status codes.

Circuit breaking is a client-side behavior, and is therefore performed by the
[outbound] side of the Linkerd proxy.[^1] Outbound proxies implement circuit
breaking in the load balancer, by marking failing endpoints as _unavailable_.
When an endpoint is unavailable, the load balancer will not select it when
determining where to send a given request. This means that if only some
endpoints have tripped their circuit breakers, the proxy will simply not select
those endpoints while they are in a failed state. When all endpoints in a load
balancer are unavailable, requests may be failed with [503 Service Unavailable]
errors, or, if the Service is one of multiple
[`backendRef`s in an HTTPRoute](httproute/#httpbackendref), the entire backend
Service will be considered unavailable and a different backend may be selected.

The [`outbound_http_balancer_endpoints` gauge metric][metric] reports the number
of "ready" and "pending" endpoints in a load balancer, with the "pending" number
including endpoints made unavailable by failure accrual.

## Failure Accrual Policies

A _failure accrual policy_ determines how failures are tracked for endpoints,
and what criteria result in an endpoint becoming unavailable ("tripping the
circuit breaker").

### Consecutive Failures

In this failure accrual policy, an endpoint is marked as failing after a
configurable number of failures occur _consecutively_ (i.e., without any
successes). For example, if the maximum number of failures is 7, the endpoint is
made unavailable once 7 failures occur in a row with no successes. For the
purpose of this failure accrual policy, a _failure_ is an HTTP response with
a [5xx server error] status code or a gRPC response with one of the following
gRPC status codes:

- DATA_LOSS
- DEADLINE_EXCEEDED
- INTERNAL
- PERMISSION_DENIED
- UNAVAILABLE

### Unified

In this failure accrual policy, an endpoint is marked as failing after _either_
of the following conditions is met:

- Success rate drops below a configured threshold. For the purposes of
  calculating success rate, a failure is any HTTP response with a
  [5xx server error] or 429 status code or a gRPC response with one of the
  following gRPC status codes:
  - DATA_LOSS
  - DEADLINE_EXCEEDED
  - INTERNAL
  - PERMISSION_DENIED
  - UNAVAILABLE
  - RESOURCE_EXHAUSTED
- A configured number of failures occur _consecutively_. For the purpose of
  tracking consecutive failures, a _failure_ is an HTTP response with a
  [5xx server error] status code or a gRPC response with one of the following
  gRPC status codes:
  - DATA_LOSS
  - DEADLINE_EXCEEDED
  - INTERNAL
  - PERMISSION_DENIED
  - UNAVAILABLE

For more information on the Unified failure
accrual, see [Rate Limit Aware Load Balancing](../tasks/rate-limit-aware-load-balancing.md).

## Probation and Backoffs

Once a failure accrual policy makes an endpoint unavailble, the circuit breaker
will attempt to determine whether the endpoint is still in a failing state, and
transition it back to available if it has recovered. This process is called
_probation_. When an endpoint enters probation, it is temporarily made available
to the load balancer again, and permitted to handle a single request, called a
_probe request_. If this request succeeds, the endpoint is no longer considered
failing, and is once again made available. If the probe request fails, the
endpoint remains unavailable, and another probe request will be issued after a
backoff.

{{< note >}}

In the context of HTTP failure accrual, a probe request is an actual application
request, and should not be confused with HTTP readiness and liveness probes.
This means that a circuit breaker will not allow an endpoint to exit probation
just because it responds successfully to health checks &mdash; actual
application traffic must succeed for the endpoint to become available again.

{{< /note >}}

When an endpoint's failure accrual policy trips the circuit breaker, it will
remain unavailble for at least a _minimum penalty_ duration. After this duration
has elapsed, the endpoint will enter probation. When a probe request fails, the
endpoint will not be placed in probation again until a backoff duration has
elapsed. Every time a probe request fails, [the backoff increases
exponentially][exp-backoff], up to an upper bound set by the _maximum penalty_
duration.

An amount of random noise, called _jitter_, is added to each backoff duration.
Jitter is controlled by a parameter called the _jitter ratio_, a floating-point
number from 0.0 to 100.0, which represents the maximum percentage of the
original backoff duration which may be added as jitter.

## Configuring Failure Accrual

HTTP failure accrual is configured by a set of annotations. When these
annotations are added to a Kubernetes Service, client proxies will perform HTTP
failure accrual when communicating with endpoints of that Service. If no failure
accrual annotations are present on a Service, proxies will not perform failure
accrual.

{{< warning >}}

Circuit breaking is **incompatible with ServiceProfiles**. If a
[ServiceProfile](../features/service-profiles/) is defined for the annotated
Service, proxies will not perform circuit breaking as long as the ServiceProfile
exists.

{{< /warning >}}

{{< note >}}

Some failure accrual annotations have values which represent a duration.
Durations are specified as a positive integer, followed by a unit, which may be
one of: `ms` for milliseconds, `s` for seconds, `m` for minutes, `h` for hours,
or `d` for days.

{{< /note >}}

Set this annotation on a Service to enable meshed clients to use circuit
breaking when sending traffic to that Service:

- `balancer.linkerd.io/failure-accrual`: Selects the
  [failure accrual policy](#failure-accrual-policies) used when communicating
  with this Service. If this is not present, no failure accrual is performed.
  Supported values for this annotation are `consecutive` and `unified`.

When the failure accrual mode is `"consecutive"`, the following annotations
configure parameters for the consecutive-failures failure accrual policy:

- `balancer.linkerd.io/failure-accrual-consecutive-max-failures`: Sets the
  number of consecutive failures which must occur before an endpoint is made
  unavailable. Must be an integer. If this annotation is not present, the
  default value is 7.
- `balancer.linkerd.io/failure-accrual-consecutive-min-penalty`: Sets the
  minumum penalty duration for which an endpoint will be marked as unavailable
  after `max-failures` consecutive failures occur. After this period of time
  elapses, the endpoint will be [probed](#probation-and-backoffs). This duration
  must be non-zero, and may not be greater than the max-penalty duration. If
  this annotation is not present, the default value is one second (`1s`).
- `balancer.linkerd.io/failure-accrual-consecutive-max-penalty`: Sets the
  maximum penalty duration for which an endpoint will be marked as unavailable
  after `max-failures` consecutive failures occur. This is an upper bound on the
  duration between [probe requests](#probation-and-backoffs). This duration must
  be non-zero, and must be greater than the min-penalty duration. If this
  annotation is not present, the default value is one minute (`1m`).
- `balancer.linkerd.io/failure-accrual-consecutive-jitter-ratio`: Sets the
  jitter ratio used for [probation backoffs](#probation-and-backoffs). This is a
  floating-point number, and must be between 0.0 and 100.0. If this annotation
  is not present, the default value is 0.5.

When the failure accrual mode is `"unified"`, the following annotations
configure parameters for the unified failure accrual policy:

- `balancer.alpha.linkerd.io/failure-accrual-success-rate-threshold`: If the
  success rate of responses in the window drops below this threshold, then the
  endpoint will be made unavailable.  Must be between `0.0` and `1.0`.
  Rate-limited responses such as HTTP 429 and gRPC RESOURCE_EXHAUSTED count as
  failures for this calculation. If this annotation is not present, the default
  value is `0.8` (80% success rate).
- `balancer.alpha.linkerd.io/failure-accrual-success-rate-window`: The window of
  time over which success rate is calculated.  If this annotation is not present,
  the default value is `10s`.
- `balancer.alpha.linkerd.io/failure-accrual-success-rate-min-requests`: The
  minimum number of responses which must be in the window before this breaker
  can trip. This acts as a "cold start" protection to ensure we have a
  sufficient number of responses for the success rate calculation to be
  meaningful before tripping. If this annotation is not present, the default
  value is `5`.
- `balancer.linkerd.io/failure-accrual-consecutive-max-failures`: See above.
- `balancer.linkerd.io/failure-accrual-consecutive-min-penalty`: See above.
- `balancer.linkerd.io/failure-accrual-consecutive-max-penalty`: See above.
- `balancer.linkerd.io/failure-accrual-consecutive-jitter-ratio`: See above.

[^1]:
    The part of the proxy which handles connections from within the pod to the
    rest of the cluster.

[circuit-breaker]: https://www.martinfowler.com/bliki/CircuitBreaker.html
[503 Service Unavailable]:
  https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/503
[metric]: proxy-metrics/#outbound-xroute-metrics
[5xx server error]:
  https://developer.mozilla.org/en-US/docs/Web/HTTP/Status#server_error_responses
[exp-backoff]:
  https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
[outbound]: architecture/#meshed-conncections
