---
title: Setting Up Service Profiles
description:
  Create a service profile that provides more details for Linkerd to build on.
---

{{< warning >}}

As of Linkerd 2.16, ServiceProfiles have been fully supplanted by
[Gateway API types](../features/gateway-api/), including for getting per-route
metrics, specifying timeouts, and specifying retries. Service profiles continue
to be supported for backwards compatibility, but will not receive further
feature development.

{{< /warning >}}

[Service profiles](../features/service-profiles/) provide Linkerd additional
information about a service and how to handle requests for a service.

When an HTTP (not HTTPS) request is received by a Linkerd proxy, the
`destination service` of that request is identified. If a service profile for
that destination service exists, then that service profile is used to to provide
per-route metric, retries, and timeouts.

The `destination service` for a request is computed by selecting the value of
the first header to exist of, `l5d-dst-override`, `:authority`, and `Host`. The
port component, if included and including the colon, is stripped. That value is
mapped to the fully qualified DNS name. When the `destination service` matches
the name of a service profile in the namespace of the sender or the receiver,
Linkerd will use that for additional features.

There are times when you may need to define a service profile for a service
which resides in a namespace that you do not control. To accomplish this, simply
create a service profile as before, but edit the namespace of the service
profile to the namespace of the pod which is calling the service. When Linkerd
proxies a request to a service, a service profile in the source namespace will
take priority over a service profile in the destination namespace.

Your `destination service` may be a
[ExternalName service](https://kubernetes.io/docs/concepts/services-networking/service/#externalname).
In that case, use the `spec.metadata.name` and the `spec.metadata.namespace'
values to name your ServiceProfile. For example,

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
  namespace: prod
spec:
  type: ExternalName
  externalName: my.database.example.com
```

use the name `my-service.prod.svc.cluster.local` for the ServiceProfile.

Note that at present, you cannot view statistics gathered for routes in this
ServiceProfile in the web dashboard. You can get the statistics using the CLI.

For a complete demo walkthrough, check out the [books](books/#service-profiles)
demo.

There are a couple different ways to use `linkerd profile` to create service
profiles.

{{< docs/toc >}}

Requests which have been associated with a route will have a `rt_route`
annotation. To manually verify if the requests are being associated correctly,
run `tap` on your own deployment:

```bash
linkerd viz tap -o wide <target> | grep req
```

The output will stream the requests that `deploy/webapp` is receiving in real
time. A sample is:

```bash
req id=0:1 proxy=in  src=10.1.3.76:57152 dst=10.1.3.74:7000 tls=disabled :method=POST :authority=webapp.default:7000 :path=/books/2878/edit src_res=deploy/traffic src_ns=foobar dst_res=deploy/webapp dst_ns=default rt_route=POST /books/{id}/edit
```

Conversely, if `rt_route` is not present, a request has _not_ been associated
with any route. Try running:

```bash
linkerd viz tap -o wide <target> | grep req | grep -v rt_route
```

## Swagger

If you have an [OpenAPI (Swagger)](https://swagger.io/docs/specification/about/)
spec for your service, you can use the `--open-api` flag to generate a service
profile from the OpenAPI spec file.

```bash
linkerd profile --open-api webapp.swagger webapp
```

This generates a service profile from the `webapp.swagger` OpenAPI spec file for
the `webapp` service. The resulting service profile can be piped directly to
`kubectl apply` and will be installed into the service's namespace.

```bash
linkerd profile --open-api webapp.swagger webapp | kubectl apply -f -
```

## Protobuf

If you have a [protobuf](https://developers.google.com/protocol-buffers/) format
for your service, you can use the `--proto` flag to generate a service profile.

```bash
linkerd profile --proto web.proto web-svc
```

This generates a service profile from the `web.proto` format file for the
`web-svc` service. The resulting service profile can be piped directly to
`kubectl apply` and will be installed into the service's namespace.

## Auto-Creation

It is common to not have an OpenAPI spec or a protobuf format. You can also
generate service profiles from watching live traffic. This is based off tap data
and is a great way to understand what service profiles can do for you. To start
this generation process, you can use the `--tap` flag:

```bash
linkerd viz profile -n emojivoto web-svc --tap deploy/web --tap-duration 10s
```

This generates a service profile from the traffic observed to `deploy/web` over
the 10 seconds that this command is running. The resulting service profile can
be piped directly to `kubectl apply` and will be installed into the service's
namespace.

## Template

Alongside all the methods for automatically creating service profiles, you can
get a template that allows you to add routes manually. To generate the template,
run:

```bash
linkerd profile -n emojivoto web-svc --template
```

This generates a service profile template with examples that can be manually
updated. Once you've updated the service profile, use `kubectl apply` to get it
installed into the service's namespace on your cluster.
