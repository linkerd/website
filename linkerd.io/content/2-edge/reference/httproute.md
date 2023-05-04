+++
title = "HTTPRoute"
description = "Reference guide to HTTPRoute resources."
+++

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
Outbound HTTPRoutes are **incompatible with ServiceProfiles**. If the
[ParentReference](#parentreference) of an HTTPRoute is a Service, and a
[ServiceProfile](../../features/service-profiles/) is also defined for that
Service, proxies will use the ServiceProfile configuration, rather than the
HTTPRoute configuration, as long as the ServiceProfile exists.
{{< /warning >}}

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
| `type`| One of: RequestHeaderModifier, RequestRedirect.|
| `requestHeaderModifier`| An [httpRequestHeaderFilter](#httprequestheaderfilter).|
| `requestRedirect`| An [httpRequestRedirectFilter](#httprequestredirectfilter).|
{{< /table >}}

### httpRequestHeaderFilter

A filter which modifies request headers.

{{< table >}}
| field| value |
|------|-------|
| `set`| A list of [httpHeaders](#httpheader) to overwrites on the request.|
| `add`|  A list of [httpHeaders](#httpheader) to add on the request, appending to any existing value.|
| `remove`|  A list of header names to remove from the request.|
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
