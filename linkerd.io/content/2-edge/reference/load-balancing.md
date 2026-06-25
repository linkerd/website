---
title: Load Balancing
description: How Linkerd implements load balancing.
---

Linkerd uses a sophisticated
[EWMA load balancing algorithm](../features/load-balancing.md) which typically
requires no configuration or tuning. However, it also supports special handling
for backends which support rate limiting. This special handling can be enabled
with Service annotations.

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
