+++
title = "Circuit Breakers"
description = "Protect against service failures using circuit breakers"
+++

Circuit breaking is a powerful feature where Linkerd will temporarily stop
routing requests to an endpoint if that endpoint is deemed to be unhealthy,
instead routing that request to other replicas in the Service.

In this tutoral, we'll see how to enable circuit breaking on a Service to
improve client success rate when a backend replica is unhealthy.

See the [reference documentation](../../reference/circuit-breaking/) for more
details on how Linkerd implements circuit breaking.

{{< trylpt >}}

## Prerequisites

To use this guide, you'll need a Kubernetes cluster running:

- Linkerd and Linkerd-Viz. If you haven't installed these yet, follow the
  [Installing Linkerd Guide](../install/).

## Set up the demo

Remember those puzzles where one guard always tells the truth and one guard
always lies? This demo involves one pod (named `good`) which always returns an
HTTP 200 and one pod (named `bad`) which always returns an HTTP 500. We'll also
create a load generator to send traffic to a Service which includes these two
pods.

For load generation we'll use
[Slow-Cooker](https://github.com/BuoyantIO/slow_cooker)
and for the backend pods we'll use [BB](https://github.com/BuoyantIO/bb).

To add these components to your cluster and include them in the Linkerd
[data plane](../../reference/architecture/#data-plane), run:

```bash
cat <<EOF | linkerd inject - | kubectl apply -f -
---
apiVersion: v1
kind: Namespace
metadata:
  name: circuit-breaking-demo
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: good
  namespace: circuit-breaking-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      class: good
  template:
    metadata:
      labels:
        class: good
        app: bb
    spec:
      containers:
      - name: terminus
        image: buoyantio/bb:v0.0.6
        args:
        - terminus
        - "--h1-server-port=8080"
        ports:
        - containerPort: 8080
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bad
  namespace: circuit-breaking-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      class: bad
  template:
    metadata:
      labels:
        class: bad
        app: bb
    spec:
      containers:
      - name: terminus
        image: buoyantio/bb:v0.0.6
        args:
        - terminus
        - "--h1-server-port=8080"
        - "--percent-failure=100"
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: bb
  namespace: circuit-breaking-demo
spec:
  ports:
  - name: http
    port: 8080
    targetPort: 8080
  selector:
    app: bb
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: slow-cooker
  namespace: circuit-breaking-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: slow-cooker
  template:
    metadata:
      labels:
        app: slow-cooker
    spec:
      containers:
      - args:
        - -c
        - |
          sleep 5 # wait for pods to start
          /slow_cooker/slow_cooker --qps 10 http://bb:8080
        command:
        - /bin/sh
        image: buoyantio/slow_cooker:1.3.0
        name: slow-cooker
EOF
```

We can now look at the success rate of the `good` and `bad` pods:

```console
> linkerd viz -n circuit-breaking-demo stat deploy
NAME          MESHED   SUCCESS      RPS   LATENCY_P50   LATENCY_P95   LATENCY_P99   TCP_CONN
bad              1/1     6.43%   4.7rps           1ms           1ms           4ms          2
good             1/1   100.00%   5.9rps           1ms           1ms           1ms          3
slow-cooker      1/1   100.00%   0.3rps           1ms           1ms           1ms          1
```

Here we can see that `good` and `bad` deployments are each receiving similar
amounts of traffic, but `good` has a success rate of 100% while the success
rate of `bad` is very low (only healthcheck probes are succeeding). We can also
see how this looks from the perspective of the traffic generator:

```console
> linkerd viz -n circuit-breaking-demo stat deploy/slow-cooker --to svc/bb
NAME          MESHED   SUCCESS       RPS   LATENCY_P50   LATENCY_P95   LATENCY_P99   TCP_CONN
slow-cooker      1/1    51.00%   10.0rps           1ms           1ms           2ms          2
```

From `slow-cooker`'s perspective, roughly 50% of requests that it sends to the
Service are failing. We can use circuit breaking to improve this by cutting off
traffic to the `bad` pod.

## Breaking the circuit

Linkerd supports a type of circuit breaking called [_consecutive failure
accrual_](../../reference/circuit-breaking/#consecutive-failures).
This works by tracking consecutive failures from each endpoint in Linkerd's
internal load balancer. If there are ever too many failures in a row, that
endpoint is temporarily ignored and Linkerd will only load balance among the
remaining endpoints. After a [backoff
period](../../reference/circuit-breaking/#probation-and-backoffs), the endpoint
is re-introduced so that we can determine if it has become healthy.

Let's enable consecutive failure accrual on the `bb` Service by adding an
annotation:

```bash
kubectl annotate -n circuit-breaking-demo svc/bb balancer.linkerd.io/failure-accrual=consecutive
```

{{< warning >}}
Circuit breaking is **incompatible with ServiceProfiles**. If a
[ServiceProfile](../../features/service-profiles/) is defined for the annotated
Service, proxies will not perform circuit breaking as long as the ServiceProfile
exists.
{{< /warning >}}

We can check that failure accrual was configured correctly by using a Linkerd
diagnostics command.  The `linkerd diagnostics policy` command prints the policy
that Linkerd will use when sending traffic to a Service. We'll use the
[jq](https://stedolan.github.io/jq/) utility to filter the output to focus on
failure accrual:

```console
> linkerd diagnostics policy -n circuit-breaking-demo svc/bb 8080 -o json | jq '.protocol.Kind.Detect.http1.failure_accrual'
{
  "Kind": {
    "ConsecutiveFailures": {
      "max_failures": 7,
      "backoff": {
        "min_backoff": {
          "seconds": 1
        },
        "max_backoff": {
          "seconds": 60
        },
        "jitter_ratio": 0.5
      }
    }
  }
}
```

This tells us that Linkerd will use `ConsecutiveFailures` failure accrual
when talking to the `bb` Service. It also tells us that the `max_failures` is
7, meaning that it will trip the circuit breaker once it observes 7 consective
failures. We'll talk more about each of the parameters here at the end of this
article.

Let's look at how much traffic each pod is getting now that the circuit breaker
is in place:

```console
> linkerd viz -n circuit-breaking-demo stat deploy
NAME          MESHED   SUCCESS       RPS   LATENCY_P50   LATENCY_P95   LATENCY_P99   TCP_CONN
bad              1/1    94.74%    0.3rps           1ms           1ms           1ms          3
good             1/1   100.00%   10.3rps           1ms           1ms           4ms          4
slow-cooker      1/1   100.00%    0.3rps           1ms           1ms           1ms          1
```

Notice that the `bad` pod's RPS is significantly lower now. The circuit breaker
has stopped nearly all of the traffic from `slow-cooker` to `bad`.

We can also see how this has affected `slow-cooker`:

```console
> linkerd viz -n circuit-breaking-demo stat deploy/slow-cooker --to svc/bb
NAME          MESHED   SUCCESS       RPS   LATENCY_P50   LATENCY_P95   LATENCY_P99   TCP_CONN
slow-cooker      1/1    99.83%   10.0rps           1ms           1ms           1ms          4
```

Nearly all of `slow-cooker`'s requests are now getting routed to the `good` pod
and succeeding!

## Tuning circuit breaking

As we saw when we ran the `linkerd diagnostics policy` command, consecutive
failure accrual is controlled by a number of parameters. Each of these
parameters has a default, but can be manually configured using annotations:

- `balancer.linkerd.io/failure-accrual-consecutive-max-failures`
  - The number of consecutive failures that Linkerd must observe before
    tripping the circuit breaker (default: 7). Consider setting a lower value
    if you want circuit breaks to trip more easily which can lead to better
    success rate at the expense of less evenly distributed traffic. Consider
    setting a higher value if you find circuit breakers are tripping too easily,
    causing traffic to be cut off from healthy endpoints.
- `balancer.linkerd.io/failure-accrual-consecutive-max-penalty`
  - The maximum amount of time a circuit breaker will remain tripped
    before the endpoint is restored (default: 60s). Consider setting a longer
    duration if you want to reduce the amount of traffic to endpoints which have
    tripped the circuit breaker. Consider setting a shorter duration if you'd
    like tripped circuit breakers to recover faster after an endpoint becomes
    healthy again.
- `balancer.linkerd.io/failure-accrual-consecutive-min-penalty`
  - The minimum amount of time a circuit breaker will remain tripped
    before the endpoints is restored (default: 1s). Consider tuning this in a
    similar way to `failure-accrual-consecutive-max-penalty`.
- `balancer.linkerd.io/failure-accrual-consecutive-jitter-ratio`
  - The amount of jitter to introduce to circuit breaker backoffs (default: 0.5).
    You are unlikely to need to tune this but might consider increasing it if
    you notice many clients are sending requests to a circuit broken endpoint
    at the same time, leading to spiky traffic patterns.

See the [reference
documentation](../../reference/circuit-breaking/#configuring-failure-accrual)
for details on failure accrual configuration.
