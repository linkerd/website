+++
title = "Multi-cluster communication"
description = "Multi-cluster communication"
+++

Linkerd's [multi-cluster functionality](../features/multicluster/) allows pods
to connect to Kubernetes services across cluster boundaries in a way that is
secure and fully transparent to the application. As of Linkerd 2.14, this
feature supports two modes: hierarchical (using an gateway) and flat (without a
gateway):

* **Flat mode** requires that all pods on the source cluster be able to directly
  connect to pods on the destination cluster.
* **Hierarchical mode** only requires that the gateway IP of the destination
  cluster be reachable by pods on the source cluster.

These modes can be mixed and matched.

{{< fig
  alt="An architectural diagram comparing hierarchical network mode with the new flat network mode"
  src="/uploads/2023/07/flat_network@2x.png">}}

Hierarchical mode places a bare minimum of requirements on the underlying
network, as it only requires that the gateway IP be reachable. However, flat
mode has a few advantages over the gateway approach used in hierarchical mode,
including reducing latency and preserving client identity.

## Service mirroring

Linkerd's multi-cluster functionality uses a *service mirror* component that
watches a target cluster for updates to services and mirrors those service
updates locally to a source cluster.

Multi-cluster support is underpinned by a concept known as service mirroring.
Mirroring refers to importing a service definition from another cluster, and it
allows applications to address and consume multi-cluster services. The *service
mirror* component runs on the source cluster; it watches a target cluster for
updates to services and mirrors those updates locally in the source cluster.
Only Kubernetes service objects that match a label selector are exported.

The label selector also controls the mode a service is exported in. For
example, by default, services labeled with `mirror.linkerd.io/exported=true`
will be exported in gateway mode, whereas services labeled with
`mirror.linkerd.io/exported=remote-discovery` will be exported in pod-to-pod
communication mode. Since the configuration is service-centric, switching from
gateway to pod-to-pod mode is trivial and does not require the extension to be
re-installed.

The term "remote-discovery" refers to how the imported services should be
interpreted by Linkerd's control plane. Service discovery is performed by the
[*destination service*](../../reference/architecture#the-destination-service).
Whenever traffic is sent to a target imported in "remote-discovery" mode, the
destination service knows to look for all relevant information in the cluster
the service has been exported from, not locally. In contrast, service discovery
for a hierarchical (gateway mode) import will be performed locally; instead of
routing directly to a pod, traffic will be sent to the gateway address on the
target cluster.

Linkerd's *destination service* performs remote discovery by connecting directly
to multiple Kubernetes API servers. Whenever two clusters are connected
together, a Kubernetes `Secret` is created in the control plane's namespace with
a kubeconfig file that allows an API client to be configured. The kubeconfig
file uses RBAC to provide the "principle of least privilege", ensuring the
*destination service* may only access only the resources it needs.

## Cluster configuration and namespace sameness

In flat mode, service discovery is performed remotely. This naturally
puts restrictions on configuration. For the purpose of multi-cluster
communication, Linkerd has adopted the "namespace sameness" principle described
in [a SIG Multicluster Position
Statement](https://github.com/kubernetes/community/blob/master/sig-multicluster/namespace-sameness-position-statement.md).

In this multi-cluster model, all namespaces with a given name are considered to
be the same across clusters. In other words, namespaces are a wholistic
concept. By extension, all services defined in a namespace are considered the
same service across all different clusters.

Linkerd assumes namespace sameness is enforced *for the control plane*. In
practice, this means that the control plane should be installed in the same
namespace across all connected clusters, and it should be configured with the
same values. An exception applies for cluster-wide configuration such as the
cluster and identity domains.
