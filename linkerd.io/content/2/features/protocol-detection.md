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

The following protocols are known to be server-speaks-first:

* 25   - SMTP
* 3306 - MySQL
* 4222 - NATS
* 27017 - MongoDB

If you're working with a protocol that can't be automatically recognized by
Linkerd, use the `--skip-inbound-ports` and `--skip-outbound-ports` flags when
running `linkerd inject`.

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

## Plaintext MySQL and SMTP

For MySQL and SMTP, if you are using Linkerd to proxy plaintext connections on
their default ports (3306 and 25, respectively), then Linkerd will currently
identify these protocols based on the port, and will not attempt to perform
protocol detection. Thus, no extra configuration is necessary for plaintext
MySQL and SMTP connections.
