+++
aliases = ["/features/retries-deadlines"]
description = "Linkerd can automatically retry requests on certain failures and can timeout requests after a specified period."
title = "Retries and deadlines"
weight = 6
[menu.docs]
parent = "features"
weight = 10

+++
Failures are inevitable in a distributed system. Linkerd comes with several
configurable options that help make clients and servers more fault-tolerant and
reliable.

## Retries

Linkerd can automatically retry requests on certain failures (for example,
connection errors). See the [configuration documentation]({{% linkerdconfig
"retries" %}}) for examples. Linkerd comes with a few HTTP response classifiers
that determine which HTTP responses should be considered failures and which can
be retried. Thus, even if one instance of a service is failing, clients can
maximize success rates. Retry budgets (the percentage of requests that Linkerd
will retry) are configurable so that you can avoid overloading your server.

## Timeouts

You can also specify a per-request timeout on the
[router]({{% linkerdconfig "routers" %}}) level so that the
service does not spend an inordinate amount of time on a request. This, coupled
with deadlines, allows you to use your services more efficiently.

## Deadlines

Deadlines allow you to specify time bounds within which a request is expected to
be satisfied (or within which the response is still useful). This is very handy
to avoid occupying your service's resources trying to fulfill very long-running
requests. This feature is not fully implemented yet, but is coming soon.

For more info on deadlines related to service to service communication, check
out [Marius Eriksen's article](https://monkey.org/~marius/redux.html#TOC_4.2).
