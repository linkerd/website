+++
date = "2018-07-31T12:00:00-07:00"
title = "Adding Your Service"
[menu.l5d2docs]
  name = "Adding Your Service"
  weight = 6
+++

In order for your service to take advantage of Linkerd, it needs to have the
proxy sidecar added to its resource definition. This is done by using the
Linkerd [CLI](../architecture/#cli) to update the definition and output YAML
that can be passed to `kubectl`. By using Kubernetes' rolling updates, the
availability of your application will not be affected.

To add Linkerd to your service, run:

```bash
linkerd inject deployment.yml \
  | kubectl apply -f -
```

`deployment.yml` is the Kubernetes config file containing your
application. This will add the proxy sidecar along with an `initContainer` that
configures iptables to pass all traffic through the proxy. By applying this new
configuration via `kubectl`, a rolling update of your deployment will be
triggered replacing each pod with a new one.

You will know that your service has been successfully added to the service mesh
if it's pods are reported to be meshed in the Meshed column of the Linkerd
dashboard.

{{< fig src="/images/getting-started/stat.png" title="Dashboard" >}}

You can always get to the Linkerd dashboard by running:

```bash
linkerd dashboard
```

## Protocol support

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

## Inject Reference

For more information on how the inject command works and all of the parameters
that can be set, look at the [reference](../cli/inject/).

## Notes

* Applications that use protocols where the server sends data before the client
  sends data may require additional configuration. See the
  [Protocol support](#protocol-support) section above.
* gRPC applications that use grpc-go must use grpc-go version 1.3 or later due
  to a [bug](https://github.com/grpc/grpc-go/issues/1120) in earlier versions.
