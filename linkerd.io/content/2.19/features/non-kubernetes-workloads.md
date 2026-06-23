---
title: Non-Kubernetes workloads (mesh expansion)
---

Linkerd features _mesh expansion_, or the ability to add non-Kubernetes
workloads to your service mesh by deploying the Linkerd proxy to the remote
machine and connecting it back to the Linkerd control plane within the mesh.
This allows you to use Linkerd to establish communication to and from the
workload that is secure, reliable, and observable, just like communication to
and from your Kubernetes workloads.

Related content:

- [Guide: Adding non-Kubernetes workloads to your mesh](../tasks/adding-non-kubernetes-workloads)
- [ExternalWorkload Reference](../reference/external-workload)
