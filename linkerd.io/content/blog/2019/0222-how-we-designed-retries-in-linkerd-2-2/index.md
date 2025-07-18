---
date: 2019-02-22T00:00:00Z
slug: how-we-designed-retries-in-linkerd-2-2
title: How we designed retries in Linkerd 2.2
keywords: [news]
params:
  author: alex
---

Retries are a fundamental mechanism for handling partial or transient failures in a distributed system. But retries can also be dangerous—if done poorly, they can rapidly escalate a small error into a system-wide outage. In this post, we describe how we designed retries in Linkerd 2.2 in a way that allows Linkerd to automatically improve system reliability while minimizing risk.

## Marking a route as retryable

In Linkerd 2.2 we introduced _retries_, or the ability for Linkerd to automatically retry failed requests. This gives Linkerd the ability to automatically handle partial or transient failures in a service, without the application having to be aware: if a request fails, Linkerd can just try it again! Combined with Linkerd's [request-level load balancing](/2/features/load-balancing/), this also allows Linkerd to handle failures of individual pods. In Linkerd, you specify retries as part of a [service profile](/2/features/service-profiles/) (introduced in a [previous blog post](/2018/12/08/service-profiles-for-per-route-metrics/)). Marking a route as retryable is as simple as adding \`isRetryable: true\` to the corresponding service profile entry:

```yaml
- name: HEAD /authors/{id}.json
    condition:
      method: HEAD
      pathRegex: /authors/[^/]*\\.json
    isRetryable: true
```

Of course, before you add retry behavior to a route, you should make sure that the route is _idempotent_—in other words, that multiple calls to the same route with the same parameters will have no ill effects. This is important because retries (by definition!) may cause multiple copies of the same request to be sent to a service. If the request does something non-idempotent, e.g. subtracting a dollar from your bank account, you probably don't want it to be automatically retried. Once enabled, retries have two important parameters: a _budget_ and a _timeout_. Let's take both of these in turn.

## Using retry budgets

Once you've marked a route as retryable, Linkerd allows you to configure a _retry budget_ for a service. Linkerd ships with reasonable default values, but if you want to customize the budget, you can set it in the service profile:

```yaml
retryBudget:
  # The retryRatio is the maximum ratio of retries requests to original
  # requests.  A retryRatio of 0.2 means that retries may add at most an
  # additional 20% to the request load.
  retryRatio: 0.2

  # This is an allowance of retries per second in addition to those allowed
  # by the retryRatio.  This allows retries to be performed, when the request
  # rate is very low.
  minRetriesPerSecond: 10

  # This duration indicates for how long requests should be considered for the
  # purposes of calculating the retryRatio.  A higher value considers a larger
  # window and therefore allows burstier retries.
  ttl: 10s
```

Linkerd's use of retry budgets is a better alternative to the normal practice of configuring retries with the _max retries_. Let's take a moment to understand why.

### Why budgets and not max retries?

First, some background. The most common way of configuring retries is to specify a maximum number of retry attempts to perform before giving up. This is a familiar idea to anyone who's used a web browser: you try to load a webpage, and if it doesn't load, you try again. If it still doesn't load, you try a third time. Finally you give up. Unfortunately, there are at least two problems with configuring retries this way:

**Choosing the maximum number of retry attempts is a guessing game.** You need to pick a number that’s high enough to make a difference when things are _somewhat_ failing, but not so high that it generates extra load on the system when it's _really_ failing. In practice, you usually pick a maximum retry attempts number out of a hat (e.g. 3) and hope for the best.

**Systems configured this way are vulnerable to retry storms.** A retry storm begins when one service starts to experience a larger than normal failure rate. This causes its clients to retry those failed requests. The extra load from the retries causes the service to slow down further and fail more requests, triggering more retries. If each client is configured to retry up to 3 times, this can quadruple the number of requests being sent! To make matters even worse, if any of the clients’ clients are configured with retries, the number of retries compounds multiplicatively and can turn a small number of errors into a self-inflicted denial of service attack.

To avoid these problems, Linkerd uses retry budgets. Rather than specifying a fixed maximum number of retry attempts per request, Linkerd keeps track of the ratio between regular requests and retries and keeps this number below a limit. For example, you may specify that you want retries to add at most 20% more requests. Linkerd will then retry as much as it can while maintaining that ratio.

Thus, using retry budgets makes _explicit_ the trade-off between improving success rate and additional load. Your retry budget is exactly how much extra load your system is willing to accept from retries.

(And finally, a retry budget in Linkerd also includes an allowance for a minimum rate of retries which will always be allowed, independent of the ratio. This allows Linkerd to retry in very low traffic systems.)

## Setting per-request timeouts

In addition to a budgets, retries are parameterized by a per-request _timeout_. A timeout ensures that a request that always fails will eventually return a response, even if that response is a failure. Once the timeout is reached, Linkerd will cancel the request and return a HTTP 504 response. Similar to retry budgets, retry timeouts have a sane default that can be overridden in the service profile:

```yaml
- name: HEAD /authors/{id}.json
    condition:
      method: HEAD
      pathRegex: /authors/[^/]*\\.json
    timeout: 50ms
```

## Who owns retry behavior? The client or the server?

You may have noticed something interesting in the configuration snippets above. In "traditional" retrying systems  (e.g. a web browser), retry behavior is configured on the client—after all, this is where the retries actually take place. But in the service profiles above, we're specifying retry policy on the _server_ side instead.

Being able to attach policy to the server side, but have it be obeyed by the client side, is one of the fundamental benefits of Linkerd's service profile approach. Retry configuration logically _belongs_ at the level of the service ("this is how you should talk to me"). Since Linkerd controls both client and server behavior, we can do this the right way: a service profile allows a service to publish exactly "here is how I want you to talk to me", and all traffic going through Linkerd, regardless of source, will respect that behavior. Pretty cool!

## Putting it all together

We've shown how you can configure Linkerd's retry behavior by combining timeouts, budgets, and retryability. Now let's put it all together with a brief demo. If you have a terminal window and a Kubernetes cluster, you can follow along at home. We'll start by installing Linkerd and our sample books application:

```bash
linkerd install | kubectl apply -f - && \
  curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/booksapp.yml | linkerd inject - | kubectl apply -f - && \
  linkerd check
```

One thing that we can notice about this application is that the success rate of requests from the books service to the authors service is very poor:

```bash
$ linkerd routes deploy/books --to svc/authors
ROUTE       SERVICE   SUCCESS      RPS   LATENCY_P50   LATENCY_P95   LATENCY_P99
[DEFAULT]   authors    54.24%   3.9rps           5ms          14ms          19ms
```

To get a better picture of what’s going on here, let’s add a service profile for the authors service, generated from a Swagger definition:

<!-- markdownlint-disable MD014 -->
```bash
$ curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/booksapp/authors.swagger | linkerd profile --open-api - authors | kubectl apply -f  -
$ linkerd routes deploy/books --to svc/authors
ROUTE                       SERVICE   SUCCESS      RPS   LATENCY_P50   LATENCY_P95   LATENCY_P99
DELETE /authors/{id}.json   authors     0.00%   0.0rps           0ms           0ms           0ms
GET /authors.json           authors     0.00%   0.0rps           0ms           0ms           0ms
GET /authors/{id}.json      authors     0.00%   0.0rps           0ms           0ms           0ms
HEAD /authors/{id}.json     authors    50.85%   3.9rps           5ms          10ms          17ms
POST /authors.json          authors     0.00%   0.0rps           0ms           0ms           0ms
[DEFAULT]                   authors     0.00%   0.0rps           0ms           0ms           0ms
```
<!-- markdownlint-enable MD014 -->

One thing that’s clear is that all requests from books to authors are to the `HEAD /authors/{id}.json` route and those requests are failing about 50% of the time. To correct this, let’s edit the authors service profile and make those requests retryable:

```bash
$ kubectl edit sp/authors.default.svc.cluster.local
[...]
  - condition:
      method: HEAD
      pathRegex: /authors/[^/]*\\.json
    name: HEAD /authors/{id}.json
    isRetryable: true ### ADD THIS LINE ###
```

After editing the service profile, we see a nearly immediate improvement in success rate:

```bash
$ linkerd routes deploy/books --to svc/authors -o wide
ROUTE                       SERVICE   EFFECTIVE_SUCCESS   EFFECTIVE_RPS   ACTUAL_SUCCESS   ACTUAL_RPS   LATENCY_P50   LATENCY_P95   LATENCY_P99
DELETE /authors/{id}.json   authors               0.00%          0.0rps            0.00%       0.0rps           0ms           0ms           0ms
GET /authors.json           authors               0.00%          0.0rps            0.00%       0.0rps           0ms           0ms           0ms
GET /authors/{id}.json      authors               0.00%          0.0rps            0.00%       0.0rps           0ms           0ms           0ms
HEAD /authors/{id}.json     authors             100.00%          2.8rps           58.45%       4.7rps           7ms          25ms          37ms
POST /authors.json          authors               0.00%          0.0rps            0.00%       0.0rps           0ms           0ms           0ms
[DEFAULT]                   authors               0.00%          0.0rps            0.00%       0.0rps           0ms           0ms           0ms
```

Success rate looks great but the p95 and p99 latencies have increased. This is to be expected because doing retries takes time. However, we can limit this by setting a [timeouts](/2/features/retries-and-timeouts/#timeouts) another new feature of Linkerd 2.x - at the maximum duration that we’re willing to wait. For the purposes of this demo, I’ll set a timeout of 25ms. Your results will vary depending on the characteristics of your system.

```bash
$ kubectl edit sp/authors.default.svc.cluster.local
[...]
  - condition:
      method: HEAD
      pathRegex: /authors/[^/]*\\.json
    isRetryable: true
    name: HEAD /authors/{id}.json
    timeout: 25ms ### ADD THIS LINE ###
```

We now see that success rate has come down slightly because some requests are timing out, but that the tail latency has been greatly reduced:

```bash
$ linkerd routes deploy/books --to svc/authors -o wide
ROUTE                       SERVICE   EFFECTIVE_SUCCESS   EFFECTIVE_RPS   ACTUAL_SUCCESS   ACTUAL_RPS   LATENCY_P50   LATENCY_P95   LATENCY_P99
DELETE /authors/{id}.json   authors               0.00%          0.0rps            0.00%       0.0rps           0ms           0ms           0ms
GET /authors.json           authors               0.00%          0.0rps            0.00%       0.0rps           0ms           0ms           0ms
GET /authors/{id}.json      authors               0.00%          0.0rps            0.00%       0.0rps           0ms           0ms           0ms
HEAD /authors/{id}.json     authors              97.73%          2.9rps           49.71%       5.8rps           9ms          25ms          29ms
POST /authors.json          authors               0.00%          0.0rps            0.00%       0.0rps           0ms           0ms           0ms
[DEFAULT]                   authors               0.00%          0.0rps            0.00%       0.0rps           0ms           0ms           0ms
```

Note that the p99 latency appears to be greater than our 25ms timeout due to histogram bucketing artifacts.

## Conclusion

In this post, we described how Linkerd can automatically retry requests in a way that minimizes risk to the system. We described why retry behavior is specified at the server rather than client, level, and we walked you through a quick demonstration of how to deploy the retries and timeout features on a service in a demo app.

Retries are a big step forward in Linkerd's reliability roadmap. The intersection of service profiles, retries, and diagnostics is a particularly exciting area for Linkerd, and you can expect [more cool features](https://github.com/linkerd/linkerd2/issues/2016) in future releases—so stay tuned!

Like this post? Linkerd is a community project and is hosted by the [Cloud Native Computing Foundation](https://cncf.io/). If you have feature requests, questions, or comments, we’d love to have you join our rapidly-growing community! Linkerd is [hosted on GitHub](https://github.com/linkerd/linkerd2), and we have a thriving community on [Slack](https://slack.linkerd.io/), [Twitter](https://twitter.com/linkerd), and the [mailing lists](https://lists.cncf.io/g/cncf-linkerd-users). Come and join the fun!
