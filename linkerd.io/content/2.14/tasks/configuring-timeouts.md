---
title: Configuring Timeouts
description: Configure Linkerd to automatically fail requests that take too long.
---

To limit how long Linkerd will wait before failing an outgoing request to
another service, you can configure timeouts. Timeouts specify the maximum amount
of time to wait for a response from a remote service to complete after the
request is sent. If the timeout elapses without receiving a response, Linkerd
will cancel the request and return a [504 Gateway Timeout] response.

Timeouts can be specified either [using HTTPRoutes](#using-httproutes) or [using
legacy ServiceProfiles](#using-serviceprofiles). Since [HTTPRoute] is a newer
configuration mechanism intended to replace [ServiceProfile]s, prefer the use of
HTTPRoute timeouts unless a ServiceProfile already exists for the Service.

## Using HTTPRoutes

Linkerd supports timeouts as specified in [GEP-1742], for [outbound
HTTPRoutes](../../features/httproute/#inbound-and-outbound-httproutes)
with Service parents.

{{< warning >}}
Support for [GEP-1742](https://gateway-api.sigs.k8s.io/geps/gep-1742/) has not
yet been implemented by the upstream Gateway API HTTPRoute resource. The GEP has
been accepted, but it has not yet been added to the definition of the HTTPRoute
resource. This means that HTTPRoute timeout fields can currently be used only in
HTTPRoute resources with the `policy.linkerd.io` API group, *not* the
`gateway.networking.k8s.io` API group.

When the [GEP-1742](https://gateway-api.sigs.k8s.io/geps/gep-1742/) timeout
fields are added to the upstream resource definition, Linkerd will support
timeout configuration for HTTPRoutes with both API groups.

See [the HTTPRoute reference
documentation](../../reference/httproute/#linkerd-and-gateway-api-httproutes)
for details on the two versions of the HTTPRoute resource.
{{< /warning >}}

Each [rule](../../reference/httproute/#httprouterule) in an [HTTPRoute] may
define an optional [`timeouts`](../../reference/httproute/#httproutetimeouts)
object, which can define `request` and/or `backendRequest` fields:

- `timeouts.request` specifies the *total time* to wait for a request matching
  this rule to complete (including retries). This timeout starts when the proxy
  receives a request, and ends when successful response is sent to the client.
- `timeouts.backendRequest` specifies the time to wait for a single request to a
  backend to complete. This timeout starts when a request is dispatched to a
  [backend](../../reference/httproute/#httpbackendref), and ends when a response
  is received from that backend. This is a subset of the `timeouts.request`
  timeout. If the request fails and is retried (if applicable), the
  `backendRequest` timeout will be restarted for each retry request.

Timeout durations are specified specified as strings using the [Gateway API
duration format] specified by
[GEP-2257](https://gateway-api.sigs.k8s.io/geps/gep-2257/)
(e.g. 1h/1m/1s/1ms), and must be at least 1ms. If either field is unspecified or
set to 0, the timeout configured by that field will not be enforced.

For example:

```yaml
spec:
  rules:
  - matches:
    - path:
        type: RegularExpression
        value: /authors/[^/]*\.json"
      method: GET
    timeouts:
      request: 600ms
      backendRequest: 300ms
```

## Using ServiceProfiles

Each [route](../../reference/service-profiles/#route) in a [ServiceProfile] may
define a request timeout for requests matching that route. This timeout secifies
the maximum amount of time to wait for a response (including retries) to
complete after the request is sent.

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
a tutorial of how to configure timeouts using ServiceProfiles.

## Monitoring Timeouts

Requests which reach the timeout will be canceled, return a [504 Gateway
Timeout] response, and count as a failure for the purposes of [effective success
rate](../configuring-retries/#monitoring-retries).  Since the request was
canceled before any actual response was received, a timeout will not count
towards the actual request volume at all.  This means that effective request
rate can be higher than actual request rate when timeouts are configured.
Furthermore, if a response is received just as the timeout is exceeded, it is
possible for the request to be counted as an actual success but an effective
failure.  This can result in effective success rate being lower than actual
success rate.

[HTTPRoute]: ../../features/httproute/
[ServiceProfile]: ../../features/service-profiles/
[504 Gateway Timeout]:
    https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/504
[GEP-1742]: https://gateway-api.sigs.k8s.io/geps/gep-1742/
[Gateway API duration format]:
    https://gateway-api.sigs.k8s.io/geps/gep-2257/#gateway-api-duration-format
