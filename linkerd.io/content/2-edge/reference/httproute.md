+++
title = "HTTPRoute"
description = "Reference guide to HTTPRoute resources."
+++

## Linkerd and Gateway API HTTPRoutes

The HTTPRoute resource was originally specified by the Kubernetes [Gateway API]
project. Linkerd currently supports two versions of the HTTPRoute resource: the
upstream version from the Gateway API, with the
`gateway.networking.kubernetes.io` API group, and a Linkerd-specific version,
with the `policy.linkerd.io` API group. While these two resource definitions are
largely the same, the `policy.linkerd.io` HTTPRoute resource is an experimental
version that contains features not yet stabilized in the upstream
`gateway.networking.k8s.io` HTTPRoute resource, such as
[timeouts](#httproutetimeouts). Both the Linkerd and Gateway API resource
definitions may coexist within the same cluster, and both can be used to
configure policies for use with Linkerd.

This documentation describes the `policy.linkerd.io` HTTPRoute resource. For a
similar description of the upstream Gateway API HTTPRoute resource, refer to the
Gateway API's [HTTPRoute
specification](https://gateway-api.sigs.k8s.io/references/spec/#gateway.networking.k8s.io/v1beta1.HTTPRoute).

## HTTPRoute Spec

An HTTPRoute spec may contain the following top level fields:

{{< table >}}
| field| value |
|------|-------|
| `parentRefs`| A set of [ParentReference](#parentreference)s which indicate which [Servers](#server) or Services this HTTPRoute attaches to.|
| `hostnames`| A set of hostnames that should match against the HTTP Host header.|
| `rules`| An array of [HTTPRouteRules](#httprouterule).|
{{< /table >}}

### parentReference

A reference to the parent resource this HTTPRoute is a part of.

HTTPRoutes can be attached to a [Server](../authorization-policy/#server) to
allow defining an [authorization
policy](../authorization-policy/#authorizationpolicy) for specific routes served
on that Server.

HTTPRoutes can also be attached to a Service, in order to route requests
depending on path, headers, query params, and/or verb. Requests can then be
rerouted to different backend services. This can be used to perform [dynamic
request routing](../../tasks/configuring-dynamic-request-routing/).

{{< warning >}}
**Outbound HTTPRoutes and [ServiceProfile](../../features/service-profiles/)s
provide overlapping configuration.** For backwards-compatibility reasons, a
ServiceProfile will take precedence over HTTPRoutes which configure the same
Service. If a ServiceProfile is defined for the parent Service of an HTTPRoute,
proxies will use the ServiceProfile configuration, rather than the HTTPRoute
configuration, as long as the ServiceProfile exists.
{{< /warning >}}

ParentReferences are namespaced, and may reference either a parent in the same
namespace as the HTTPRoute, or one in a different namespace. As described in
[GEP-1426][ns-boundaries], a HTTPRoute with a `parentRef` that references a
Service  in the same namespace as the HTTPRoute is referred to as a _producer
route_, while an HTTPRoute with a `parentRef` referencing a Service in a
different namespace is referred to as a _consumer route_. A producer route will
apply to requests originating from clients in any namespace. On the other hand,
a consumer route is scoped to apply only to traffic originating in the
HTTPRoute's namespace. See the ["Namespace boundaries" section in
GEP-1426][ns-boundaries] for details on producer and consumer routes.

{{< table >}}
| field| value |
|------|-------|
| `group`| The group of the referent. This must either be "policy.linkerd.io" (for Server) or "core" (for Service).|
| `kind`| The kind of the referent. This must be either "Server" or "Service".|
| `port`| The targeted port number, when attaching to Services.|
| `namespace`| The namespace of the referent. When unspecified (or empty string), this refers to the local namespace of the Route.|
| `name`| The name of the referent.|
{{< /table >}}

### httpRouteRule

HTTPRouteRule defines semantics for matching an HTTP request based on conditions
(matches) and processing it (filters).

{{< table >}}
| field| value |
|------|-------|
| `matches`| A list of [httpRouteMatches](#httproutematch). Each match is independent, i.e. this rule will be matched if **any** one of the matches is satisfied.|
| `filters`| A list of [httpRouteFilters](#httproutefilter) which will be applied to each request which matches this rule.|
| `backendRefs`| An array of [HTTPBackendRefs](#httpbackendref) to declare where the traffic should be routed to (only allowed with Service [parentRefs](#parentreference)).|
| `timeouts` | An optional [httpRouteTimeouts](#httproutetimeouts) object which configures timeouts for requests matching this rule. |
{{< /table >}}

### httpRouteMatch

HTTPRouteMatch defines the predicate used to match requests to a given
action. Multiple match types are ANDed together, i.e. the match will
evaluate to true only if all conditions are satisfied.

{{< table >}}
| field| value |
|------|-------|
| `path`| An [httpPathMatch](#httppathmatch). If this field is not specified, a default prefix match on the "/" path is provided.|
| `headers`| A list of [httpHeaderMatches](#httpheadermatch). Multiple match values are ANDed together.|
| `queryParams`| A list of [httpQueryParamMatches](#httpqueryparammatch). Multiple match values are ANDed together.|
| `method`| When specified, this route will be matched only if the request has the specified method.|
{{< /table >}}

### httpPathMatch

`HTTPPathMatch` describes how to select a HTTP route by matching the HTTP
request path.

{{< table >}}
| field| value |
|------|-------|
| `type`| How to match against the path Value. One of: Exact, PathPrefix, RegularExpression. If this field is not specified, a default of "PathPrefix" is provided.|
| `value`| The HTTP path to match against.|
{{< /table >}}

### httpHeaderMatch

`HTTPHeaderMatch` describes how to select a HTTP route by matching HTTP request
headers.

{{< table >}}
| field| value |
|------|-------|
| `type`| How to match against the value of the header. One of: Exact, RegularExpression. If this field is not specified, a default of "Exact" is provided.|
| `name`| The HTTP Header to be matched against. Name matching MUST be case insensitive.|
| `value`| Value of HTTP Header to be matched.|
{{< /table >}}

### httpQueryParamMatch

`HTTPQueryParamMatch` describes how to select a HTTP route by matching HTTP
query parameters.

{{< table >}}
| field| value |
|------|-------|
| `type`| How to match against the value of the query parameter. One of: Exact, RegularExpression. If this field is not specified, a default of "Exact" is provided.|
| `name`| The HTTP query param to be matched. This must be an exact string match.|
| `value`| Value of HTTP query param to be matched.|
{{< /table >}}

### httpRouteFilter

HTTPRouteFilter defines processing steps that must be completed during the
request or response lifecycle.

{{< table >}}
| field| value |
|------|-------|
| `type`| One of: RequestHeaderModifier, ResponseHeaderModifier, or RequestRedirect.|
| `requestHeaderModifier`| An [httpHeaderFilter](#httpheaderfilter) which modifies request headers.|
| `responseHeaderModifier` | An [httpHeaderFilter](#httpheaderfilter) which modifies response headers.|
| `requestRedirect`| An [httpRequestRedirectFilter](#httprequestredirectfilter).|
{{< /table >}}

### httpHeaderFilter

A filter which modifies HTTP request or response headers.

{{< table >}}
| field| value |
|------|-------|
| `set`| A list of [httpHeaders](#httpheader) to overwrite on the request or response.|
| `add`| A list of [httpHeaders](#httpheader) to add on to the request or response, appending to any existing value.|
| `remove`| A list of header names to remove from the request or response.|
{{< /table >}}

### httpHeader

`HTTPHeader` represents an HTTP Header name and value as defined by RFC 7230.

{{< table >}}
| field| value |
|------|-------|
| `name`| Name of the HTTP Header to be matched. Name matching MUST be case insensitive.|
| `value`| Value of HTTP Header to be matched.|
{{< /table >}}

### httpRequestRedirectFilter

`HTTPRequestRedirect` defines a filter that redirects a request.

{{< table >}}
| field| value |
|------|-------|
| `scheme`| The scheme to be used in the value of the `Location` header in the response. When empty, the scheme of the request is used.|
| `hostname`| The hostname to be used in the value of the `Location` header in the response. When empty, the hostname of the request is used.|
| `path`| An [httpPathModfier](#httppathmodfier) which modifies the path of the incoming request and uses the modified path in the `Location` header.|
| `port`| The port to be used in the value of the `Location` header in the response. When empty, port (if specified) of the request is used.|
| `statusCode`| The HTTP status code to be used in response.|
{{< /table >}}

### httpPathModfier

`HTTPPathModifier` defines configuration for path modifiers.

{{< table >}}
| field| value |
|------|-------|
| `type`| One of: ReplaceFullPath, ReplacePrefixMatch.|
| `replaceFullPath`| The value with which to replace the full path of a request during a rewrite or redirect.|
| `replacePrefixMatch`| The value with which to replace the prefix match of a request during a rewrite or redirect.|
{{< /table >}}

### httpBackendRef

`HTTPBackendRef` defines the list of objects where matching requests should be
sent to. Only allowed when a route has Service [parentRefs](#parentReference).

{{< table >}}
| field| value |
|------|-------|
| `name`| Name of service for this backend.|
| `port`| Destination port number for this backend.|
| `namespace`| Namespace of service for this backend.|
| `weight`| Proportion of requests sent to this backend.|
{{< /table >}}

### httpRouteTimeouts

`HTTPRouteTimeouts` defines the timeouts that can be configured for an HTTP
request.

Linkerd implements HTTPRoute timeouts as described in [GEP-1742]. Timeout
durations are specified as strings using the [Gateway API duration format]
specified by [GEP-2257](https://gateway-api.sigs.k8s.io/geps/gep-2257/) (e.g.
1h/1m/1s/1ms), and MUST be at least 1ms. A timeout field with duration 0
disables that timeout.

{{< table >}}
| field| value |
|------|-------|
| `request` | Specifies the duration for processing an HTTP client request after which the proxy will time out if unable to send a response. When this field is unspecified or 0, the proxy will not enforce request timeouts. |
| `backendRequest` | Specifies a timeout for an individual request from the proxy to a backend service. This covers the time from when the request first starts being sent from the proxy to when the response has been received from the backend. When this field is unspecified or 0, the proxy will not enforce a backend request timeout, but may still enforce the `request` timeout, if one is configured. |
{{< /table >}}

If retries are enabled, a request received by the proxy may be retried by
sending it to a different backend. In this case, a new `backendRequest` timeout
will be started for each retry request, but each retry request will count
against the overall `request` timeout.

[GEP-1742]: https://gateway-api.sigs.k8s.io/geps/gep-1742/
[Gateway API duration format]: https://gateway-api.sigs.k8s.io/geps/gep-2257/#gateway-api-duration-format

## HTTPRoute Examples

An HTTPRoute attached to a Server resource which matches GETs to
`/authors.json` or `/authors/*`:

```yaml
apiVersion: policy.linkerd.io/v1beta2
kind: HTTPRoute
metadata:
  name: authors-get-route
  namespace: booksapp
spec:
  parentRefs:
    - name: authors-server
      kind: Server
      group: policy.linkerd.io
  rules:
    - matches:
      - path:
          value: "/authors.json"
        method: GET
      - path:
          value: "/authors/"
          type: "PathPrefix"
        method: GET
```

An HTTPRoute attached to a Service to perform header-based routing. If there's
a `x-faces-user: testuser` header in the request, the request is routed to the
`smiley2` backend Service. Otherwise, the request is routed to the `smiley`
backend Service.

```yaml
apiVersion: policy.linkerd.io/v1beta2
kind: HTTPRoute
metadata:
  name: smiley-a-b
  namespace: faces
spec:
  parentRefs:
    - name: smiley
      kind: Service
      group: core
      port: 80
  rules:
    - matches:
      - headers:
        - name: "x-faces-user"
          value: "testuser"
      backendRefs:
        - name: smiley2
          port: 80
    - backendRefs:
      - name: smiley
        port: 80
```

[ServiceProfile]: ../../features/service-profiles/
[Gateway API]: https://gateway-api.sigs.k8s.io/
[GEP-1426]: https://gateway-api.sigs.k8s.io/geps/gep-1426/#namespace-boundaries
