---
title: Configuring Proxy Concurrency
description: Limit the Linkerd proxy's CPU usage.
---

The Linkerd data plane's proxies are multithreaded, and are capable of running a
variable number of worker threads so that their resource usage matches the
application workload.

In a vacuum, of course, proxies will exhibit the best throughput and lowest
latency when allowed to use as many CPU cores as possible. However, in practice,
there are other considerations to take into account.

A real world deployment is _not_ a load test where clients and servers perform
no other work beyond saturating the proxy with requests. Instead, the service
mesh model has proxy instances deployed as sidecars to application containers.
Each proxy only handles traffic to and from the pod it is injected into. This
means that throughput and latency are limited by the application workload. If an
application container instance can only handle so many requests per second, it
may not actually matter that the proxy could handle more. In fact, giving the
proxy more CPU cores than it requires to keep up with the application may _harm_
overall performance, as the application may have to compete with the proxy for
finite system resources.

Therefore, it is more important for individual proxies to handle their traffic
efficiently than to configure all proxies to handle the maximum possible load.
The primary method of tuning proxy resource usage is limiting the number of
worker threads used by the proxy to forward traffic. There are multiple methods
for doing this.

## Using the `proxy-cpu-limit` Annotation

The simplest way to configure the proxy's thread pool is using the
`config.linkerd.io/proxy-cpu-limit` annotation. This annotation configures the
proxy injector to set an environment variable that controls the number of CPU
cores the proxy will use.

When installing Linkerd using the [`linkerd install` CLI command](install/), the
`--proxy-cpu-limit` argument sets this annotation globally for all proxies
injected by the Linkerd installation. For example,

```bash
# first, install the Linkerd CRDs
linkerd install --crds | kubectl apply -f -

# install Linkerd, with a proxy CPU limit configured.
linkerd install --proxy-cpu-limit 2 | kubectl apply -f -
```

For more fine-grained configuration, the annotation may be added to any
[injectable Kubernetes resource](../features/proxy-injection/), such as a
namespace, pod, or deployment.

For example, the following will configure any proxies in the `my-deployment`
deployment to use two CPU cores:

```yaml
kind: Deployment
apiVersion: apps/v1
metadata:
  name: my-deployment
  # ...
spec:
  template:
    metadata:
      annotations:
        config.linkerd.io/proxy-cpu-limit: "2"
  # ...
```

{{< note >}}

Unlike Kubernetes CPU limits and requests, which can be expressed in milliCPUs,
the `proxy-cpu-limit` annotation should be expressed in whole numbers of CPU
cores. Fractional values will be rounded up to the nearest whole number.

{{< /note >}}

## Using Kubernetes CPU Limits and Requests

Kubernetes provides
[CPU limits and CPU requests](https://kubernetes.io/docs/tasks/configure-pod-container/assign-cpu-resource/#specify-a-cpu-request-and-a-cpu-limit)
to configure the resources assigned to any pod or container. These may also be
used to configure the Linkerd proxy's CPU usage. However, depending on how the
kubelet is configured, using Kubernetes resource limits rather than the
`proxy-cpu-limit` annotation may not be ideal.

{{< warning >}}

When the environment variable configured by the `proxy-cpu-limit` annotation is
unset, the proxy will run only a single worker thread. Therefore, a
`proxy-cpu-limit` annotation should always be added to set an upper bound on the
number of CPU cores used by the proxy, even when Kubernetes CPU limits are also
in use.

{{< /warning >}}

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

## Using Helm

When using [Helm](install-helm/), users must take care to set the `proxy.cores`
Helm variable in addition to `proxy.cpu.limit`, if the criteria for cgroup-based
CPU limits [described above](#using-kubernetes-cpu-limits-and-requests) are not
met.
