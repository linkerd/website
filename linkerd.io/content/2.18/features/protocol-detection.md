---
title: TCP Proxying and Protocol Detection
description: Linkerd is capable of proxying all TCP traffic, including TLS'd connections,
  WebSockets, and HTTP tunneling.
weight: 2
---

Linkerd is capable of proxying all TCP traffic, including TLS connections,
WebSockets, and HTTP tunneling.

In most cases, Linkerd can do this without configuration. To accomplish this,
Linkerd performs *protocol detection* to determine whether traffic is HTTP
(including HTTP/2 and gRPC). If Linkerd detects that a connection is HTTP, it
will automatically provide HTTP-level metrics and routing. If Linkerd *cannot*
determine that a connection is using HTTP, Linkerd will proxy the connection as
a plain TCP connection without HTTP metrics and routing. (In both cases,
non-HTTP features such as [mutual TLS](../automatic-mtls/) and byte-level
metrics are still applied.)

Protocol detection can only happen if the HTTP traffic is unencrypted from the
client. If the application itself initiates a TLS call, Linkerd will not be able
to decrypt the connection, and will treat it as an opaque TCP connection.

## Configuring protocol detection

{{< note >}}
If your proxy logs contain messages like `protocol detection timed out
after 10s`, or you are experiencing 10-second delays when establishing
connections, you are likely running into a protocol detection timeout.
This section will help you understand how to fix this.
{{< /note >}}

To do protocol detection, Linkerd waits for up to 10 seconds to see bytes sent
from the client. Note that until the protocol has been determined, Linkerd
cannot even establish a connection to the destination, since HTTP routing
configuration may inform where this connection is established to.

If Linkerd does not see enough data from the client within 10 seconds from
connection establishment to determine the protocol, Linkerd will treat the
connection as an opaque TCP connection and will proceed as normal, establishing
the connection to the destination and proxying the data. However, since Linkerd
was not able to detect the connection as HTTP, it will treat the connection as
TCP. This means that any policy configured via HTTPRoutes will not be applied
and can lead to unexpected routing or authorization behavior.

In practice, protocol detection timeouts typically happen when the application
is using a protocol where the server sends data before the client does (such as
SMTP) or a protocol that proactively establishes connections without sending data
(such as Memcache). They can also occur when an application opens connections
but does not send data on them due to CPU contention or connection pooling.

To avoid this delay and ensure Linkerd uses the correct protocol, you can
provide some configuration for Linkerd.

## Protocols that may require configuration

The following table contains common protocols that may require additional
configuration.

| Protocol        | Standard ports   | In default list? | Notes |
|-----------------|------------------|------------------|-------|
| SMTP            | 25, 587          | Yes              |       |
| MySQL           | 3306             | Yes              |       |
| MySQL with Galera | 3306, 4444, 4567, 4568 | Partially | Ports 4567 and 4568 are not in Linkerd's default list of opaque ports  |
| PostgreSQL      | 5432             | Yes              |       |
| Redis           | 6379             | Yes              |       |
| ElasticSearch   | 9300             | Yes              |       |
| Memcache        | 11211            | Yes              |       |
| NATS            | 4222, 6222, 8222 | No               |       |

If you are using one of those protocols, follow this decision tree to determine
which configuration you need to apply.

## Declaring a Service port's protocol

When you're getting started with Linkerd, automatic protocol detection works in
the majority of cases, but it runs the risk that if a connection ever takes more
than 10 seconds to send enough data, it might not detect the protocol. This
could happen in situations where the cluster is overloaded, the proxy is
resource constrained, the app is resource constrained, etc.

To eliminate this risk, you can set the `appProtocol` field on the ports in a
Service to determine what protocol to use when communicating with that Service port,
and skip automatic protocol detection entirely.

| `appProtocol`     | Protocol   | Notes |
|-------------------|------------|-------|
| linkerd.io/opaque | opaque     |       |
| linkerd.io/tcp    | opaque     | This is an alias of `linkerd.io/opaque`. It is treated exactly the same. |
| http              | HTTP/1     | The source proxy may upgrade the connection to the destination proxy to HTTP/2, though the destination workload will still see HTTP/1 |
| kubernetes.io/h2c | HTTP/2     |       |

If `appProtocol` is set to any other value, Linkerd will treat the connection as
opaque TCP. If `appProtocol` is unset, Linkerd will continue to do automatic
protocol detection.

## Opaque Ports Annotation

There are a few cases where it is not possible to mark a port as opaque using
the `appProtocol` field. In the following cases you must use the
`config.linkerd.io/opaque-ports` annotation instead to mark a port or list of
ports as opaque:

{{< note >}}
Multiple ports can be provided as a comma-delimited string. The values you
provide will *replace*, not augment, the default list of opaque ports.
{{< /note >}}

### Pods that receive traffic from unmeshed clients

Since an unmeshed client will not have a Linkerd proxy, it will not read the
`appProtocol` field of a Service. Therefore, if a pod receives traffic from an
unmeshed client then you must set the `config.linkerd.io/opaque-ports`
annotation on the pod receiving the traffic to skip protocol detection.
This instructs Linkerd to treat those connections as opaque TCP.

### Headless Services

Similarly, if clients connect to a pod using a headless service or connect to
the pod directly without using a service at all, the `appProtocol` field will
be applicable. In this case you must set the `config.linkerd.io/opaque-ports`
annotation on the pod receiving the traffic to skip protocol detection.
This instructs Linkerd to treat those connections as opaque TCP.

### Egress

When connecting to a destination outside of the cluster, Linkerd will look for
a matching `EgressNetwork` resource. To skip protocol detection and mark this
connection as opaque TCP, you must set the `config.linkerd.io/opaque-ports`
annotation on the matching `EgressNetwork` resource. For more information,
see [managing egress traffic](../../tasks/managing-egress-traffic/).

## Marking ports as skip ports

Sometimes it is necessary to bypass the proxy altogether. In this case, you can
use the `config.linkerd.io/skip-outbound-ports` annotation to bypass the proxy
entirely when sending to those ports. (Note that there is a related annotation,
`skip-inbound-ports`, to bypass the proxy for incoming connections. This is
typically only needed for debugging purposes.)

As with opaque ports, multiple skip-ports can be provided as a comma-delimited
string.

This annotation should be set on the source of the traffic.
