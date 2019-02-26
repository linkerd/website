+++
date = "2018-07-31T12:00:00-07:00"
title = "Service Profiles"
description = "Details on the specification and what is possible with service profiles."
+++

[Service profiles](/2/features/service-profiles/) provide Linkerd additional
information about a service. This is a reference for everything that can be done
with service profiles.

## Spec

A service profile spec must contain the following top level fields:

{{< table >}}
| field| value |
|------|-------|
| `routes`| a list of [route](#route) objects |
| `retryBudget`| a [retry budget](#retry-budget) object that defines the maximum retry rate to this service |
{{< /table >}}

## Route

A route object must contain the following fields:

{{< table >}}
| field | value |
|-------|-------|
| `name` | the name of this route as it will appear in the route label |
| `condition` | a [request match](#request-match) object that defines if a request matches this route |
| `responses` | (optional) a list of [response class](#response-class) objects |
| `isRetryable` | indicates that requests to this route are always safe to retry and will cause the proxy to retry failed requests on this route whenever possible |
| `timeout` | the maximum amount of time to wait for a response (including retries) to complete after the request is sent |
{{< /table >}}

## Request Match

A request match object must contain _exactly one_ of the following fields:

{{< table >}}
| field | value |
|-------|-------|
| `pathRegex` | a regular expression to match the request path against |
| `method` | one of GET, POST, PUT, DELETE, OPTION, HEAD, TRACE |
| `all` | a list of [request match](#request-match) objects which must _all_ match |
| `any` | a list of [request match](#request-match) objects, at least one of which must match |
| `not` | a [request match](#request-match) object which must _not_ match |
{{< /table >}}

## Response Class

A response class object must contain the following fields:

{{< table >}}
| field | value |
|-------|-------|
| `condition` | a [response match](#response-match) object that defines if a response matches this response class |
| `isSuccess` | a boolean that defines if these responses should be classified as successful |
{{< /table >}}

## Response Match

A response match object must contain _exactly one_ of the following fields:

{{< table >}}
| field | value |
|-------|-------|
| `status` | a [status range](#status-range) object to match the response status code against |
| `all` | a list of [response match](#response-match) objects which must _all_ match |
| `any` | a list of [response match](#response-match) objects, at least one of which must match |
| `not` | a [response match](#response-match) object which must _not_ match |
{{< /table >}}

## Status Range

A status range object must contain _at least one_ of the following fields.
Specifying only one of min or max matches just that one status code.

{{< table >}}
| field | value |
|-------|-------|
| `min` | the status code must be greater than or equal to this value |
| `max` | the status code must be less than or equal to this value |
{{< /table >}}

## Retry Budget

A retry budget specifies the maximum total number of retries that should be sent
to this service as a ratio of the original request volume.

{{< table >}}
| field | value |
|-------|-------|
| `retryRatio` | the maximum ratio of retries requests to original requests |
| `minRetriesPerSecond` | allowance of retries per second in addition to those allowed by the retryRatio |
| `ttl` | indicates for how long requests should be considered for the purposes of calculating the retryRatio |
{{< /table >}}
