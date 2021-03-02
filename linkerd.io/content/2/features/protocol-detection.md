+++
title = "TCP Proxying and Protocol Detection"
description = "Linkerd is capable of proxying all TCP traffic, including TLS'd connections, WebSockets, and HTTP tunneling."
weight = 2
aliases = [
  "/2/supported-protocols/"
]
+++

Linkerd is capable of proxying all TCP traffic, including TLS'd connections,
WebSockets, and HTTP tunneling.

Linkerd performs *protocol detection* to determine whether traffic is HTTP or
HTTP/2 (including gRPC). If Linkerd detects that a connection is using HTTP or
HTTP/2, Linkerd will automatically provide HTTP-level metrics and routing
without configuration from the user. (See
[HTTP, HTTP/2, and gRPC Proxying](../http-grpc/) for more.)

If Linkerd *cannot* determine that a connection is using HTTP or HTTP/2, Linkerd
will proxy the connection, but will only be able to provide byte-level metrics.
Note that this also applies to TLS'd HTTP connections if the application
initiates the TLS, as Linkerd will not be able to observe the HTTP transactions
in this connection.

## Configuring Protocol Detection

In some cases Linkerd's protocol detection requires configuration. Currently,
this is required for unencrypted "server-speaks-first" protocols, or protocols
where the server sends data before the client sends data. In these cases,
Linkerd cannot automatically recognize the protocol used on the connection.
(Note that TLS-enabled connections work as normal, because TLS itself is a
client-speaks-first protocol.)

The following protocols are known to be server-speaks-first and are treated as
opaque by default:

* 25   - SMTP
* 3306 - MySQL
* 4222 - NATS
* 5432 - PostgreSQL
* 11211 - Memcached (clients do not issue any preamble, which breaks detection)

If you're working with a protocol that can't be automatically recognized by
Linkerd, you will need to set the `config.linkerd.io/opaque-ports` annotation on
both the Pod template spec of the workload and on the Service.  This annotation
tells Linkerd to skip protocol detection and immediately treat connections on
those ports as opaque TCP.  

Setting this annotation on the Service resource tells meshed clients to skip
protocol detection when proxying connections on those ports to the Service.
Similarly, setting this annotation on the Pod template spec tells Linkerd to skip
protocol detection when reverse-proxying incoming connections on those ports.
This means that it is still important to set this annotation on Services that use
server-speaks-first protocols if they have any meshed clients, even if that
Service itself is not meshed.

This annotation can easily be set on both Pod template specs and Services by
using the `--opaque-ports` flag when running `linkerd inject`.

For example, if you have a MySQL database running on port 4406, use the
commands:

```bash
linkerd inject mysql-deployment.yml --opaque-ports=4406 \
  | kubectl apply -f -
 linkerd inject mysql-service.yml --opaque-ports=4406 \
  | kubectl apply -f -
```

## Skipping the Proxy

Sometimes it is necessary to bypass the proxy altogether.  For example, when
connecting to a server-speaks-first server which is outside of the cluster,
there is no Service resource on which to set the
`config.linkerd.io/opaque-ports` annotation.  In this case you can use the
`--skip-outbound-ports` flag when running `linkerd inject` which will configure
the Pod to bypass the proxy entirely when sending to those ports.  Similarly,
the `--skip-inbound-ports` flag will configure the Pod to bypass the proxy for
incoming connections to those ports.

Skipping the proxy can be useful when diagnosing issues but otherwise should
rarely be necessary.  Using the `config.linkerd.io/opaque-ports` annotation is
the preferred method for dealing with server-speaks-first protocols since this
will allow Linkerd to provide TCP metrics and mTLS.
