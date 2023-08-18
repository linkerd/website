+++
title = "Getting Per-Route Metrics"
description = "Configure per-route metrics for your application."
+++

To get per-route metrics, you must first create a
[service profile](../../features/service-profiles/). Once a service
profile has been created, Linkerd will add labels to the Prometheus metrics that
associate a specific request to a specific route.

For a tutorial that shows this functionality off, check out the
[books demo](../books/#service-profiles).

{{< note >}}
Routes configured in service profiles are different from [HTTPRoute] resources.
Service profile routes allow you to collect per-route metrics and configure
client-side behavior such as retries and timeouts. [HTTPRoute] resources, on the
other hand, can be the target of AuthorizationPolicies and allow you to specify
per-route authorization.
{{< /note >}}

You can view per-route metrics in the CLI by running `linkerd viz routes`:

```bash
$ linkerd viz routes svc/webapp
ROUTE                       SERVICE   SUCCESS      RPS   LATENCY_P50   LATENCY_P95   LATENCY_P99
GET /                        webapp   100.00%   0.6rps          25ms          30ms          30ms
GET /authors/{id}            webapp   100.00%   0.6rps          22ms          29ms          30ms
GET /books/{id}              webapp   100.00%   1.2rps          18ms          29ms          30ms
POST /authors                webapp   100.00%   0.6rps          32ms          46ms          49ms
POST /authors/{id}/delete    webapp   100.00%   0.6rps          45ms          87ms          98ms
POST /authors/{id}/edit      webapp     0.00%   0.0rps           0ms           0ms           0ms
POST /books                  webapp    50.76%   2.2rps          26ms          38ms          40ms
POST /books/{id}/delete      webapp   100.00%   0.6rps          24ms          29ms          30ms
POST /books/{id}/edit        webapp    60.71%   0.9rps          75ms          98ms         100ms
[DEFAULT]                    webapp     0.00%   0.0rps           0ms           0ms           0ms
```

The `[DEFAULT]` route is a catch-all, anything that does not match the regexes
specified in your service profile will end up there.

It is also possible to look the metrics up by other resource types, such as:

```bash
$ linkerd viz routes deploy/webapp
ROUTE                          SERVICE   SUCCESS      RPS   LATENCY_P50   LATENCY_P95   LATENCY_P99
[DEFAULT]                   kubernetes     0.00%   0.0rps           0ms           0ms           0ms
GET /                           webapp   100.00%   0.5rps          27ms          38ms          40ms
GET /authors/{id}               webapp   100.00%   0.6rps          18ms          29ms          30ms
GET /books/{id}                 webapp   100.00%   1.1rps          17ms          28ms          30ms
POST /authors                   webapp   100.00%   0.5rps          25ms          30ms          30ms
POST /authors/{id}/delete       webapp   100.00%   0.5rps          58ms          96ms          99ms
POST /authors/{id}/edit         webapp     0.00%   0.0rps           0ms           0ms           0ms
POST /books                     webapp    45.58%   2.5rps          33ms          82ms          97ms
POST /books/{id}/delete         webapp   100.00%   0.6rps          33ms          48ms          50ms
POST /books/{id}/edit           webapp    55.36%   0.9rps          79ms         160ms         192ms
[DEFAULT]                       webapp     0.00%   0.0rps           0ms           0ms           0ms
```

Then, it is possible to filter all the way down to requests going from a
specific resource to other services:

```bash
$ linkerd viz routes deploy/webapp --to svc/books
ROUTE                     SERVICE   SUCCESS      RPS   LATENCY_P50   LATENCY_P95   LATENCY_P99
DELETE /books/{id}.json     books   100.00%   0.5rps          18ms          29ms          30ms
GET /books.json             books   100.00%   1.1rps           7ms          12ms          18ms
GET /books/{id}.json        books   100.00%   2.5rps           6ms          10ms          10ms
POST /books.json            books    52.24%   2.2rps          23ms          34ms          39ms
PUT /books/{id}.json        books    41.98%   1.4rps          73ms          97ms          99ms
[DEFAULT]                   books     0.00%   0.0rps           0ms           0ms           0ms
```

## Troubleshooting

If you're not seeing any metrics, there are two likely culprits. In both cases,
`linkerd viz tap` can be used to understand the problem. For the resource that
the service points to, run:

```bash
linkerd viz tap deploy/webapp -o wide | grep req
```

A sample output is:

```bash
req id=3:1 proxy=in  src=10.4.0.14:58562 dst=10.4.1.4:7000 tls=disabled :method=POST :authority=webapp:7000 :path=/books/24783/edit src_res=deploy/traffic src_ns=default dst_res=deploy/webapp dst_ns=default rt_route=POST /books/{id}/edit
```

This will select only the requests observed and show the `:authority` and
`rt_route` that was used for each request.

- Linkerd discovers the right service profile to use via `:authority` or
  `Host` headers. The name of your service profile must match these headers.
  There are many reasons why these would not match, see
  [ingress](../../features/ingress/) for one reason. Another would be clients that
  use IPs directly such as Prometheus.
- Getting regexes to match can be tough and the ordering is important. Pay
  attention to `rt_route`. If it is missing entirely, compare the `:path` to
  the regex you'd like for it to match, and use a
  [tester](https://regex101.com/) with the Golang flavor of regex.

[HTTPRoute]: ../../features/httproute/
