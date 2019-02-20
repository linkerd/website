+++
date = "2018-10-16T12:00:21-07:00"
title = "Service Profiles"
description = "Linkerd supports defining service profiles that enable per-route metrics and features such as retries and timeouts."
weight = 5
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
[`linkerd routes` command](/2/reference/cli/routes/).

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
