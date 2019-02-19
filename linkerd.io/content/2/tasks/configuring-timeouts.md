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
  - condition:
      method: HEAD
      pathRegex: /authors/[^/]*\.json
    name: HEAD /authors/{id}.json
    timeout: 300ms
```

Check out the [timeouts section](/2/tasks/books/#timeouts) of the books demo for
a tutorial of how to configure timeouts.

## Example

This guide assumes that you've followed the steps to get the
[books](/2/tasks/books/) demo running.

Take a look at the latency for requests from `webapp` to `svc/books`:

```bash
$ linkerd routes deploy/webapp --to svc/books
ROUTE                     SERVICE   SUCCESS      RPS   LATENCY_P50   LATENCY_P95   LATENCY_P99
DELETE /books/{id}.json     books   100.00%   0.6rps           9ms          19ms          20ms
GET /books.json             books   100.00%   1.2rps           7ms          10ms          10ms
GET /books/{id}.json        books   100.00%   2.3rps           7ms          10ms          18ms
POST /books.json            books    48.00%   2.5rps          16ms          28ms          30ms
PUT /books/{id}.json        books    53.97%   1.1rps          75ms          98ms         100ms
[DEFAULT]                   books     0.00%   0.0rps           0ms           0ms           0ms
```

To test timeouts, let's edit the `books` service profile and add a particularly
impossible timeout:

```bash
$ kubectl edit sp/books.default.svc.cluster.local
[...]
  - condition:
      method: GET
      pathRegex: /books/[^/]*\.json
    name: GET /books/{id}.json
    timeout: 5ms ### ADD THIS LINE ###
```

Over time, we will see the `EFFECTIVE_SUCCESS` go down and there be a difference
between the `EFFECTIVE_RPS` and `ACTUAL_RPS`.

```bash
$ linkerd routes deploy/webapp --to svc/books -o wide
ROUTE                     SERVICE   EFFECTIVE_SUCCESS   EFFECTIVE_RPS   ACTUAL_SUCCESS   ACTUAL_RPS   LATENCY_P50   LATENCY_P95   LATENCY_P99
DELETE /books/{id}.json     books             100.00%          0.3rps          100.00%       0.3rps          15ms          20ms          20ms
GET /books.json             books             100.00%          0.6rps          100.00%       0.6rps           8ms          10ms          10ms
GET /books/{id}.json        books              14.78%          4.8rps          100.00%       0.7rps           6ms          10ms          15ms
POST /books.json            books              51.95%          1.3rps           51.95%       1.3rps          17ms          28ms          30ms
PUT /books/{id}.json        books              53.66%          0.7rps           53.66%       0.7rps          75ms          98ms         100ms
[DEFAULT]                   books               0.00%          0.0rps            0.00%       0.0rps           0ms           0ms           0ms
```

Note that the p99 latency appears to be greater than our 25ms timeout due to histogram bucketing artifacts.
