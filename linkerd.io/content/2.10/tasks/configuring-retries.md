---
title: Configuring Retries
description: Configure Linkerd to automatically retry failing requests.
---

In order for Linkerd to do automatic retries of failures, there are two
questions that need to be answered:

- Which requests should be retried?
- How many times should the requests be retried?

Both of these questions can be answered by specifying a bit of extra information
in the [service profile](../features/service-profiles/) for the service you're
sending requests to.

The reason why these pieces of configuration are required is because retries can
potentially be dangerous. Automatically retrying a request that changes state
(e.g. a request that submits a financial transaction) could potentially impact
your user's experience negatively. In addition, retries increase the load on
your system. A set of services that have requests being constantly retried
could potentially get taken down by the retries instead of being allowed time
to recover.

Check out the [retries section](books/#retries) of the books demo
for a tutorial of how to configure retries.

## Retries

For routes that are idempotent and don't have bodies, you can edit the service
profile and add `isRetryable` to the retryable route:

```yaml
spec:
  routes:
  - name: GET /api/annotations
    condition:
      method: GET
      pathRegex: /api/annotations
    isRetryable: true ### ADD THIS LINE ###
```

## Retry Budgets

A retry budget is a mechanism that limits the number of retries that can be
performed against a service as a percentage of original requests.  This
prevents retries from overwhelming your system.  By default, retries may add at
most an additional 20% to the request load (plus an additional 10 "free"
retries per second). These settings can be adjusted by setting a `retryBudget`
on your service profile.

```yaml
spec:
  retryBudget:
    retryRatio: 0.2
    minRetriesPerSecond: 10
    ttl: 10s
```

## Monitoring Retries

Retries can be monitored by using the `linkerd viz routes` command with the `--to`
flag and the `-o wide` flag.  Since retries are performed on the client-side,
we need to use the `--to` flag to see metrics for requests that one resource
is sending to another (from the server's point of view, retries are just
regular requests).  When both of these flags are specified, the `linkerd routes`
command will differentiate between "effective" and "actual" traffic.

```bash
ROUTE                       SERVICE   EFFECTIVE_SUCCESS   EFFECTIVE_RPS   ACTUAL_SUCCESS   ACTUAL_RPS   LATENCY_P50   LATENCY_P95   LATENCY_P99
HEAD /authors/{id}.json     authors             100.00%          2.8rps           58.45%       4.7rps           7ms          25ms          37ms
[DEFAULT]                   authors               0.00%          0.0rps            0.00%       0.0rps           0ms           0ms           0ms
```

Actual requests represent all requests that the client actually sends, including
original requests and retries.  Effective requests only count the original
requests.  Since an original request may trigger one or more retries, the actual
request volume is usually higher than the effective request volume when retries
are enabled.  Since an original request may fail the first time, but a retry of
that request might succeed, the effective success rate is usually ([but not
always](configuring-timeouts/#monitoring-timeouts)) higher than the
actual success rate.
