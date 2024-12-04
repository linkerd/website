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
the connection to the destination and proxying the data.

In practice, protocol detection timeouts typically happen when the application
is using a protocol where the server sends data before the client does (such as
SMTP) or a protocol that proactively establishes connections without sending data
(such as Memcache). In this case, everything will work, but Linkerd will
introduce an unnecessary 10 second delay before connection establishment.

To avoid this delay, you can provide some configuration for Linkerd. There are
two basic mechanisms for configuring protocol detection: _opaque ports_ and
_skip ports_:

* Opaque ports instruct Linkerd to skip protocol detection and proxy the
  connection as a TCP stream.
* Skip ports bypass the proxy entirely.

Opaque ports are generally preferred as they only skip protocol detection,
without interfering with Linkerd's ability to provide mTLS, TCP-level metrics,
policy, etc. Skip ports, by contrast, create networking rules that avoid the
proxy entirely, circumventing Linkerd's ability to provide security features.

Linkerd maintains a default list of opaque ports that corresponds to the
standard ports used by protocols that interact poorly with protocol detection.

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

![Decision tree](/docs/images/protocol-detection-decision-tree.png)

## Marking ports as opaque

You can use the `config.linkerd.io/opaque-ports` annotation to mark a port as
opaque. Linkerd will skip protocol detection on opaque ports, and treat
connections to them as TCP streams.

This annotation should be set on the _destination_, not on the source, of the
traffic. This is true even if the destination is unmeshed, as it controls the
behavior of meshed clients.

This annotation *must* be set in two places:

1. On the Service receiving the traffic.
2. On the workload itself (e.g. on the Deployment's Pod spec receiving the
traffic), or on enclosing namespace, in which it will apply to all workloads in
the namespace.

{{< note >}}
Multiple ports can be provided as a comma-delimited string. The values you
provide will _replace_, not augment, the default list of opaque ports.
{{< /note >}}

{{< note >}}
If you are using [authorization policies](../server-policy/), the `Server`'s
`proxyProtocol` field which can be used to control protocol detection behavior
and can be used instead of a Service annotation. Regardless, we suggest
annotating the Service object for clarity.
{{< /note >}}

## Marking ports as skip ports

Sometimes it is necessary to bypass the proxy altogether. In this case, you can
use the `config.linkerd.io/skip-outbound-ports` annotation to bypass the proxy
entirely when sending to those ports. (Note that there is a related annotation,
`skip-inbound-ports`, to bypass the proxy for incoming connections. This is
typically only needed for debugging purposes.)

As with opaque ports, multiple skip-ports can be provided as a comma-delimited
string.

This annotation should be set on the source of the traffic.

## Setting the enable-external-profiles annotation

The `config.linkerd.io/enable-external-profiles` annotation configures Linkerd
to look for [`ServiceProfiles`](../service-profiles/) for off-cluster
connections. It *also* instructs Linkerd to respect the default set of opaque
ports for this connection.

This annotation should be set on the source of the traffic.

Note that the default set of opaque ports can be configured at install
time, e.g. by using `--set proxy.opaquePorts`. This may be helpful in
conjunction with `enable-external-profiles`.

## Using `NetworkPolicy` resources with opaque ports

When a service has a port marked as opaque, any `NetworkPolicy` resources that
apply to the respective port and restrict ingress access will have to be
changed to target the proxy's inbound port instead (by default, `4143`). If the
service has a mix of opaque and non-opaque ports, then the `NetworkPolicy`
should target both the non-opaque ports, and the proxy's inbound port.

A connection that targets an opaque endpoint (i.e a pod with a port marked as
opaque) will have its original target port replaced with the proxy's inbound
port. Once the inbound proxy receives the traffic, it will transparently
forward it to the main application container over a TCP connection.
