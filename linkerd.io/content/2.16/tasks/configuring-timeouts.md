+++
title = "Configuring Timeouts"
description = "Configure Linkerd to automatically fail requests that take too long."
+++

To limit how long Linkerd will wait before failing an outgoing request to
another service, you can configure timeouts. Timeouts specify the maximum amount
of time to wait for a response from a remote service to complete after the
request is sent. If the timeout elapses without receiving a response, Linkerd
will cancel the request and return a [504 Gateway Timeout] response.

Timeouts can be specified by adding annotations to HTTPRoute, GRPCRoute, or
Service resources.

{{< warning >}}
Timeouts configured in this way are **incompatible with ServiceProfiles**. If a
[ServiceProfile](../../features/service-profiles/) is defined for a Service,
proxies will use the ServiceProfile timeout configuration and ignore any timeout
annotations.
{{< /warning >}}

## Timeouts

Check out the [timeouts section](../books/#timeouts) of the books demo
for a tutorial of how to configure timeouts.
