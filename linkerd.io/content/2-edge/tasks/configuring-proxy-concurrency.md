---
title: Configuring Proxy Concurrency
description: Limit the Linkerd proxy's CPU usage.
---

Linkerd data plane proxies allocate a fixed number of worker threads at startup,
and this thread count directly determines the maximum CPU consumption of the
proxy. In Kubernetes environments, where proxies run as sidecars alongside other
containers in the same pod and coexist with pods on the same node, this static
allocation means that choosing too many threads can lead to CPU
oversubscription. Operators must balance the proxy’s fixed thread count with the
pod’s CPU limits and resource quotas to ensure that both the proxy and the
application containers operate efficiently without degrading overall
performance.

## Default Behavior

Linkerd's default Helm configuration runs sidecar proxies with a single runtime
worker. No requests or limits are configured for the proxy.

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

Kubernetes allows you to set [CPU requests and
limits](https://kubernetes.io/docs/tasks/configure-pod-container/assign-cpu-resource/#specify-a-cpu-request-and-a-cpu-limit)s
for any container, and these settings can also control the CPU usage of the
Linkerd proxy. However, the effect of these settings depends on how the kubelet
enforces CPU limits.

The kubelet enforces pod CPU limits using one of two approaches, determined by
its
[`--cpu-manager-policy`](https://kubernetes.io/docs/tasks/administer-cluster/cpu-management-policies/#configuration)
flag:

### Default CPU Manager Policy

When using the default
[`none`](https://kubernetes.io/docs/tasks/administer-cluster/cpu-management-policies/#none-policy)
policy, the kubelet relies on [Completely Fair Scheduler
(CFS)](https://en.wikipedia.org/wiki/Completely_Fair_Scheduler) quotas. In this
mode, the Linux kernel limits the percentage of CPU time that processes
(including the Linkerd proxy) can use.

### Static CPU Manager Policy

When the kubelet is configured with the static CPU manager policy, it assigns
whole CPU cores to containers by leveraging Linux [cgroup
cpusets](https://www.kernel.org/doc/html/latest/admin-guide/cgroup-v2.html#cpuset).
To successfully use this mechanism, the following conditions must be met:

- The kubelet must run with the [`static` CPU manager
  policy](https://kubernetes.io/docs/tasks/administer-cluster/cpu-management-policies/#static-policy).
- The pod must belong to the [Guaranteed QoS
  class](https://kubernetes.io/docs/tasks/configure-pod-container/quality-service-pod#create-a-pod-that-gets-assigned-a-qos-class-of-guaranteed).
  This requires that every container in the pod has matching CPU (and memory)
  requests and limits.
- The CPU request and CPU limit for the proxy must be specified as whole numbers
  (integers) and must be at least 1.

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

In some environments, it might not be practical to use a fixed CPU limit for a
workload (for example, when the workload does not specify CPU limits and runs on
nodes of varying sizes). In this case, the proxy can be configured with a
maximum ratio of the host's total available CPUs.

A `runtime.workers.maximumCPURatio` value of `1.0` configures the proxy to
allocate a worker for each CPU, while a value of `0.2` configures the proxy to
allocate 1 proxy worker for every 5 available cores (rounded up or down as
appropriate). The `runtime.workers.minimum` value sets a lower bound on the
number of workers per proxy.

## Configuring Rational Proxy CPU Limits Using Helm

Global defaults can be configured in the control-plane helm chart:

```yaml
proxy:
  runtime:
    workers:
      maximumCPURatio: 0.2
      minimum: 1
```

{{< note >}} CPU limits takes precedence over the maximum CPU ratio, so it is
suitable to set a global default maximumCPURatio while setting limits on
specific workloads. {{< /note >}}

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
