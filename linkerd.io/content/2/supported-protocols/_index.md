+++
date = "2018-07-31T12:00:00-07:00"
title = "Supported Protocols"
[menu.l5d2docs]
  name = "Supported Protocols"
  weight = 6
+++

Linkerd is capable of proxying all TCP traffic, including WebSockets and HTTP
tunneling, and reporting top-line metrics (success rates, latencies, etc) for
all HTTP, HTTP/2, and gRPC traffic.

### Server-speaks-first protocols

For protocols where the server sends data before the client sends data over
connections that aren't protected by TLS, Linkerd cannot automatically recognize
the protocol used on the connection.

This applies to the following list:

* 25   - SMTP
* 3306 - MySQL
* 8086 - InfluxDB

If you are using Linkerd to proxy plaintext MySQL
or SMTP requests on their default ports (3306 and 25, respectively), then Linkerd
is able to successfully identify these protocols based on the port. If you're
using non-default ports, or if you're using a different server-speaks-first
protocol, then you'll need to manually configure Linkerd to recognize these
protocols.

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

## Notes

* Applications that use protocols where the server sends data before the client
  sends data may require additional configuration. See the
  [Protocol support](#protocol-support) section above.
* gRPC applications that use grpc-go must use grpc-go version 1.3 or later due
  to a [bug](https://github.com/grpc/grpc-go/issues/1120) in earlier versions.
