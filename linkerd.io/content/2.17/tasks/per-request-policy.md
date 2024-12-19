---
title: Per-Request Policy
description: Using HTTP headers to specify per-request policy
---

[Retries](../configuring-retries/) and [timeouts](../configuring-timeouts/) can
be configured by annotating Service, HTTPRoute, or GRPCRoute resources. This
will apply the retry or timeout policy to all requests that are sent to that
service/route.

Additionally, retry and timeout policy can be configured for individual HTTP
requests by adding special HTTP headers to those requests.

## Enabling Per-Request Policy

In order to enable per-request policy, Linkerd must be installed with the
`--set policyController.additionalArgs="--allow-l5d-request-headers"` flag or
the corresponding Helm value. Enabling per-request policy is **not**
recommended if your application accepts requests from untrusted sources (e.g.
if it is an ingress) since this allows untrusted clients to specify Linkerd
policy.

## Per-Request Policy Headers

Once per-request policy is enabled, the following HTTP headers can be added to
a request to set or override retry and/or timeout policy for that request:

+ `l5d-retry-http`: Overrides the `retry.linkerd.io/http` annotation
+ `l5d-retry-grpc`: Overrides the `retry.linkerd.io/grpc` annotation
+ `l5d-retry-limit`: Overrides the `retry.linkerd.io/limit` annotation
+ `l5d-retry-timeout`: Overrides the `retry.linkerd.io/timeout` annotation
+ `l5d-timeout`: Overrides the `timeout.linkerd.io/request` annotation
+ `l5d-response-timeout`: Overrides the `timeout.linkerd.io/response` annotation
