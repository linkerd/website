---
title: Rate Limiting
description: Linkerd offers a simple and performant HTTP local rate limiting solution to protect services from misbehaved clients
---

Rate limiting helps protect a service by controlling its inbound traffic flow to
prevent overload, ensure fair resource use, enhance security, manage costs,
maintain quality, and comply with SLAs.

Please check the [Configuring Rate Limiting
task](../../tasks/configuring-rate-limiting/) for an example guide on deploying
rate limiting, and the [HTTPLocalRateLimitPolicy reference
doc](../../reference/rate-limiting/).

## Scope

Linkerd offers a _local_ rate limiting solution, which means that each inbound
proxy performs the limiting for the pod. This is unlike _global_ rate limiting,
which takes into account all replicas for each service to track global request
volume. Global rate limiting requires an additional service to track everything
and is thus more complex to deploy and maintain.

## Fairness

In the `HTTPLocalRateLimitPolicy` CR you can optionally configure a rate limit
to apply to all the inbound traffic for a given Server, regardless of the
source.

Additionally, you can specify fairness among clients by declaring a limit per
identity. This avoids specific clients gobbling all the rate limit quota and
affecting all the other clients. Note that all unmeshed sources (which don't
have an identity) are treated as a single source.

Finally, you also have at your disposal the ability to override the config for
specific clients by their identity.

## Algorithm

Linkerd uses the [Generic cell rate algorithm
(GCRA)](https://en.wikipedia.org/wiki/Generic_cell_rate_algorithm) to implement
rate limiting, which is more performant than the token bucket and leaky bucket
algorithms usually used for rate limiting.

The GCRA has two parameters: cell rate and tolerance.

In its virtual scheduling description, the algorithm determines a theoretical
arrival time, representing the 'ideal' arrival time of a cell (request) if cells
(requests) were transmitted at equal intervals of time, corresponding to the
cell rate. How closely the flow of requests should abide to that arrival time is
determined by the tolerance parameter.

In Linkerd we derive the cell rate from the `requestsPerSecond` entries in
`HTTPLocalRateLimitPolicy` and the tolerance is set to one second. This helps
accommodating small variations or occasional bursts in traffic while ensuring
the long-term rate remains within limits.
