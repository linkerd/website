---
title: TCP Proxying and Protocol Detection
description: Linkerd is capable of proxying all TCP traffic, including TLS'd connections,
  WebSockets, and HTTP tunneling.
weight: 2
---

Linkerd is capable of proxying all TCP traffic, including TLS connections,
WebSockets, and HTTP tunneling.

In most cases, Linkerd can do this without configuration. To accomplish this,
Linkerd performs *protocol detection* to determine whether traffic is HTTP or
HTTP/2 (including gRPC). If Linkerd detects that a connection is HTTP or
HTTP/2, Linkerd automatically provides HTTP-level metrics and routing.

If Linkerd *cannot* determine that a connection is using HTTP or HTTP/2,
Linkerd will proxy the connection as a plain TCP connection, applying
[mTLS](../automatic-mtls/) and providing byte-level metrics as usual.

(Note that HTTPS calls to or from meshed pods are treated as TCP, not as HTTP.
Because the client initiates the TLS connection, Linkerd is not be able to
decrypt the connection to observe the HTTP transactions.)

## Configuring protocol detection

{{< note >}}
If your proxy logs contain messages like `protocol detection timed out
after 10s`, or you are experiencing 10-second delays when establishing
connections, you are likely running into a protocol detection timeout.
This section will help you understand how to fix this.
{{< /note >}}

In some cases, Linkerd's protocol detection will time out because it doesn't see
any bytes from the client. This situation is commonly encountered when using
protocols where the server sends data before the client does (such as SMTP) or
protocols that proactively establish connections without sending data (such as
Memcache). In this case, the connection will proceed as a TCP connection after a
10-second protocol detection delay.

To avoid this delay, you will need to provide some configuration for Linkerd.
There are two basic mechanisms for configuring protocol detection: _opaque
ports_ and _skip ports_:

* Opaque ports instruct Linkerd to skip protocol detection and proxy the
  connection as a TCP stream
* Skip ports bypass the proxy entirely.

Opaque ports are generally preferred as they allow Linkerd to provide mTLS,
TCP-level metrics, policy, etc. Skip ports circumvent Linkerd's ability to
provide security features.

Linkerd maintains a default list of opaque ports that corresponds to the
standard ports used by protocols that interact poorly with protocol detection.
As of the 2.12 release, that list is: **25** (SMTP), **587** (SMTP), **3306**
(MySQL), **4444** (Galera), **5432** (Postgres), **6379** (Redis), **9300**
(ElasticSearch), and **11211** (Memcache).

## Protocols that may require configuration

The following table contains common protocols that may require additional
configuration.

| Protocol        | Standard port(s) | In default list? | Notes |
|-----------------|------------------|------------------|-------|
| SMTP            | 25, 587          | Yes              |       |
| MySQL           | 3306             | Yes              |       |
| MySQL with Galera | 3306, 4444, 4567, 4568 | Partially | Ports 4567 and 4568 are not in Linkerd's default set of opaque ports  |
| PostgreSQL      | 5432             | Yes              |       |
| Redis           | 6379             | Yes              |       |
| ElasticSearch   | 9300             | Yes              |       |
| Memcache        | 11211            | Yes              |       |

If you are using one of those protocols, follow this decision tree to determine
which configuration you need to apply.

![Decision tree](/docs/images/protocol-detection-decision-tree.png)

## Marking ports as opaque

You can use the `config.linkerd.io/opaque-ports` annotation to mark a port as
opaque. Note that this annotation should be set on the _destination_, not on the
source, of the traffic.

This annotation can be set in a variety of ways:

1. On the workload itself, e.g. on the Deployment's Pod spec receiving the traffic.
1. On the Service receiving the traffic.
1. On a namespace (in which it will apply to all workloads in the namespace).
1. In an [authorization policy](../server-policy/) `Server` object's
   `proxyProtocol` field, in which case it will apply to all pods targeted by that
   `Server`.

When set, Linkerd will skip protocol detection both on the client side and on
the server side. Note that since this annotation informs the behavior of meshed
_clients_, it can be applied to unmeshed workloads as well as meshed ones.

{{< note >}}
Multiple ports can be provided as a comma-delimited string. The values you
provide will _replace_, not augment, the default list of opaque ports.
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

{{< note >}}
There was a bug in Linkerd 2.11.0 and 2.11.1 that prevented the opaque ports
behavior of `enable-external-profiles` from working. This was fixed in Linkerd
2.11.2.
{{< /note >}}

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
