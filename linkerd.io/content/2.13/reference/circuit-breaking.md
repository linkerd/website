+++
title = "Circuit Breaking"
description = "Reference guide to Linkerd's Circuit Breaking."
+++

Linkerd's Circuit Breaking factors an endpoint’s recent success rate when
considering whether to send a request to it.

Linkerd's Circuit Breaking is configured using [HTTPLoadBalancerPolicy],
[HTTPRoute](../authorization-policy/#httproute), `TCP`(_tbd_) and `GRPCRoute`(_tbd_).

## HTTPLoadBalancerPolicy

An `HTTPLoadBalancerPolicy` configures circuit breaking and fail fast timeoutes.

### HTTPLoadBalancerPolicy Spec

An `HTTPLoadBalancerPolicy` spec may contain the following top level fields:

{{< table >}}
| field| value |
|------|-------|
| `bufferCapacity` | The number of requests in a queue before the proxy stops accepting connections. |
| `bufferFailfastTimeout` | A duration representing how long a request stays in the queue. |
| `failureStatusCodes` | A list of status codes considered failures. Numbers and ranges are considered. |
| `maxFailureRatio` | If the responses within the `slidingWindowDuration` fail at, or above this ratio, the endpoint is considered to be in a failure condition. |
| `slidingWindowDuration` | A duration, in milliseconds, considered for circuit breaking failure accrual.  |
| `targetRef`| A [TargetRef](#targetref) which references a ClusterIP Service to which the policy applies.|
{{< /table >}}

#### failureStatusCodes

`FailureStatusCodes` represent the _default_ status codes considered failures and may be overridden in an
[HTTPRoute].

#### maxFailureRatio

`MaxFailureRatio` represents the maximum ratio allowed before considering the endpoint in a failure mode.

#### slidingWindowDuration

A `SlidingWindowDuration` is the period of time considered for Circuit Breaking. Defaults to 10000.

#### targetRef

A `TargetRef` identifies an API object to which this HTTPLoadBalancerPolicy
applies. The API objects supported are:

- A [Server](../authorization-policy/#server), indicating that the
  HTTPLoadBalancerPolicy applies to all traffic to the Server.
- An [HTTPRoute](../authorization-policy/#httproute), indicating that the
  HTTPLoadBalancerPolicy applies to all traffic matching the HTTPRoute.
- A namespace (`kind: Namespace`), indicating that the HTTPLoadBalancerPolicy
  applies to all traffic to all [Servers](../authorization-policy/#server) and
  [HTTPRoutes](../authorization-policy/#httproute) defined in the namespace.
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
  bufferCapacity: 4000 # Number of requests allowed in buffer
  bufferFailfastTimeout: 4000 # Duration in ms
  maxFailureRatio: 0.05 # Fail if more than 1 in 20 requests in slidingWindowDuration fail 
  slidingWindowDuration: 5000 # Duration in ms
  failureStatusCodes:
    - 410
    - 500-599 # Status codes 500 through 599, inclusive.
  targetRef:
    - name: emoji-svc
      kind: Service
```

[HTTPRoute]: #httproute
[HTTPRoutes]: #httproute
[HTTPLoadBalancerPolicy]: #httploadbalancerpolicy
[HTTPLoadBalancerPolicies]: #httploadbalancerpolicy
