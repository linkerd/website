---
title: Multi-cluster communication
description: Linkerd can transparently and securely connect services that are running
  in different clusters.
---

Linkerd can connect Kubernetes services across cluster boundaries in a way that
is secure, fully transparent to the application, and independent of network
topology. This multi-cluster capability is designed to provide:

1. **A unified trust domain.** The identity of source and destination workloads
   are validated at every step, both in and across cluster boundaries.
2. **Separate failure domains.** Failure of a cluster allows the remaining
   clusters to function.
3. **Support for any type of network.** Linkerd does not require any specific
   network topology between clusters, and can function both with hierarchical
   networks as well as when clusters [share the same flat
   network](#flat-networks).
4. **A unified model alongside in-cluster communication.** The same
   observability, reliability, and security features that Linkerd provides for
   in-cluster communication extend to cross-cluster communication.

Just as with in-cluster connections, Linkerd’s cross-cluster connections are
transparent to the application code. Regardless of whether that communication
happens within a cluster, across clusters within a datacenter or VPC, or across
the public Internet, Linkerd will establish a connection between clusters
that's reliable, encrypted, and authenticated on both sides with mTLS.

## How it works

Linkerd's multi-cluster support works by "mirroring" service information between
clusters, using a controller that watches a target cluster for updates to
services and applies those updates locally on the source cluster.

These mirrored services are suffixed with the name of the remote cluster, e.g.
the *Foo* service on the *west* cluster would be mirrored as *Foo-west* on the
local cluster. This approach is typically combined with [traffic
splitting](../traffic-split/) or [dynamic request routing](../request-routing/)
to allow local services to access the *Foo* service as if it were on the local
cluster.

Linkerd supports three basic forms of multi-cluster communication: hierarchical,
flat, and federated.

![Architectural diagram comparing hierarchical and flat network modes](/docs/images/multicluster/flat-network.png)

### Hierarchical networks

In hierarchical mode, Linkerd deploys a *gateway* component on the target
cluster that allows it to receive requests from source clusters. This approach
works on almost any network topology, as it only requires that the gateway IP of
the destination cluster be reachable by pods on the source cluster.

### Flat networks

As of Linkerd 2.14, Linkerd supports pod-to-pod communication for clusters that
share a flat network, where pods can establish TCP connections and send traffic
directly to each other across cluster boundaries. In these environments, Linkerd
does not use a gateway intermediary for data plane traffic, which provides
several advantages:

* Improved latency by avoiding an additional network hop
* Reduced operational costs in cloud environments that require a
  `LoadBalancer`-type service for the gateway
* Better multi-cluster authorization policies, as workload identity
  is preserved across cluster boundaries.

### Federated services

A federated service is a union of services with the same name and namespace
in multiple different clusters. Meshed clients that send traffic to a federated
service will have that traffic distributed across all replicas of services in
the federated service across clusters. Federated services use the *flat
networking* model and do not use a gateway intermediary.

These modes can be combined, with each specific service selecting the mode that
is most appropriate for that service. See the
[pod-to-pod multicluster communication](../../tasks/pod-to-pod-multicluster/)
guide, the [federated services](../../tasks/federated-services/) guide, and the
[multi-cluster reference](../../reference/multicluster/) for more.

## Headless services

[headless-svc]: https://kubernetes.io/docs/concepts/services-networking/service/#headless-services
[stateful-set]: https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/

By default, Linkerd will mirror all exported services as Kubernetes `clusterIP`
services. This also extends to [headless services][headless-svc]; an exported
headless service will be mirrored as `clusterIP` and have an IP address
assigned to it. In general, headless services *should not have an IP address*;
they are used when a workload needs a stable network identifier or to
facilitate service discovery without being tied to Kubernetes' native
implementation. This allows clients to either implement their own load
balancing or to address a pod directly through its DNS name. In certain
situations, it is desirable to preserve some of this functionality, especially
when working with Kubernetes objects that require it, such as
[StatefulSet][stateful-set].

Linkerd's multi-cluster extension can be configured with support for headless
services when linking two clusters together. When the feature is turned on, the
controller will export headless services without assigning them an IP.
This allows clients to talk to specific pods (or hosts) across clusters.
To support direct communication, underneath the hood, the service mirror
component will create an *endpoint mirror* for each host that backs a headless
service. To exemplify, if in a target cluster there is a StatefulSet deployed
with two replicas, and the StatefulSet is backed by a headless service, when
the service will be exported, the source cluster will create a headless mirror
along with two "endpoint mirrors" representing the hosts in the StatefulSet.

This approach allows Linkerd to preserve DNS record creation and support direct
communication to pods across clusters. Clients may also implement their own
load balancing based on the DNS records created by the headless service.
Hostnames are also preserved across clusters, meaning that the only difference
in the DNS name (or FQDN) is the headless service's mirror name. In order to be
exported as a headless service, the hosts backing the service need to be named
(e.g a StatefulSet is supported since all pods have a hostname, but a
Deployment would not be supported, since they do not allow for arbitrary
hostnames in the pod spec).

Note that headless services can *not* be part of a federated service.

Ready to get started? See the [getting started with multi-cluster
guide](../../tasks/multicluster/) for a walkthrough.

## Further reading

* [Multi-cluster installation instructions](../../tasks/installing-multicluster/)
* [Pod-to-pod multicluster communication](../../tasks/pod-to-pod-multicluster/)
* [Multi-cluster communication with StatefulSets](../../tasks/multicluster-using-statefulsets/)
* [Federated services](../../tasks/federated-services/)
* [Architecting for multi-cluster
  Kubernetes](/2020/02/17/architecting-for-multicluster-kubernetes/), a blog
  post explaining some of the design rationale behind Linkerd's multi-cluster
  implementation.
* [Multi-cluster Kubernetes with service
  mirroring](/2020/02/25/multicluster-kubernetes-with-service-mirroring/), a
  deep dive of some of the architectural decisions behind Linkerd's
  multi-cluster implementation.
