---
title: Rate Limiting
description: Reference guide to Linkerd's HTTPLocalRateLimitPolicy resource
---

Linkerd's rate limiting functionality is configured via
`HTTPLocalRateLimitPolicy` resources, which should point to a
[Server](../../reference/authorization-policy/#server) reference. Note that a
`Server` can only be referred by a single `HTTPLocalRateLimitPolicy`.

{{< note >}}
`Server`'s default `accessPolicy` config is `deny`. This means that if you don't
have [AuthorizationPolicies](../../reference/authorization-policy/) pointing to a
Server, it will deny traffic by default. If you want to set up rate limit
policies for a Server without being forced to also declare authorization
policies, make sure to set `accessPolicy` to a permissive value like
`all-unauthenticated`.
{{< /note >}}

## HTTPLocalRateLimitPolicy Spec

{{< keyval >}}
| field| value |
|------|-------|
| `targetRef`| A reference to the [Server](../../reference/authorization-policy/#server) this policy applies to. |
| `total.requestsPerSecond`| Overall rate limit, which all traffic coming to the `targetRef` should abide. If unset no overall limit is applied. |
| `total.identity`| Fairness for individual identities; each separate client, grouped by identity, will have this rate limit. The `requestsPerSecond` value should be less than or equal to `total.requestsPerSecond` (if set). |
| `overrides`| An array of [overrides](#overrides) for traffic from specific clients. The `requestsPerSecond` values should be less than or equal to `total.requestsPerSecond` (if set). |
{{< /keyval >}}

### Overrides

{{< keyval >}}
| field| value |
|------|-------|
| `requestsPerSecond`| The number of requests per second allowed from clients matching `clientRefs`. |
| `clientRefs.kind`| Kind of the referent. Currently only ServiceAccount is supported. |
| `clientRefs.namespace`| Namespace of the referent. When unspecified (or empty string), this refers to the local namespace of the policy. |
| `clientRefs.name`| Name of the referent. |
{{< /keyval >}}

## Example

In this example, the policy targets the `web-http` Server, for which a total
rate limit of 100RPS is imposed, with a limit of 20RPS per identity, and an
override of 25RPS for the "special-client" ServiceAccount in the emojivoto
namespace:

```yaml
apiVersion: policy.linkerd.io/v1alpha1
kind: HTTPLocalRateLimitPolicy
metadata:
  namespace: emojivoto
  name: web-rl
spec:
  targetRef:
    group: policy.linkerd.io
    kind: Server
    name: web-http
  total:
    requestsPerSecond: 100
  identity:
    requestsPerSecond: 20
  overrides:
  - requestsPerSecond: 25
    clientRefs:
    - kind: ServiceAccount
      namespace: emojivoto
      name: special-client
```
