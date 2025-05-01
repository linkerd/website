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
3. **Support for heterogeneous networks.** Since clusters can span clouds,
   VPCs, on-premises data centers, and combinations thereof, Linkerd does not
   introduce any L3/L4 requirements other than gateway connectivity.
4. **A unified model alongside in-cluster communication.** The same
   observability, reliability, and security features that Linkerd provides for
   in-cluster communication extend to cross-cluster communication.

Just as with in-cluster connections, Linkerd’s cross-cluster connections are
transparent to the application code. Regardless of whether that communication
happens within a cluster, across clusters within a datacenter or VPC, or across
the public Internet, Linkerd will establish a connection between clusters
that’s encrypted and authenticated on both sides with mTLS.

## How it works

Linkerd's multi-cluster support works by "mirroring" service information
between clusters. Because remote services are represented as Kubernetes
services, the full observability, security and routing features of Linkerd
apply uniformly to both in-cluster and cluster-calls, and the application does
not need to distinguish between those situations.

![Overview](/docs/images/multicluster/feature-overview.svg "Overview")

Linkerd's multi-cluster functionality is implemented by two components:
a *service mirror* and a *gateway*. The *service mirror* component watches
a target cluster for updates to services and mirrors those service updates
locally on a source cluster. This provides visibility into the service names of
the target cluster so that applications can address them directly. The
*multi-cluster gateway* component provides target clusters a way to receive
requests from source clusters. (This allows Linkerd to support [hierarchical
networks](/2020/02/17/architecting-for-multicluster-kubernetes/#requirement-i-support-hierarchical-networks).)

Once these components are installed, Kubernetes `Service` resources that match
a label selector can be exported to other clusters.

Ready to get started? See the [getting started with multi-cluster
guide](../tasks/multicluster/) for a walkthrough.

## Further reading

* [Multi-cluster installation instructions](../tasks/installing-multicluster/).
* [Architecting for multi-cluster
  Kubernetes](/2020/02/17/architecting-for-multicluster-kubernetes/), a blog
  post explaining some of the design rationale behind Linkerd's multi-cluster
  implementation.
* [Multi-cluster Kubernetes with service
  mirroring](/2020/02/25/multicluster-kubernetes-with-service-mirroring/), a
  deep dive of some of the architectural decisions behind Linkerd's
  multi-cluster implementation.
