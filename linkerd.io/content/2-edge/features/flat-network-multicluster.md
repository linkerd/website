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

## How does it work

- Kubeconfig generated as part of link
- Secret, RBAC
- Controller watches for changes, reads from API server
- Service can be exported in either mode

## Namespace sameness

- Explanation
- Link
