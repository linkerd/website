---
title: Rate Limiting
description: Reference guide to Linkerd's HTTPLocalRateLimitPolicy resource
---

Linkerd's rate limiting functionality is configured via
`HTTPLocalRateLimitPolicy` resources, which should point to a
[Server](../reference/authorization-policy/#server) reference. Note that a
`Server` can only be referred by a single `HTTPLocalRateLimitPolicy`.

{{< note >}}

`Server`'s default `accessPolicy` config is `deny`. This means that if you don't
have [AuthorizationPolicies](../reference/authorization-policy/) pointing to a
Server, it will deny traffic by default. If you want to set up rate limit
policies for a Server without being forced to also declare authorization
policies, make sure to set `accessPolicy` to a permissive value like
`all-unauthenticated`.

{{< /note >}}

## HTTPLocalRateLimitPolicy Spec

{{< keyval >}}

| field                        | value                                                                                                                                                                                                                              |
| ---------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `targetRef`                  | A reference to the [Server](../reference/authorization-policy/#server) this policy applies to.                                                                                                                                     |
| `total.requestsPerSecond`    | Overall rate limit for all traffic sent to the `targetRef`. If unset no overall limit is applied.                                                                                                                                  |
| `identity.requestsPerSecond` | Fairness for individual identities; each separate client, grouped by identity, will have this rate limit. If `total.requestsPerSecond` is also set, `identity.requestsPerSecond` cannot be greater than `total.requestsPerSecond`. |
| `overrides`                  | An array of [overrides](#overrides) for traffic from specific client.                                                                                                                                                              |

{{< /keyval >}}

### Overrides

{{< keyval >}}

| field                  | value                                                                                                                                                                                                                        |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `requestsPerSecond`    | The number of requests per second allowed from clients matching `clientRefs`. If `total.requestsPerSecond` is also set, the `requestsPerSecond` for each `overrides` entry cannot be greater than `total.requestsPerSecond`. |
| `clientRefs.kind`      | Kind of the referent. Currently only ServiceAccount is supported.                                                                                                                                                            |
| `clientRefs.namespace` | Namespace of the referent. When unspecified (or empty string), this refers to the local namespace of the policy.                                                                                                             |
| `clientRefs.name`      | Name of the referent.                                                                                                                                                                                                        |

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

## Load Biaser

When backends implement rate limiting and return
[HTTP 429](https://www.rfc-editor.org/rfc/rfc6585.html#page-3) or
[gRPC RESOURCE_EXHAUSTED](https://grpc.github.io/grpc/core/md_doc_statuscodes.html)
by default, the proxy treats these as successful responses from a load balancing
perspective. Since these types of responses are typically very fast, Linkerd’s
[EWMA load balancing](https://linkerd.io/docs/features/load-balancing/) may
actually send more traffic to these rate-limited endpoints. This can create a
feedback loop where clients experience high 429 or RESOURCE_EXHAUSTED rates.

Linkerd can be configured to use a more sophisticated version of the EWMA load
balancing algorithm which takes rate-limit responses (HTTP 429 or gRPC
RESOURCE_EXHAUSTED) into account.

To enable Linkerd to use the Load Biaser for a Service, set the following
annotation on the Service resource:

{{< keyval >}}

| annotation                                              | value                                                                                  |
| ------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| `balancer.alpha.linkerd.io/penalize-failures`           | Enables the Load Biaser for this Service. Defaults to `false`.                         |
| `balancer.alpha.linkerd.io/load-biaser-penalty`         | The latency value to inject for rate-limited responses and failures. Defaults to `5s`. |
| `balancer.alpha.linkerd.io/load-biaser-max-retry-after` | The maximum allowed value of a Retry-After header. Defaults to `300s`.                 |

{{< /keyval >}}
