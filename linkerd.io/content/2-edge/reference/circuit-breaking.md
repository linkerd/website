+++
title = "Circuit Breaking"
description = ""
aliases = [
  "../failure-accrual/",
]
+++

[_Circuit breaking_][wiki] is a pattern for improving the reliability of
distributed applications. TODO ELIZA MOAR WORDS

The Linkerd proxy is capable of performing request-level circuit breaking on
HTTP requests using a configurable failure accrual strategy.

## Failure Accrual Policies

A _failure accrual policy_ determines how failures are tracked for endpoints,
and what criteria result in an endpoint becoming unavailable ("tripping the
circuit breaker"). Currently, the Linkerd proxy implements one failure accrual
policy, _consecutive failures_. Additional failure accrual policies may be
added in the future.

### Consecutive Failures

In this failure accrual policy, an endpoint is marked as failing after a
configurable number of failures occur _consecutively_ (i.e., without any
successes). For example, if the maximum number of failures is 7, the endpoint is
made unavailable once 7 failures occur in a row with no successes.

## Probation and Backoffs

Once a failure accrual policy makes an endpoint unavailble, the circuit breaker
will attempt to determine whether the endpoint is still in a failing state, and
transition it back to available if it has recovered. This process is called
_probation_. When an endpoint enters probatiion, it is available for a single
request, called a _probe request_. If this request succeeds, the endpoint is no
longer considered failing, and is once again made available. If the probe
request fails, the endpoint remains unavailable, and another probe request will
be issued after a backoff.

When an endpoint's failure accrual policy trips the circuit breaker, it will
remain unavailble for at least a _minimum penalty_ duration. After this duration
has elapsed, the endpoint will enter probation. When a probe request fails, the
endpoint will not be placed in probation again until a backoff duration has
elapsed. Every time a probe request fails, [the backoff increases
exponentially][exp-backoff], up to an upper bound set by the _maximum penalty_
duration.

An amount of random noise, called _jitter_, is added to each backoff
duration. Jitter is controlled by a parameter called the _jitter ratio_, a
floating-point number from 0.0 to 100.0, which represents the maximum percentage
of the original backoff duration which may be added as jitter.

## Configuring Failure Accrual

HTTP failure accrual is configured by a set of annotations. When these
annotations are added to a Kubernetes Service, client proxies will perform
HTTP failure accrual when communicating with replicas of that Service. If no
failure accrual annotations are present on a Service, proxies will not perform
failure accrual.

The following annotations configure failure accrual:

+ `balancer.linkerd.io/failure-accrual`: Selects the [failure accrual
  policy](#failure-accrual-policies) used
  when communicating with this Service. If this is not present, no failure
  accrual is performed. Currently, the only supported value for this annotation
  is `"consecutive"`, to perform [consecutive failures failure
  accrual](#consecutive-failures).

When the failure accrual mode is `"consecutive"`, the following annotations
configure parameters for the consecutive-failures failure accrual policy:

+ `balancer.linkerd.io/failure-accrual-consecutive-max-failures`: Sets the
  number of consecutive failures which must occur before an endpoint is made
  unavailable. Must be an integer. If this annotation is not present, the
  default value is 7.
+ `balancer.linkerd.io/failure-accrual-consecutive-min-penalty`: Sets the
  minumum penalty duration for which an endpoint will be marked as unavailable
  after `max-failures` consecutive failures occur. After this period of time
  elapses, the endpoint will be [probed](#probation-and-backoffs).
+ `balancer.linkerd.io/failure-accrual-consecutive-max-penalty`: Sets the
  maximum penalty duration for which an endpoint will be marked as unavailable
  after `max-failures` consecutive failures occur. This is an upper bound on the
  duration between [probe requests](#probation-and-backoffs).


### Specifying Durations

Durations are

[wiki]: https://en.wikipedia.org/wiki/Circuit_breaker_design_pattern
[exp-backoff]: https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/