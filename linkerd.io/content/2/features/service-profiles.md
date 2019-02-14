+++
date = "2018-10-16T12:00:21-07:00"
title = "Service Profiles"
description = "Linkerd supports defining service profiles that enable per-route metrics and features such as retries and timeouts."
weight = 5
[menu.l5d2docs]
  name = "Service Profiles"
  parent = "features"
aliases = [
  "/2/service-profiles/"
]
+++

A service profile is a custom Kubernetes resource which allows you to give
Linkerd additional information about a service. In particular, it allows you to
define a list of routes for the service. Each route can use a regular expression
to define which paths should match that route, or use more complex matching
criteria. Defining a service profile enables Linkerd to report per-route metrics
and also allows you to enable per-route features such as retries and timeouts.

## Defining a Service Profile

Service profiles can be created with the `linkerd profile` command.  If you
have an [OpenAPI (Swagger)](https://swagger.io/docs/specification/about/) spec
for your service, you can use the `--open-api` flag to generate a service
profile from the OpenAPI spec file.

```bash
linkerd profile --open-api webapp.swagger webapp
```

This generates a service profile from the `webapp.swagger` OpenAPI spec file
for the `webapp` service.  The resulting service profile can be piped directly
to `kubectl apply` and will be installed into the service's namespace.

```bash
linkerd profile --open-api webapp.swagger webapp | kubectl apply -f -
```

Similarly, you can use the `--proto` flag to create a service profile from a
protobuf (gRPC) definition file or the `--tap` flag to create a service profile
based on a sampling of live traffic to the service.

If you'd like to craft your service profile by hand, you can use the
`--template` flag which outputs a commented service profile skeleton which you
can manually edit to define exactly the routes that you want.

Once you have created a service profile, you can use the `linkerd check`
command to validate it.

```bash
> linkerd check
[...]
linkerd-api: no invalid service profiles...................................[ok]
[...]
```

## Viewing Per-Route Metrics

Per-route metrics can be viewed by using the
[`linkerd routes` command](/2/cli/routes/).

## Overriding a Service Profile

There are times when you may need to define a service profile for a service
which resides in a namespace that you do not control.  To accomplish this,
simply create a service profile as before, but edit the namespace of the
service profile to the namespace of the pod which is calling the service.  When
Linkerd proxies a request to a service, a service profile in the source
namespace will take priority over a service profile in the destination
namespace.

## Debugging Service Profiles

To manually verify if requests are getting associated with the correct service
profile route, you can use `linkerd tap -o wide`.  Requests which have been
associated with a route will have a `rt_route` annotation.  For example:

```bash
req id=0:1 proxy=in  src=10.1.3.76:57152 dst=10.1.3.74:7000 tls=disabled :method=POST :authority=webapp.default:7000 :path=/books/2878/edit src_res=deploy/traffic src_ns=foobar dst_res=deploy/webapp dst_ns=default rt_route=POST /books/{id}/edit
```

Similarly, you can use the command `linkerd tap -o wide <target> | grep -v rt_route`
to see all requests to a target which have *not* been associated with any route.

## Service Profile Specification

### Spec

A service profile spec must contain the following top level fields:

| field| value |
|------|-------|
| `routes`| a list of [route](#route) objects |
| `retryBudget`| a [retry budget](#retry-budget) object that defines the maximum retry rate to this service |

### Route

A route object must contain the following fields:

| field | value |
|-------|-------|
| `name` | the name of this route as it will appear in the route label |
| `condition` | a [request match](#request-match) object that defines if a request matches this route |
| `responses` | (optional) a list of [response class](#response-class) objects |
| `isRetryable` | indicates that requests to this route are always safe to retry and will cause the proxy to retry failed requests on this route whenever possible |
| `timeout` | the maximum amount of time to wait for a response (including retries) to complete after the request is sent |

### Request Match

A request match object must contain _exactly one_ of the following fields:

| field | value |
|-------|-------|
| `pathRegex` | a regular expression to match the request path against |
| `method` | one of GET, POST, PUT, DELETE, OPTION, HEAD, TRACE |
| `all` | a list of [request match](#request-match) objects which must _all_ match |
| `any` | a list of [request match](#request-match) objects, at least one of which must match |
| `not` | a [request match](#request-match) object which must _not_ match |

### Response Class

A response class object must contain the following fields:

| field | value |
|-------|-------|
| `condition` | a [response match](#response-match) object that defines if a response matches this response class |
| `isSuccess` | a boolean that defines if these responses should be classified as successful |

### Response Match

A response match object must contain _exactly one_ of the following fields:

| field | value |
|-------|-------|
| `status` | a [status range](#status-range) object to match the response status code against |
| `all` | a list of [response match](#response-match) objects which must _all_ match |
| `any` | a list of [response match](#response-match) objects, at least one of which must match |
| `not` | a [response match](#response-match) object which must _not_ match |

### Status Range

A status range object must contain _at least one_ of the following fields.
Specifying only one of min or max matches just that one status code.

| field | value |
|-------|-------|
| `min` | the status code must be greater than or equal to this value |
| `max` | the status code must be less than or equal to this value |

### Retry Budget

A retry budget specifies the maximum total number of retries that should be sent
to this service as a ratio of the original request volume.

| field | value |
|-------|-------|
| `retryRatio` | the maximum ratio of retries requests to original requests |
| `minRetriesPerSecond` | allowance of retries per second in addition to those allowed by the retryRatio |
| `ttl` | indicates for how long requests should be considered for the purposes of calculating the retryRatio |
