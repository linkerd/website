---
title: Multi-cluster communication
description: Multi-cluster communication
---

Linkerd's [multi-cluster functionality](../features/multicluster/) allows pods
to connect to Kubernetes services across cluster boundaries in a way that is
secure and fully transparent to the application. As of Linkerd 2.14, this
feature supports two modes: hierarchical (using an gateway) and flat (without a
gateway):

- **Flat mode** requires that all pods on the source cluster be able to directly
  connect to pods on the destination cluster.
- **Hierarchical mode** only requires that the gateway IP of the destination
  cluster be reachable by pods on the source cluster.

These modes can be mixed and matched.

![Architectural diagram comparing hierarchical and flat network modes](/docs/images/multicluster/flat-network.png)

Hierarchical mode places a bare minimum of requirements on the underlying
network, as it only requires that the gateway IP be reachable. However, flat
mode has a few advantages over the gateway approach used in hierarchical mode,
including reducing latency and preserving client identity.

## Service mirroring

Linkerd's multi-cluster functionality uses a _service mirror_ component that
watches a target cluster for updates to services and mirrors those service
updates locally to a source cluster.

Multi-cluster support is underpinned by a concept known as service mirroring.
Mirroring refers to importing a service definition from another cluster, and it
allows applications to address and consume multi-cluster services. The _service
mirror_ component runs on the source cluster; it watches a target cluster for
updates to services and mirrors those updates locally in the source cluster.
Only Kubernetes service objects that match a label selector are exported.

The label selector also controls the mode a service is exported in. For example,
by default, services labeled with `mirror.linkerd.io/exported=true` will be
exported in hierarchical (gateway) mode, whereas services labeled with
`mirror.linkerd.io/exported=remote-discovery` will be exported in flat
(pod-to-pod) mode. Since the configuration is service-centric, switching from
gateway to pod-to-pod mode is trivial and does not require the extension to be
re-installed.

{{< note >}}

In flat mode, the namespace of the Linkerd control plane should be the same
across all clusters. We recommend leaving this at the default value of
`linkerd`.

{{< /note >}}

The term "remote-discovery" refers to how the imported services should be
interpreted by Linkerd's control plane. Service discovery is performed by the
[_destination service_](../reference/architecture/#the-destination-service).
Whenever traffic is sent to a target imported in "remote-discovery" mode, the
destination service knows to look for all relevant information in the cluster
the service has been exported from, not locally. In contrast, service discovery
for a hierarchical (gateway mode) import will be performed locally; instead of
routing directly to a pod, traffic will be sent to the gateway address on the
target cluster.

Linkerd's _destination service_ performs remote discovery by connecting directly
to multiple Kubernetes API servers. Whenever two clusters are connected
together, a Kubernetes `Secret` is created in the control plane's namespace with
a kubeconfig file that allows an API client to be configured. The kubeconfig
file uses RBAC to provide the "principle of least privilege", ensuring the
_destination service_ may only access only the resources it needs.
