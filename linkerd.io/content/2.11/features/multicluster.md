+++
title = "Multi-cluster communication"
description = "Linkerd can transparently and securely connect services that are running in different clusters."
aliases = [ "multicluster_support" ]
+++

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

{{< fig
    alt="Overview"
    title="Overview"
    center="true"
    src="/images/multicluster/feature-overview.svg" >}}

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

## Headless services

[headless-svc]: https://kubernetes.io/docs/concepts/services-networking/service/#headless-services
[stateful-set]: https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/

By default, Linkerd will mirror all exported services as Kubernetes `clusterIP`
services. This also extends to [headless services][headless-svc]; an exported
headless service will be mirrored as `clusterIP` and have an IP address
assigned to it. In general, headless services _should not have an IP address_,
they are used when a workloads needs a stable network identifier or to
facilitate service discovery without being tied to Kubernetes' native
implementation. This allows clients to either implement their own load
balancing or to address a pod directly through its DNS name. In certain
situations, it is desirable to preserve some of this functionality, especially
when working with Kubernetes objects that require it, such as
[StatefulSet][stateful-set].

Linkerd's multi-cluster extension can be configured with support for headless
services when linking two clusters together. When the feature is turned on, the
*service mirror* component will export headless services without assigning them
an IP. This allows clients to talk to specific pods (or hosts) across clusters.
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

Ready to get started? See the [getting started with multi-cluster
guide](../../tasks/multicluster/) for a walkthrough.

## Further reading

* [Multi-cluster installation instructions](../../tasks/installing-multicluster/).
* [Multi-cluster communication with StatefulSets](../../tasks/multicluster-using-statefulsets/).
* [Architecting for multi-cluster
  Kubernetes](/2020/02/17/architecting-for-multicluster-kubernetes/), a blog
  post explaining some of the design rationale behind Linkerd's multi-cluster
  implementation.
* [Multi-cluster Kubernetes with service
  mirroring](/2020/02/25/multicluster-kubernetes-with-service-mirroring/), a
  deep dive of some of the architectural decisions behind Linkerd's
  multi-cluster implementation.
