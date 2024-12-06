---
title: Configuring Retries
description: Configure Linkerd to automatically retry failing requests.
---

In order for Linkerd to do automatic retries of failures, there are two
questions that need to be answered:

- Which requests should be retried?
- How many times should the requests be retried?

Both of these questions can be answered by adding annotations to the Service,
HTTPRoute, or GRPCRoute resource you're sending requests to.

The reason why these pieces of configuration are required is because retries can
potentially be dangerous. Automatically retrying a request that changes state
(e.g. a request that submits a financial transaction) could potentially impact
your user's experience negatively. In addition, retries increase the load on
your system. A set of services that have requests being constantly retried
could potentially get taken down by the retries instead of being allowed time
to recover.

Check out the [retries section](../books/#retries) of the books demo
for a tutorial of how to configure retries.

{{< warning >}}
Retries configured in this way are **incompatible with ServiceProfiles**. If a
[ServiceProfile](../../features/service-profiles/) is defined for a Service,
proxies will use the ServiceProfile retry configuration and ignore any retry
annotations.
{{< /warning >}}

## Retries

For HTTPRoutes that are idempotent, you can add the `retry.linkerd.io/http: 5xx`
annotation which instructs Linkerd to retry any requests which fail with an HTTP
response status in the 500s.

Note that requests will not be retried if the body exceeds 64KiB.

## Retry Limits

You can also add the `retry.linkerd.io/limit` annotation to specify the maximum
number of times a request may be retried. By default, this limit is `1`.

## gRPC Retries

Retries can also be configured for gRPC traffic by adding the
`retry.linkerd.io/grpc` annotation to a GRPCRoute or Service resource. The value
of this annotation is a comma seperated list of gRPC status codes that should
be retried.
