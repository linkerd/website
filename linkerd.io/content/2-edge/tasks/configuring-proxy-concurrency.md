---
title: Configuring Proxy Concurrency
description: Limit the Linkerd proxy's CPU usage.
---

Linkerd data plane proxies allocate a fixed number of worker threads at startup,
and this thread count directly determines the maximum CPU consumption of the
proxy. In Kubernetes environments, where proxies run as sidecars alongside other
containers in the same pod—-and coexist with pods on the same node—-this static
allocation means that choosing too many threads can lead to CPU
oversubscription. Operators must balance the proxy’s fixed thread count with the
pod’s CPU limits and resource quotas to ensure that both the proxy and the
application containers operate efficiently without degrading overall
performance.

## Default Behavior

Linkerd's default Helm configuration runs sidecar proxies to use a single
runtime worker. No requests or limits are configured for the proxy.

```yaml
proxy:
  resources:
    cpu:
      request:
      limit:
  runtime:
    workers:
      minimum: 1
```

This document describes how to run proxies with additional runtime workers.

## Configuring Proxy CPU Requests and Limits

Kubernetes provides
[CPU limits and CPU requests](https://kubernetes.io/docs/tasks/configure-pod-container/assign-cpu-resource/#specify-a-cpu-request-and-a-cpu-limit)
to configure the resources assigned to any pod or container. These may also be
used to configure the Linkerd proxy's CPU usage. However, depending on how the
kubelet is configured, using Kubernetes resource limits rather than the
`proxy-cpu-limit` annotation may not be ideal.

The kubelet uses one of two mechanisms for enforcing pod CPU limits. This is
determined by the
[`--cpu-manager-policy` kubelet option](https://kubernetes.io/docs/tasks/administer-cluster/cpu-management-policies/#configuration).
With the default CPU manager policy,
[`none`](https://kubernetes.io/docs/tasks/administer-cluster/cpu-management-policies/#none-policy),
the kubelet uses
[CFS quotas](https://en.wikipedia.org/wiki/Completely_Fair_Scheduler) to enforce
CPU limits. This means that the Linux kernel is configured to limit the amount
of time threads belonging to a given process are scheduled. Alternatively, the
CPU manager policy may be set to
[`static`](https://kubernetes.io/docs/tasks/administer-cluster/cpu-management-policies/#static-policy).
In this case, the kubelet will use Linux `cgroup`s to enforce CPU limits for
containers which meet certain criteria.

On the other hand, using
[cgroup cpusets](https://www.kernel.org/doc/Documentation/cgroup-v1/cpusets.txt)
will limit the number of CPU cores available to the process. In essence, it will
appear to the proxy that the system has fewer CPU cores than it actually does.
If this value is lower than the value of the `proxy-cpu-limit` annotation, the
proxy will use the number of CPU cores determined by the cgroup limit.

However, it's worth noting that in order for this mechanism to be used, certain
criteria must be met:

- The kubelet must be configured with the `static` CPU manager policy
- The pod must be in the
  [Guaranteed QoS class](https://kubernetes.io/docs/tasks/configure-pod-container/quality-service-pod/#create-a-pod-that-gets-assigned-a-qos-class-of-guaranteed).
  This means that all containers in the pod must have both a limit and a request
  for memory and CPU, and the limit for each must have the same value as the
  request.
- The CPU limit and CPU request must be an integer greater than or equal to 1.

### Configuring Default Proxy CPU Requests and Limits Using Helm

A global default CPU request can be configured in the control-plane helm chart
to influence the scheduler:

```yaml
proxy:
  resources:
    cpu:
      request: 100m
```

When only a request is specified, its value is used to configure the proxy's
runtime (by rounding up to the next whole number).

Alternatively, a global default CPU limit can be configured in the
control-plane helm chart:

```yaml
proxy:
  resources:
    cpu:
      limit: 2000m
```

Similarly, this value controls the proxy's runtime configuration (by rounding up
to the next whole number).

When both values are specified, the request is used to influence the scheduler
and the limit is used to configure the proxy's runtime:

```yaml
proxy:
  resources:
    cpu:
      request: 100m
      limit: 2000m
```

### Overriding Proxy CPU Requests and Limits Using Annotations

The `config.linkerd.io/proxy-cpu-request` and
`config.linkerd.io/proxy-cpu-limit` annotations can be used to override the Helm
configuration for a given namespace or workload:

```yaml
kind: Deployment
apiVersion: apps/v1
metadata:
  # ...
spec:
  template:
    metadata:
      annotations:
        config.linkerd.io/proxy-cpu-request: 100m
        config.linkerd.io/proxy-cpu-limit: 2000m
  # ...
```

{{< note >}} When a CPU quantity annotation value is not expressed as a whole
number, the value will be rounded up to the next whole number when configuring
the proxy's runtime. {{< /note >}}

## Configuring _Rational Proxy CPU Limits_

In some environments, it may not be practical to use a fixed CPU limit for a
workload (for example, because the workload does not use CPU limits and runs on
variably sized nodes). In this case, the proxy can be configured with a maximum
ratio of the host's total available CPUs.

For example, a value of `1.0` configures the proxy to use all available CPUs,
while a value of `0.2` configures the proxy to allocate 1 proxy worker for every
5 available cores (rounded).

## Configuring Rational Proxy CPU Limits Using Helm

Global defaults can be configured in the control-plane helm chart:

```yaml proxy:
  runtime:
    workers:
      maximumCPURatio: 0.2
      minimum: 1

```

## Overriding Rational Proxy CPU Limits Using Annotations

To override the default maximum CPU ratio, use the
`config.linkerd.io/proxy-cpu-ratio-limit` annotation:

```yaml
kind: Deployment
apiVersion: apps/v1
metadata:
  # ...
spec:
  template:
    metadata:
      annotations:
        config.linkerd.io/proxy-cpu-ratio-limit: '0.3'
  # ...
```

Note that this may be combined with the `config.linkerd.io/proxy-cpu-request`
annotation (i.e. to influence scheduling). However, the
`config.linkerd.io/proxy-cpu-limit` annotation takes precedence over the ratio
configuration.

```yaml
kind: Deployment
apiVersion: apps/v1
metadata:
  # ...
spec:
  template:
    metadata:
      annotations:
        config.linkerd.io/proxy-cpu-request: '100m'
        config.linkerd.io/proxy-cpu-ratio-limit: '0.3'
  # ...
```
