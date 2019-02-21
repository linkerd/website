+++
date = "2019-02-17T12:00:00-07:00"
title = "Configuring Retries"
description = "Configure Linkerd to retry outgoing requests on failure."
+++

In order for Linkerd to do automatic retries of failures, there are two
questions that need to be answered:

- Which requests should be retried?
- How many times should the requests be retried?

Both of these questions can be answered by specifying a bit of extra information
in the [service profile](/2/features/service-profiles/) for the service you're
sending requests to.

The reason why these pieces of configuration are required is because retries can
potentially be dangerous. Automatically retrying a request that changes state
(e.g. a request that submits a financial transaction) could potentially impact
your user's experience negatively. In addition, retries increase the load on
your system. A set of services that have requests being constantly retried
could potentially get taken down by the retries instead of being allowed time
to recover.

Check out the [retries section](/2/tasks/books/#retries) of the books demo for a
tutorial of how to configure retries.

## Retries

For routes that are idempotent and do have bodies,
you can edit the service profile and add the `isRetryable` flag:

```yaml
spec:
  routes:
  - name: GET /api/annotations
    condition:
      method: GET
      pathRegex: /api/annotations
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
