+++
date = "2019-02-06T13:23:37-08:00"
title = "Retries and Timeouts"
description = "Linkerd can be configured to perform service-specific retries and timeouts."
weight = 3
[menu.l5d2docs]
  name = "Retries and Timeouts"
  parent = "features"
+++

A [service profile](/2/features/service-profiles/) may define certain routes as
retryable or specify timeouts for routes.  This will cause the Linkerd proxy to
perform the appropriate retries or timeouts when calling that service.  Retries
and timeouts are always performed on the *outbound* (client) side.

## Retries

A route in a service profile may be marked as retryable by setting the
`isRetryable` property to `true`.  This tells Linkerd that the route is safe to
retry and will cause Linkerd to retry any failed requests until either the
timeout is reached or the retry budget is exceeded (see below).

Example:

```yaml
  - condition:
      method: HEAD
      pathRegex: /authors/[^/]*\.json
    name: HEAD /authors/{id}.json
    isRetryable: true
```

Note that to avoid excessive buffering in the proxy, requests with bodies will
never be retried.

### Retry Budgets

A retry budget is a mechanism that limits the number of retries that can be
performed against a service as a percentage of original requests.  This
prevents retries from overwhelming your system.  By default, retries may add  at
most an additional 20% to the request load (plus an additional 10 "free"
retries per second).  These settings can be adjusted by setting a `retryBudget`
on your service profile.

Example:

```yaml
spec:
  retryBudget:
    retryRatio: 0.2
    minRetriesPerSecond: 10
    ttl: 10s
```

## Timeouts

Each route may define a timeout which specifies the maximum amount of time to
wait for a response (including retries) to complete after the request is sent.
If this timeout is reached, Linkerd will cancel the request, and return a 504
response.  If unspecified, the default timeout is 10 seconds.

Example:

```yaml
  - condition:
      method: HEAD
      pathRegex: /authors/[^/]*\.json
    name: HEAD /authors/{id}.json
    timeout: 300ms
```
