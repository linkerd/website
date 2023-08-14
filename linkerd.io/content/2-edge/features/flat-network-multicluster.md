+++
title = "Multi-cluster communication in flat networks"
description = "Multi-cluster communication using pod-to-pod communication in shared network environments."
aliases = [ "multicluster_support" ]
+++

Linkerd's multi-cluster functionality allows pods to connect to Kubernetes
services across cluster boundaries in a secure, and fully transparent way. In
order to be environment agnostic, the multi-cluster extension uses an
intermediary gateway in each cluster that exports a service to other clusters.

Environments that can be categorized as having a flat network topology may
choose to route traffic directly, instead of going through the intermediary
hop. When clusters use a shared network, pods are able to establish TCP
connections to each other, and consequently send traffic, without requiring any
`LoadBalancer`-type services or ingress gateways. Linkerd's security,
reliability and observability guarantees can be extended to environments that
use a shared network by sending traffic directly to the pods in a multi-cluster
setting.

{{< fig
  alt="An architectural diagram comparing hierarchical network mode with the new flat network mode"
  src="/uploads/2023/07/flat_network@2x.png">}}

Using a direct pod-to-pod communication model has a few advantages over the
gateway model, all while preserving Linkerd's model of separate failure and
security domains:

* Improved latency for cross-cluster calls
* Improved security, workload identity for mTLS is preserved across clusters
  instead of being overridden with the gateway identity
* Reduced operational costs by lowering the amount of traffic that has to be
  routed through an ingress gateway

## How it works

For a general overview on how Linkerd's multi-cluster extension works and what
components are involved, refer to the [multi-cluster
communication](../multicluster#how-it-works) page.

Multi-cluster support is underpinned by a concept known as ["service
mirroring"](../multicluster#how-it-works). Mirroring refers to importing a
service definition from another cluster, and it allows applications to address
and consume multi-cluster services. The *service mirror* component watches a
target cluster for updates to services and mirrors those updates locally in the
source cluster. Only Kubernetes service objects that match a label selector can
be exported, and thus copied over by the *service mirror*.

The label selector also controls the mode a service is exported in. For
example, by default, services labeled with `mirror.linkerd.io/exported=true`
will be exported in gateway mode, whereas services labeled with
`mirror.linkerd.io/exported=remote-discovery` will be exported in pod-to-pod
communication mode. Since the configuration is service-centric, switching from
gateway to pod-to-pod mode is trivial and does not require the extension to be
re-installed.

The term "remote-discovery" refers to how the imported services should be
interpreted by Linkerd's control plane. Service discovery is performed by the
[*destination service*](../../reference/architecture#the-destination-service),
whenever traffic is sent to a target imported in "remote-discovery" mode, it
knows to look for all relevant information in the cluster the service has been
exported from, and not locally. In contrast, service discovery for a gateway
mode import will be performed locally; instead of routing directly to a pod,
traffic will be sent to a gateway address.

Linkerd's *destination service* performs remote discovery by connecting
directly to multiple Kubernetes API Servers. Whenever two clusters are
connected together, a Kubernetes secret object is created in the control
plane's namespace with a kubeconfig file that allows an API client to be
configured. The kubeconfig file uses RBAC to provide the "principle of least
privilege", ensuring the *destination service* may only access only the
resources it needs.

## Cluster configuration and namespace sameness

In pod-to-pod mode, service discovery is performed remotely. This naturally
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
