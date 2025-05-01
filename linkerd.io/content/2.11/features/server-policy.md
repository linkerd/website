---
title: Authorization Policy
description: Linkerd can restrict which types of traffic are allowed to .
---

Linkerd's server authorization policy allows you to control which types of
traffic are allowed to meshed pods. For example, you can restrict communication
to a particular service to only come from certain other services; or you can
enforce that mTLS must be used on a certain port; and so on.

## Adding traffic policy on your services

{{< note >}}
Linkerd can only enforce policy on meshed pods, i.e. pods where the Linkerd
proxy has been injected. If policy is a strict requirement, you should pair the
usage of these features with [HA mode](ha/), which enforces that the proxy
*must* be present when pods start up.
{{< /note >}}

By default Linkerd allows all traffic to transit the mesh, and uses a variety
of mechanisms, including [retries](retries-and-timeouts/) and [load
balancing](load-balancing/), to ensure that requests are delivered
successfully.

Sometimes, however, we want to restrict which types of traffic are allowed.
Linkerd's policy features allow you to *deny* traffic under certain conditions.
It is configured with two basic mechanisms:

1. A set of basic _default policies_, which can be set at the cluster,
   namespace, workload, and pod level through Kubernetes annotations.
2. `Server` and `ServerAuthorization` CRDs that specify fine-grained policy
   for specific ports.

These mechanisms work in conjunction. For example, a default cluster-wide
policy of `deny` would prohibit any traffic to any meshed pod; traffic must
then be explicitly allowed through the use of `Server` and
`ServerAuthorization` CRDs.

### Policy annotations

The `config.linkerd.io/default-inbound-policy` annotation can be set at a
namespace, workload, and pod level, and will determine the default traffic
policy at that point in the hierarchy. Valid default policies include:

- `all-unauthenticated`: inbound proxies allow all connections
- `all-authenticated`: inbound proxies allow only mTLS connections from other
  meshed pods.
- `cluster-unauthenticated`: inbound proxies allow all connections from client
  IPs in the cluster's `clusterNetworks` (must be configured at install-time).
- `cluster-authenticated`: inbound proxies allow only mTLS connections from other
  meshed pods from IPs in the cluster's `clusterNetworks`.
- `deny` inbound proxies deny all connections that are not explicitly
  authorized.

See the [Policy reference](../reference/authorization-policy/) for more default
policies.

Every cluster has a default policy (by default, `all-unauthenticated`), set at
install / upgrade time. Annotations that are present at the workload or
namespace level *at pod creation time* can override that value to determine the
default policy for that pod. Note that the default policy is fixed at proxy
initialization time, and thus, after a pod is created, changing the annotation
will not change the default policy for that pod.

### Policy CRDs

The `Server` and `ServerAuthorization` CRDs further configure Linkerd's policy
beyond the default policies. In contrast to annotations, these CRDs can be
changed dynamically and policy behavior will be updated on the fly.

A `Server` selects a port and a set of pods that is subject to policy. This set
of pods can correspond to a single workload, or to multiple workloads (e.g.
port 4191 for every pod in a namespace). Once created, a `Server` resource
denies all traffic to that port, and traffic to that port can only be enabled
by creating `ServerAuthorization` resources.

A `ServerAuthorization` defines a set of allowed traffic to a `Server`. A
`ServerAuthorization` can allow traffic based on any number of things,
including IP address; use of mTLS; specific mTLS identities (including
wildcards, to allow for namespace selection); specific Service Accounts; and
more.

See the [Policy reference](../reference/authorization-policy/) for more on
the `Server` and `ServerAuthorization` resources.

{{< note >}}
Currently, `Servers` can only reference ports that are defined as container
ports in the pod's manifest.
{{< /note >}}

### Policy rejections

Any traffic that is known to be HTTP (including HTTP/2 and gRPC) that is denied
by policy will result in the proxy returning an HTTP 403. Any non-HTTP traffic
will be denied at the TCP level, i.e. by refusing the connection.

Note that dynamically changing the policy may result in abrupt termination of
existing TCP connections.

### Examples

See
[emojivoto-policy.yml](https://github.com/linkerd/website/blob/main/run.linkerd.io/public/emojivoto-policy.yml)
for an example set of policy definitions for the [Emojivoto sample
application](/2/getting-started/).
