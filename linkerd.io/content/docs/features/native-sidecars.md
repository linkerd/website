---
title: Native sidecars
description:
  Linkerd supports Kubernetes native sidecars, which fix some of the
  long-standing annoyances of using sidecar containers in Kubernetes, especially
  around support for Jobs and race conditions around container startup.
---

Linkerd supports Kubernetes
[native sidecar containers](https://kubernetes.io/docs/concepts/workloads/pods/sidecar-containers/).
Native sidecars fix some of the long-standing historical annoyances of using
sidecar containers in Kubernetes, including:

1. Meshed Jobs (and CronJobs) are not able to terminate without modification,
   because the sidecar proxy continues to run even after the job container
   terminates.

2. There are a variety of startup race conditions with meshed pods when init
   containers also need network access.

As of Linkerd 2.20, native sidecars are enabled by default: the proxy is
injected as an init container with a `restartPolicy` of `Always`, rather than
as a regular container.

## Disabling native sidecars in Linkerd

If for any reason you want to disable this mode and have the proxy be injected
alongside regular containers, set the
`config.linkerd.io/proxy-enable-native-sidecar: false` annotation at the
namespace or workload level, or disable the mode globally by setting the Helm
chart value `proxy.nativeSidecar: false`.
