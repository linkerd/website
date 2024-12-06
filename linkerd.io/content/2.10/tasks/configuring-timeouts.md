---
title: Configuring Timeouts
description: Configure Linkerd to automatically fail requests that take too long.
---

To limit how long Linkerd will wait before failing an outgoing request to
another service, you can configure timeouts. These work by adding a little bit
of extra information to the [service profile](../../features/service-profiles/) for
the service you're sending requests to.

Each route may define a timeout which specifies the maximum amount of time to
wait for a response (including retries) to complete after the request is sent.
If this timeout is reached, Linkerd will cancel the request, and return a 504
response.  If unspecified, the default timeout is 10 seconds.

```yaml
spec:
  routes:
  - condition:
      method: HEAD
      pathRegex: /authors/[^/]*\.json
    name: HEAD /authors/{id}.json
    timeout: 300ms
```

Check out the [timeouts section](../books/#timeouts) of the books demo for
a tutorial of how to configure timeouts.

## Monitoring Timeouts

Requests which reach the timeout will be canceled, return a 504 Gateway Timeout
response, and count as a failure for the purposes of [effective success
rate](../configuring-retries/#monitoring-retries).  Since the request was
canceled before any actual response was received, a timeout will not count
towards the actual request volume at all.  This means that effective request
rate can be higher than actual request rate when timeouts are configured.
Furthermore, if a response is received just as the timeout is exceeded, it is
possible for the request to be counted as an actual success but an effective
failure.  This can result in effective success rate being lower than actual
success rate.
