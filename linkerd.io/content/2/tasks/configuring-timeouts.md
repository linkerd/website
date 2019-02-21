+++
date = "2019-02-17T12:00:00-07:00"
title = "Configuring Timeouts"
description = "Configure how long Linkerd will wait before failing an outgoing request."
+++

To limit how long Linkerd will wait before failing an outgoing request to
another service, you can configure timeouts. These work by adding a little bit
of extra information to the [service profile](/2/features/service-profiles/) for
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

Check out the [timeouts section](/2/tasks/books/#timeouts) of the books demo for
a tutorial of how to configure timeouts.
