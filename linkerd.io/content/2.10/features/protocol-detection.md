+++
title = "TCP Proxying and Protocol Detection"
description = "Linkerd is capable of proxying all TCP traffic, including TLS'd connections, WebSockets, and HTTP tunneling."
weight = 2
aliases = [
  "/2.10/supported-protocols/"
]
+++

Linkerd is capable of proxying all TCP traffic, including TLS connections,
WebSockets, and HTTP tunneling.

In most cases, Linkerd can do this without configuration. To do this, Linkerd
performs *protocol detection* to determine whether traffic is HTTP or HTTP/2
(including gRPC). If Linkerd detects that a connection is HTTP or HTTP/2,
Linkerd will automatically provide HTTP-level metrics and routing.

If Linkerd *cannot* determine that a connection is using HTTP or HTTP/2,
Linkerd will proxy the connection as a plain TCP connection, applying
[mTLS](../automatic-mtls/) and providing byte-level metrics as usual.

{{< note >}}
Client-initiated HTTPS will be treated as TCP, not as HTTP, as Linkerd will not
be able to observe the HTTP transactions on the connection.
{{< /note >}}

## Configuring protocol detection

In some cases, Linkerd's protocol detection cannot function because it is not
provided with enough client data. This can result in a 10-second delay in
creating the connection as the protocol detection code waits for more data.
This situation is often encountered when using "server-speaks-first" protocols,
or protocols where the server sends data before the client does, and can be
avoided by supplying Linkerd with some additional configuration.

{{< note >}}
Regardless of the underlying protocol, client-initiated TLS connections do not
require any additional configuration, as TLS itself is a client-speaks-first
protocol.
{{< /note >}}

There are two basic mechanisms for configuring protocol detection: _opaque
ports_ and _skip ports_. Marking a port as _opaque_ instructs Linkerd to proxy
the connection as a TCP stream and not to attempt protocol detection. Marking a
port as _skip_ bypasses the proxy entirely. Opaque ports are generally
preferred (as Linkerd can provide mTLS, TCP-level metrics, etc), but crucially,
opaque ports can only be used for services inside the cluster.

By default, Linkerd automatically marks some ports as opaque, including the
default ports for SMTP, MySQL, PostgresQL, and Memcache.  Services that speak
those protocols, use the default ports, and are inside the cluster do not need
further configuration.

The following table summarizes some common server-speaks-first protocols and
the configuration necessary to handle them. The "on-cluster config" column
refers to the configuration when the destination is *on* the same cluster; the
"off-cluster config" to when the destination is external to the cluster.

| Protocol        | Default port(s) | On-cluster config | Off-cluster config |
|-----------------|-----------------|-------------------|--------------------|
| SMTP            | 25, 587         | none\*            | skip ports         |
| MySQL           | 3306            | none\*            | skip ports         |
| MySQL w/ Galera | 3306, 4444, 4567, 4568 | opaque ports | skip ports       |
| PostgreSQL      | 5432            | none\*            | skip ports         |
| Redis           | 6379            | opaque ports      | skip ports         |
| ElasticSearch   | 9300            | opaque ports      | skip ports         |
| Memcache        | 11211           | none\*            | skip ports         |

_\* No configuration is required if the standard port is used. If a
non-standard port is used, you must mark the port as opaque._

## Marking a port as opaque

You can use the `config.linkerd.io/opaque-ports` annotation to mark a port as
opaque. This instructions Linkerd to skip protocol detection for that port.

This annotation can be set on a workload, service, or namespace. Setting it on
a workload tells meshed clients of that workload to skip protocol detection for
connections established to the workload, and tells Linkerd to skip protocol
detection when reverse-proxying incoming connections. Setting it on a service
tells meshed clients to skip protocol detection when proxying connections to
the service. Set it on a namespace applies this behavior to all services and
workloads in that namespace.

{{< note >}}
Since this annotation informs the behavior of meshed _clients_, it can be
applied to services that use server-speaks-first protocols even if the service
itself is not meshed.
{{< /note >}}

Setting the opaque-ports annotation can be done by using the `--opaque-ports`
flag when running `linkerd inject`. For example, for a MySQL database running
on the cluster using a non-standard port 4406, you can use the commands:

```bash
linkerd inject mysql-deployment.yml --opaque-ports=4406 \
  | kubectl apply -f -
 linkerd inject mysql-service.yml --opaque-ports=4406 \
  | kubectl apply -f -
```

{{< note >}}
Multiple ports can be provided as a comma-delimited string. The values you
provide will replace, not augment, the default list of opaque ports.
{{< /note >}}

## Skipping the proxy

Sometimes it is necessary to bypass the proxy altogether. For example, when
connecting to a server-speaks-first destination that is outside of the cluster,
there is no Service resource on which to set the
`config.linkerd.io/opaque-ports` annotation.

In this case, you can use the `--skip-outbound-ports` flag when running
`linkerd inject` to configure resources to bypass the proxy entirely when
sending to those ports. (Similarly, the `--skip-inbound-ports` flag will
configure the resource to bypass the proxy for incoming connections to those
ports.)

Skipping the proxy can be useful for these situations, as well as for
diagnosing issues, but otherwise should rarely be necessary.

As with opaque ports, multiple skipports can be provided as a comma-delimited
string.
