+++
title = "Circuit Breaking"
description = "Reference guide to Linkerd's Circuit Breaking."
+++

TODO: Move to load-balancing-policy!

Linkerd's Circuit Breaking factors an endpoint’s recent success rate when
considering whether to send a request to it.

Linkerd's Circuit Breaking is configured using [HTTPLoadBalancerPolicy],
[HTTPRoute](https://gateway-api.sigs.k8s.io/references/spec/#gateway.networking.k8s.io/v1beta1.HTTPRoute), `TCP`(_tbd_) and `GRPCRoute`(_tbd_).

## HTTPLoadBalancerPolicy

An `HTTPLoadBalancerPolicy` configures circuit breaking and fail fast timeoutes.

### HTTPLoadBalancerPolicy Spec

An `HTTPLoadBalancerPolicy` spec may contain the following top level fields:

{{< table >}}
| field| value |
|------|-------|
| `failureStatusCodes` | _Default_ status codes considered failures. Overridden by [HTTPRoute] response classification. |
| `maxFailureRate` | If the responses within the `slidingWindowDuration` fail at, or above this ratio, the endpoint is considered to be in a failure condition. |
| `queue` | A `queue` configures the buffering behavior of a load balancer. |
| `slidingWindowDuration` | A duration, in milliseconds, considered for circuit breaking failure accrual.  |
| `targetRef`| A [TargetRef](#targetref) which may reference a ClusterIP Service to which the policy applies.|
{{< /table >}}

#### failureStatusCodes

`FailureStatusCodes` represent the _default_ status codes considered failures and may be overridden in an
[HTTPRoute](https://gateway-api.sigs.k8s.io/references/spec/#gateway.networking.k8s.io/v1beta1.HTTPRoute). Numbers and ranges are considered. Defaults to 500-600.

#### maxFailureRate

`maxFailureRate` represents the maximum rate allowed before considering the endpoint in a failure mode.

#### queue

A `queue` buffers requests.

{{< note >}}
The maximum throughput is `capacity` divided by `failfastTimeout`.
{{< /note >}}

{{< table >}}
| field| value |
|------|-------|
| `capacity` | The number of requests in a queue before the proxy stops accepting connections. |
| `failfastTimeout` | A duration representing how long a request stays in the queue. |
{{< /table >}}

#### slidingWindowDuration

A `SlidingWindowDuration` is the period of time considered for Circuit Breaking. Defaults to 10 seconds.

#### targetRef

A `TargetRef` identifies an API object to which this HTTPLoadBalancerPolicy
applies. The API objects supported are:

- A namespace (`kind: Namespace`), indicating that the HTTPLoadBalancerPolicy
  applies to all traffic to all Service defined in the namespace.
- A ClusterIP Service (`kind: Service`), indicating that the HTTPLoadBalancerPolicy
  applies to all traffic to the Service.

{{< table >}}
| field| value |
|------|-------|
| `group`| Group is the group of the target resource. For namespace and Service kinds, this should be omitted.|
| `kind`| Kind is kind of the target resource.|
| `namespace`| The namespace of the target resource. When unspecified (or empty string), this refers to the local namespace of the policy.|
| `name`| Name is the name of the target resource.|
{{< /table >}}

### HTTPLoadBalancerPolicy Examples

An `HTTPLoadBalancerPolicy`.

```yaml
apiVersion: policy.linkerd.io/v1beta1
kind: HTTPLoadBalancerPolicy
metadata:
  name: http-loadbalancer-policy
  namespace: emojivoto
spec:
  queueCapacity: 4000 # Number of requests allowed in queue
  queueFailfastTimeout: "4s"
  maxFailureRate: 0.05 # Fail if more than 1 in 20 requests in slidingWindowDuration fail 
  slidingWindowDuration: "5s"
  failureStatusCodes:
    - 410
    - 500-599 # Status codes 500 through 599, inclusive.
  targetRef:
    - name: emoji-svc
      kind: Service
```

[HTTPLoadBalancerPolicy]: #httploadbalancerpolicy
[HTTPLoadBalancerPolicies]: #httploadbalancerpolicy
