+++
date = "2018-07-31T12:00:00-07:00"
title = "Supported Protocols"
[menu.l5d2docs]
  name = "Supported Protocols"
  weight = 6
+++

Linkerd is capable of proxying all TCP traffic, including:

- HTTP/1.x
- HTTP/2
- gRPC
- WebSockets
- HTTP tunneling
- plain old TCP traffic

To be a fully transparent proxy, Linkerd does *protocol detection*, allowing it
to detect when HTTP, HTTP/2, and gRPC traffic passes through the proxy, and
provide additional, request-level functionality when that happens. (E.g.,
measuring success rate of calls.)

For the vast majority of applications, Linkerd should "just work," without
requiring any configuration. However, in some cases, it is not possible to do
this protocol detection automatically.

## Handling server-speaks-first protocols

For protocols where the server sends data before the client sends data over
connections that aren't protected by TLS, Linkerd cannot automatically recognize
the protocol used on the connection.

This applies to the following list:

* 25   - SMTP
* 3306 - MySQL
* 8086 - InfluxDB

If you are using Linkerd to proxy these protocols on their default ports (3306
and 25, respectively), then Linkerd is able to successfully identify these
protocols based on the port. However, if you're using non-default ports, or if
you're using a different server-speaks-first protocol, then you'll need to
manually configure Linkerd to recognize these protocols, using the
`--skip-inbound-ports` and `--skip-outbound-ports` flags with `linkerd
inject`.

For example, if your application makes requests to a MySQL database running on
port 4406, use the command:

```bash
linkerd inject deployment.yml --skip-outbound-ports=4406 \
  | kubectl apply -f -
```

Likewise if your application runs an SMTP server that accepts incoming requests
on port 35, use the command:

```bash
linkerd inject deployment.yml --skip-inbound-ports=35 \
  | kubectl apply -f -
```

## Notes

* gRPC applications that use grpc-go must use grpc-go version 1.3 or later due
  to a [gRPC bug](https://github.com/grpc/grpc-go/issues/1120) in earlier versions.
