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

In some cases, Linkerd's protocol detection requires configuration to avoid a
10-second connection delay. This configuration is typically required when using
certain "server-speaks-first" protocols, or protocols where the server sends
data before the client does, to communicate with off-cluster services.

{{< note >}}
Regardless of the underlying protocol, client-initiated TLS connection do not
require any additional configuration, as TLS itself is a client-speaks-first
protocol.
{{< /note >}}

There are two basic mechanisms for configuring protocol detection: _opaque
ports_ and _skip ports_. Marking a port as _opaque_ instructs Linkerd to skip
protocol detection and proxy the connection as a TCP stream. Marking a port as
_skip_  bypasses the proxy entirely. Opaque ports are generally preferred (as
it allows Linkerd to provide mTLS, TCP-level metrics, etc), but crucially,
opaque ports can only be used for services on the cluster.

The following table summarizes some common protocols and the configuration
necessary to handle them. The "on-cluster config" column refers to the
configuration when the destination is *on* the same cluster; the "off-cluster
config" to when the destination is external to the cluster.

| Protocol | Default port(s) | On-cluster config | Off-cluster config|
|----------|-----------------|---------------------------|----------------------------|
| SMTP | 25, 587 | none\* | skip ports |
| MySQL | 3306 | none\* | skip ports | 
| PostgreSQL | 5432 | none\* | skip ports | 
| Memcache | 11211 | none\* | skip ports | 
| ElasticSearch | 9300 | opaque ports | skip ports |

_\* No configuration is required if the standard port is used. If a non-standard port
is used, you must mark the port as opaque._

## Marking a port as opaque

The `config.linkerd.io/opaque-ports` annotation tells Linkerd to skip protocol
detection for a specific set of ports, and immediately treat connections on
those ports as TCP. This is useful for bypassing protocol detection while still
proxying the connection.

The opaque-ports annotation can be set on the Pod template spec of a workload
or on a Service resource. Setting it on a Service resource tells meshed clients
to skip protocol detection when proxying connections to the Service; setting it
annotation on a Pod template spec tells meshed clients to skip protocol
detection for connections established directly to that Pod, and tells Linkerd
to skip protocol detection when reverse-proxying incoming connections.

{{< note >}}
Since this annotation informs the behavior of meshed _clients_, it can be
applied to Services that use server-speaks-first protocols even if the Service
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

## Skipping the proxy

Sometimes it is necessary to bypass the proxy altogether. For example, when
connecting to a server-speaks-first destination that is outside of the cluster,
there is no Service resource on which to set the
`config.linkerd.io/opaque-ports` annotation.

In this case, you can use the `--skip-outbound-ports` flag when running
`linkerd inject` to configure the Pod to bypass the proxy entirely when sending
to those ports. (Similarly, the `--skip-inbound-ports` flag will configure the
Pod to bypass the proxy for incoming connections to those ports.)

Skipping the proxy can be useful for these situations, as well as for
diagnosing issues, but otherwise should rarely be necessary.
