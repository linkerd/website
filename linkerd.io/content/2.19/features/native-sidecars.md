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

## Enabling native sidecars in Linkerd

Native sidecars can be enabled by setting
`config.beta.linkerd.io/proxy-enable-native-sidecar` annotation at the level of
individual namespaces or workloads, or by setting it globally at install time.
