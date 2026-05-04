---
title: Authorization Policy
description:
  Linkerd can restrict which types of traffic are allowed between meshed
  services.
---

Linkerd's authorization policy allows you to control which types of traffic are
allowed to meshed pods. For example, you can restrict communication to a
particular service (or HTTP route on a service) to only come from certain other
services; you can enforce that mTLS must be used on a certain port; and so on.

{{< note >}}

Linkerd can only enforce policy on meshed pods, i.e. pods where the Linkerd
proxy has been injected. If policy is a strict requirement, you should pair the
usage of these features with [HA mode](ha/), which enforces that the proxy
_must_ be present when pods start up.

{{< /note >}}

## Policy overview

By default Linkerd allows all traffic to transit the mesh, and uses a variety of
mechanisms, including [retries](retries-and-timeouts/) and
[load balancing](load-balancing/), to ensure that requests are delivered
successfully.

Sometimes, however, we want to restrict which types of traffic are allowed.
Linkerd's policy features allow you to _deny_ access to resources unless certain
conditions are met, including the TLS identity of the client.

Linkerd's policy is configured using two mechanisms:

1. A set of _default policies_, which can be set at the cluster, namespace,
   workload, and pod level through Kubernetes annotations.
2. A set of CRDs that specify fine-grained policy for specific ports, routes,
   workloads, etc.

These mechanisms work in conjunction. For example, a default cluster-wide policy
of `deny` would prohibit any traffic to any meshed pod; traffic would then need
to be explicitly allowed through the use of CRDs.

## Default policies

The `config.linkerd.io/default-inbound-policy` annotation can be set at a
namespace, workload, and pod level, and will determine the default traffic
policy at that point in the hierarchy. Valid default policies include:

- `all-unauthenticated`: allow all requests. This is the default.
- `all-authenticated`: allow requests from meshed clients only.
- `cluster-authenticated`: allow requests from meshed clients in the same
  cluster.
- `deny`: deny all requests.
- `audit`: Same as `all-unauthenticated` but requests get flagged in logs and
  metrics.

As well as several other default policies—see the
[Policy reference](../reference/authorization-policy/) for more.

Every cluster has a cluster-wide default policy (by default,
`all-unauthenticated`), set at install time. Annotations that are present at the
workload or namespace level _at pod creation time_ can override that value to
determine the default policy for that pod. (Note that the default policy is
fixed at proxy initialization time, and thus, after a pod is created, changing
the annotation will not change the default policy for that pod.)

## Fine-grained policies

For finer-grained policy that applies to specific ports, routes, or more,
Linkerd uses a set of CRDs. In contrast to default policy annotations, these
policy CRDs can be changed dynamically and policy behavior will be updated on
the fly.

Three policy CRDs represent "targets" for policy: subsets of traffic over which
policy can be applied.

- [`Server`]: all traffic to a port, for a set of pods in a namespace
- [`HTTPRoute`]: a subset of HTTP requests for a `Server`
- [`GRPCRoute`]: a subset of gRPC requests for a `Server`

Two policy CRDs represent authentication rules that must be satisfied as part of
a policy rule:

- `MeshTLSAuthentication`: authentication based on
  [secure workload identities](automatic-mtls/)
- `NetworkAuthentication`: authentication based on IP address

And finally, two policy CRDs represent policy itself: the mapping of
authentication rules to targets.

- `AuthorizationPolicy`: a policy that restricts access to one or more targets
  unless an authentication rule is met

- `ServerAuthorization`: an earlier form of policy that restricts access to
  `Server`s only (i.e. not `HTTPRoute`s or `GRPCRoute`s)

The general pattern for Linkerd's dynamic, fine-grained policy is to define the
traffic target that must be protected (via a combination of `Server` and
`HTTPRoute` CRs); define the types of authentication that are required before
access to that traffic is permitted (via `MeshTLSAuthentication` and
`NetworkAuthentication`); and then define the policy that maps authentication to
target (via an `AuthorizationPolicy`).

See the [Policy reference](../reference/authorization-policy/) for more details
on how these resources work.

## ServerAuthorization vs AuthorizationPolicy

Linkerd 2.12 introduced `AuthorizationPolicy` as a more flexible alternative to
`ServerAuthorization` that can target `HTTPRoute`s as well as `Server`s. Use of
`AuthorizationPolicy` is preferred, and `ServerAuthorization` will be deprecated
in future releases.

## Default authorizations

A blanket denial of all to a pod would also deny health and readiness probes
from Kubernetes, meaning that the pod would not be able to start. Thus, any
default-deny setup must, in practice, still authorize these probes.

In order to simplify default-deny setups, Linkerd automatically authorizes
probes to pods. These default authorizations apply only when no `Server` is
configured for a port, or when a `Server` is configured but no `HTTPRoute`s or
`GRPCRoute` are configured for that `Server`. If any `HTTPRoute` or `GRPCRoute`
matches the `Server`, these automatic authorizations are not created and you
must explicitly create them for health and readiness probes.

## Policy rejections

Any traffic that is known to be HTTP (including HTTP/2 and gRPC) that is denied
by policy will result in the proxy returning an HTTP 403. All other traffic will
be denied at the TCP level, i.e. by refusing the connection.

Note that dynamically changing the policy to deny existing connections may
result in an abrupt termination of those connections.

## Audit mode

A `Server`'s default policy is defined in its `accessPolicy` field, which
defaults to `deny`. That means that, by default, traffic that doesn't conform to
the rules associated to that Server is denied (the same applies to `Servers`
that don't have associated rules yet). This can inadvertently prevent traffic if
you apply rules that don't account for all the possible sources/routes for your
services.

This is why we recommend that when first setting authorization policies, you
explicitly set `accessPolicy:audit` for complex-enough services. In this mode,
if a request doesn't abide to the policy rules, it won't get blocked, but it
will generate a log entry in the proxy at the INFO level with the tag
`authz.name=audit` along with other useful information. Likewise, the proxy will
add entries to metrics like `request_total` with the label `authz_name=audit`.
So when you're in the process of fine-tuning a new authorization policy, you can
filter by those tags/labels in your observability stack to keep an eye on
requests which weren't caught by the policy.

### Audit mode for default policies

Audit mode is also supported at cluster, namespace, or workload level. To set
the whole cluster to audit mode, set `proxy.defaultInboundPolicy=audit` when
installing Linkerd; for a namespace or a workload, use the annotation
`config.linkerd.io/default-inbound-policy:audit`. For example, if you had
`config.linkerd.io/default-inbound-policy:all_authenticated` for a namespace and
no `Servers` declared, all unmeshed traffic would be denied. By using
`config.linkerd.io/default-inbound-policy:audit` instead, unmeshed traffic would
be allowed but it would be logged and surfaced in metrics as detailed above.

## Learning more

- [Authorization policy reference](../reference/authorization-policy/)
- [Guide to configuring per-route policy](../tasks/configuring-per-route-policy/)

[`HTTPRoute`]: ../reference/httproute/
[`GRPCRoute`]: ../reference/grpcroute/
[`Server`]: ../reference/authorization-policy/#server
