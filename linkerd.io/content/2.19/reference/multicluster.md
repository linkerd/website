---
title: Multi-cluster communication
description: Multi-cluster communication
---

Linkerd's [multi-cluster functionality](../features/multicluster/) allows
pods to connect to Kubernetes services across cluster boundaries in a way that
is secure and fully transparent to the application. This feature supports three
modes: hierarchical (using a gateway), flat (without a gateway), and federated.

* **Hierarchical mode** only requires that the gateway IP of the destination
  cluster be reachable by pods on the source cluster.
* **Flat mode** requires that all pods on the source cluster be able to directly
  connect to pods on the destination cluster.
* **Federated mode** has the same requirements as flat mode but allows a service
  deployed to multiple clusters to be treated as a single cluster agnostic
  service.

These modes can be mixed and matched.

![Architectural diagram comparing hierarchical and flat network modes](/docs/images/multicluster/flat-network.png)

Hierarchical mode places a bare minimum of requirements on the underlying
network, as it only requires that the gateway IP be reachable. However, flat
mode has a few advantages over the gateway approach used in hierarchical mode,
including reducing latency and preserving client identity.

## Service mirroring

Linkerd's multi-cluster functionality uses a controller component that watches a
target cluster for updates to services and mirrors those service updates locally
to a source cluster.

Multi-cluster support is underpinned by a concept known as service mirroring.
Mirroring refers to importing a service definition from another cluster, and it
allows applications to address and consume multi-cluster services. The
controller runs on the source cluster; it watches a target cluster for updates
to services and mirrors those updates locally in the source cluster. Only
Kubernetes service objects that match a label selector are exported.

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
[*destination service*](../reference/architecture/#the-destination-service).
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

## Federated Services

Federated services take this a step farther by allowing a service which is
deployed to multiple clusters to be joined into a single unified service.

The controller will look for all services in all linked clusters which match a
label selector (`mirror.linkerd.io/federated=member` by default) and create a
federated service called `<svc name>-federated` which will act as a union of all
those services with that name. For example, all traffic sent to the
`store-web-federated` federated service will be load balanced over all replicas
of all services named `store-web` in all linked clusters.

The concept of "namespace sameness" applies, which means that the federated
service will be created in the same namespace as the individual services and
services can only join a federated service in the same namespace.

Since Linkerd's *destination service* uses "remote-discovery" to discover the
endpoints of a federated service, all of the requirements for flat mode also
apply to federated services: the clusters must be on a flat network where pods
in one cluster can connect to pods in the others, the clusters must have the
same trust root, and any clients connecting to the federated service must be
meshed.

### Metadata Copying

The federated service (`<svc name>-federated`) inherits its metadata—including
labels, annotations, and port definitions—from the unioned services. If metadata
varies across these services, as of Linkerd 2.18 the controller uses the service
tied to the oldest Link as the definitive source of truth.

All labels and annotations are copied, except for those related to
topology-aware hints or prefixed with `mirror.linkerd.io`. To prevent specific
metadata from being copied, you can list them in the Link's CR under
`excludeAnnotations` and `excludeLabels` (also only available as of Linkerd
2.18). When using the `linkerd multicluster link-gen` command, apply the
`--exclude-annotations` and `--exclude-labels` flags. For the
local-service-mirror component (the controller that manages adding local
services to federated services) to respect these exclusions, configure them in
the Helm values `localServiceMirror.excludeAnnotations` and
`localServiceMirror.excludeLabels`.
