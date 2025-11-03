---
title: Service Profiles
description: Details on the specification and what is possible with service profiles.
---

{{< warning >}}
As of Linkerd 2.16, ServiceProfiles have been fully supplanted by [Gateway API
types](../features/gateway-api/), including for getting per-route metrics,
specifying timeouts, and specifying retries. Service profiles continue to be
supported for backwards compatibility, but will not receive further feature
development.
{{< /warning >}}

[Service profiles](../features/service-profiles/) provide Linkerd additional
information about a service. This is a reference for everything that can be done
with service profiles.

## Spec

A service profile spec must contain the following top level fields:

{{< keyval >}}
| field| value |
|------|-------|
| `routes`| a list of [route](#route) objects |
| `retryBudget`| a [retry budget](#retry-budget) object that defines the maximum retry rate to this service |
{{< /keyval >}}

## Route

A route object must contain the following fields:

{{< keyval >}}
| field | value |
|-------|-------|
| `name` | the name of this route as it will appear in the route label |
| `condition` | a [request match](#request-match) object that defines if a request matches this route |
| `responseClasses` | (optional) a list of [response class](#response-class) objects |
| `isRetryable` | indicates that requests to this route are always safe to retry and will cause the proxy to retry failed requests on this route whenever possible |
| `timeout` | the maximum amount of time to wait for a response (including retries) to complete after the request is sent |
{{< /keyval >}}

## Request Match

A request match object must contain _exactly one_ of the following fields:

{{< keyval >}}
| field | value |
|-------|-------|
| `pathRegex` | a regular expression to match the request path against |
| `method` | one of GET, POST, PUT, DELETE, OPTION, HEAD, TRACE |
| `all` | a list of [request match](#request-match) objects which must _all_ match |
| `any` | a list of [request match](#request-match) objects, at least one of which must match |
| `not` | a [request match](#request-match) object which must _not_ match |
{{< /keyval >}}

### Request Match Usage Examples

The simplest condition is a path regular expression:

```yaml
pathRegex: '/authors/\d+'
```

This is a condition that checks the request method:

```yaml
method: POST
```

If more than one condition field is set, all of them must be satisfied. This is
equivalent to using the 'all' condition:

```yaml
all:
- pathRegex: '/authors/\d+'
- method: POST
```

Conditions can be combined using 'all', 'any', and 'not':

```yaml
any:
- all:
  - method: POST
  - pathRegex: '/authors/\d+'
- all:
  - not:
      method: DELETE
  - pathRegex: /info.txt
```

## Response Class

A response class object must contain the following fields:

{{< keyval >}}
| field | value |
|-------|-------|
| `condition` | a [response match](#response-match) object that defines if a response matches this response class |
| `isFailure` | a boolean that defines if these responses should be classified as failed |
{{< /keyval >}}

## Response Match

A response match object must contain _exactly one_ of the following fields:

{{< keyval >}}
| field | value |
|-------|-------|
| `status` | a [status range](#status-range) object to match the response status code against |
| `all` | a list of [response match](#response-match) objects which must _all_ match |
| `any` | a list of [response match](#response-match) objects, at least one of which must match |
| `not` | a [response match](#response-match) object which must _not_ match |
{{< /keyval >}}

Response Match conditions can be combined in a similar way as shown above for
[Request Match Usage Examples](#request-match-usage-examples)

## Status Range

A status range object must contain _at least one_ of the following fields.
Specifying only one of min or max matches just that one status code.

{{< keyval >}}
| field | value |
|-------|-------|
| `min` | the status code must be greater than or equal to this value |
| `max` | the status code must be less than or equal to this value |
{{< /keyval >}}

## Retry Budget

A retry budget specifies the maximum total number of retries that should be sent
to this service as a ratio of the original request volume.

{{< keyval >}}
| field | value |
|-------|-------|
| `retryRatio` | the maximum ratio of retries requests to original requests |
| `minRetriesPerSecond` | allowance of retries per second in addition to those allowed by the retryRatio |
| `ttl` | indicates for how long requests should be considered for the purposes of calculating the retryRatio |
{{< /keyval >}}
