+++
title = "Load Balancing Policy"
description = "Reference guide to Linkerd's Load Balancing Policy."
+++

Linkerd's Load Balancing Policy configures load balancing and Circuit Breaking. Circuit
Breaking factors an endpoint’s recent success rate when considering whether to send a request to it.

Linkerd's Load Balancing Policy is configured using [HTTPLoadBalancerPolicy],
[HTTPRoute](https://gateway-api.sigs.k8s.io/references/spec/#gateway.networking.k8s.io/v1beta1.HTTPRoute), `TCP`(_tbd_) and `GRPCRoute`(_tbd_).

## HTTPLoadBalancerPolicy

An `HTTPLoadBalancerPolicy` configures circuit breaking and queue behavior.

### HTTPLoadBalancerPolicy Spec

An `HTTPLoadBalancerPolicy` spec may contain the following top level fields:

{{< table >}}
| field| value |
|------|-------|
| `circuitBreaking` | Configures Circuit Breaking. |
| `queue` | A `queue` configures the buffering behavior of a load balancer. |
| `targetRef`| A [TargetRef](#targetref) which may reference a ClusterIP Service to which the policy applies.|
{{< /table >}}

#### circuitBreaking

{{< table >}}
| field| value |
|------|-------|
| `kind` | Either `consecutiveFailures`, `successRate`, `successRateWindowed`, or `none`. |
{{< /table >}}

<!-- Taken from https://api.linkerd.io/1.7.5/linkerd/index.html#grpc-user-defined-retryable-status-codes -->

#### kind

`kind` determines the approach for Circuit Breaking.

##### kind: consecutiveFailures

`consecutiveFailures` observes the number of consecutive failures to each node,
and backs off sending requests to nodes that have exceeded the specified number
of failures.

{{< table >}}
| field| value |
|------|-------|
| `failures` | Number of consecutive failures. |
{{< /table >}}

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
| `group`| Group is the group of the target resource. For namespace kinds, this should be omitted.|
| `kind`| The kind of the target resource.|
| `namespace`| The namespace of the target resource. When unspecified (or empty string), this refers to the local namespace of the policy.|
| `name`| The name of the target resource.|
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
  queue:
    capacity: 4000 # Number of requests allowed in queue
    failfastTimeout: "4s"
  circuitBreaking:
    maxFailureRate: 100 # Fail if more than 100 in slidingWindowDuration fail
    slidingWindowDuration: "5s"
  targetRef:
    - name: emoji-svc
      kind: Service
```

[HTTPLoadBalancerPolicy]: #httploadbalancerpolicy
[HTTPLoadBalancerPolicies]: #httploadbalancerpolicy
