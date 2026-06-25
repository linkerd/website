---
title: Handling Rate-Limited Endpoints
description: Automatically route traffic away from rate-limited endpoints
---

When backends implement rate limiting and return
[HTTP 429](https://www.rfc-editor.org/rfc/rfc6585.html#page-3) or
[gRPC RESOURCE_EXHAUSTED](https://grpc.github.io/grpc/core/md_doc_statuscodes.html)
by default, the proxy treats these as successful responses from a load
balancing perspective. Since these types of responses are typically very fast,
Linkerd's [EWMA load balancing](../features/load-balancing.md) may actually
send _more_ traffic to these rate-limited endpoints. This can create a feedback
loop where clients experience high 429 or RESOURCE_EXHAUSTED rates.

Linkerd has two experimental features to help route traffic away from endpoints
which are in a rate-limited state.

{{< production-note >}}

{{< warning >}}

Rate Limit Aware Load Balancing is an experimental, opt-in feature.

{{< /warning >}}

## Load Biaser

Linkerd can be configured to use a more sophisticated version of the EWMA
load balancing algorithm which takes rate-limit responses (HTTP 429 or gRPC
RESOURCE_EXHAUSTED) into account. This algorithm is called the Load Biaser
because it biases traffic away from endpoints which have returned rate-limit
responses recently.

The Load Biaser works exactly the same as [EWMA](../features/load-balancing.md)
except that when it receives a rate-limited response, it substitutes a fixed
penalty value for the response's actual latency (unless the latency is
higher). For example, if the penalty is configured to be `5s` and the Load
Biaser receives a 429 response in `10ms`, it will treat the latency of that
response as `5s` for load balancing purposes.

In this way, the load balancer will not favor endpoints which return
rate-limited responses quickly.

The penalty value can be further refined if the server sets the `Retry-After`
HTTP response header or the `grpc-retry-pushback-ms` gRPC trailer. If one of
these values is present and is higher than the configured penalty, it will be
used in place of the penalty. This allows servers to exert a higher or lower
amount of pushback.

To enable Linkerd to use the Load Biaser for a Service, set the following
annotation on the Service resource:

| Annotation                                    | Type | Default | Notes                                    |
|-----------------------------------------------|------|---------|------------------------------------------|
| `balancer.alpha.linkerd.io/penalize-failures` | bool | `false` | Enables the Load Biaser for this Service |

The Load Biaser can be further configured with these annotations on the Service
resource:

| Annotation                                                    | Type     | Default | Notes                                                                                  |
|---------------------------------------------------------------|----------|---------|----------------------------------------------------------------------------------------|
| `balancer.alpha.linkerd.io/load-biaser-penalty`               | duration | `5s`    | The latency value to inject for rate-limited responses and failures                    |
| `balancer.alpha.linkerd.io/load-biaser-max-retry-after`       | duration | `300s`  | The maximum allowed value of a Retry-After header                                      |

## Unified Circuit Breaker

Linkerd can be configured to use a more sophisticated version of
[consecutive failures failure accrual](../tasks/circuit-breakers.md) called
Unified failure accrual.

The Unified failure accrual can be configured with a success rate threshold.
If the percent of responses within a fixed time window drops below this
threshold, the circuit breaker will trip, temporarily cutting off traffic to
this endpoint and giving it time to recover. Critically, any rate-limited
responses will count as failures for this success rate calculation.

The Unified failure accrual will ALSO trip if it encounters a configured
number of consecutive failures, just like the consecutive failures accrual.

To enable the Unified failure accrual circuit breaker on a Service, set the
following annotation to `"unified"` on the Service resource:

| Annotation                            | Type     | Default | Notes                                                                        |
|---------------------------------------|----------|---------|------------------------------------------------------------------------------|
| `balancer.linkerd.io/failure-accrual` | string   | None    | The failure-accrual mode. Set to `unified` to enable Unified failure accrual |

The Unified failure accrual can be further configured with these annotations on
the Service resource:

| Annotation                                                            | Type                         | Default | Notes                                                            |
|-----------------------------------------------------------------------|------------------------------|---------|------------------------------------------------------------------|
| `balancer.alpha.linkerd.io/failure-accrual-success-rate-threshold`    | number between 0 and 1       | `0.8`   | The success rate threshold at which to trip the breaker          |
| `balancer.alpha.linkerd.io/failure-accrual-success-rate-window`       | duration                     | `10s`   | The window over which the success rate is calculated             |
| `balancer.alpha.linkerd.io/failure-accrual-success-rate-min-requests` | number                       | `5`     | Only trip if there are at least this many requests in the window |
| `balancer.linkerd.io/failure-accrual-consecutive-max-failures`        | number                       | `7`     | Trip if we encounter this many consecutive failures              |
| `balancer.linkerd.io/failure-accrual-consecutive-min-penalty`         | duration                     | `1s`    | The minimum duration for which to cut off traffic                |
| `balancer.linkerd.io/failure-accrual-consecutive-max-penalty`         | duration                     | `1m`    | The maximum duration for which to cut off traffic                |
| `balancer.linkerd.io/failure-accrual-consecutive-jitter-ratio`        | number between 0.0 and 100.0 | `0.5`   | The amount of randomness to inject into the backoff              |

See the
[reference documentation](../reference/circuit-breaking/#configuring-failure-accrual)
for details on failure accrual configuration.
