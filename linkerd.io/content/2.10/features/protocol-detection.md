---
title: TCP Proxying and Protocol Detection
description:
  Linkerd is capable of proxying all TCP traffic, including TLS'd connections,
  WebSockets, and HTTP tunneling.
weight: 2
---

Linkerd is capable of proxying all TCP traffic, including TLS connections,
WebSockets, and HTTP tunneling.

In most cases, Linkerd can do this without configuration. To accomplish this,
Linkerd performs _protocol detection_ to determine whether traffic is HTTP or
HTTP/2 (including gRPC). If Linkerd detects that a connection is HTTP or HTTP/2,
Linkerd automatically provides HTTP-level metrics and routing.

If Linkerd _cannot_ determine that a connection is using HTTP or HTTP/2, Linkerd
will proxy the connection as a plain TCP connection, applying
[mTLS](automatic-mtls/) and providing byte-level metrics as usual.

(Note that HTTPS calls to or from meshed pods are treated as TCP, not as HTTP.
Because the client initiates the TLS connection, Linkerd is not be able to
decrypt the connection to observe the HTTP transactions.)

## Configuring protocol detection

{{< note >}}

If you are experiencing 10-second delays when establishing connections, you are
likely running into a protocol detection timeout. This section will help you
understand how to fix this.

{{< /note >}}

In some cases, Linkerd's protocol detection will time out because it doesn't see
any bytes from the client. This situation is commonly encountered when using
"server-speaks-first" protocols where the server sends data before the client
does, such as SMTP, or protocols that proactively establish connections without
sending data, such as Memcache. In this case, the connection will proceed as a
TCP connection after a 10-second protocol detection delay.

To avoid this delay, you will need to provide some configuration for Linkerd.
There are two basic mechanisms for configuring protocol detection: _opaque
ports_ and _skip ports_. Marking a port as _opaque_ instructs Linkerd to skip
protocol detection and immediately proxy the connection as a TCP stream; marking
a port as a _skip port_ bypasses the proxy entirely. Opaque ports are generally
preferred (as Linkerd can provide mTLS, TCP-level metrics, etc), but can only be
used for services inside the cluster.

By default, Linkerd automatically marks the ports for some server-speaks-first
protocol as opaque. Services that speak those protocols over the default ports
to destinations inside the cluster do not need further configuration. Linkerd's
default list of opaque ports in the 2.10 release is 25 (SMTP), 443
(client-initiated TLS), 587 (SMTP), 3306 (MySQL), 5432 (Postgres), and 11211
(Memcache). Note that this may change in future releases.

The following table contains common protocols that may require configuration.

| Protocol          | Default port(s)        | Notes                                                                       |
| ----------------- | ---------------------- | --------------------------------------------------------------------------- |
| SMTP              | 25, 587                |                                                                             |
| MySQL             | 3306                   |                                                                             |
| MySQL with Galera | 3306, 4444, 4567, 4568 | Ports 4444, 4567, and 4568 are not in Linkerd's default set of opaque ports |
| PostgreSQL        | 5432                   |                                                                             |
| Redis             | 6379                   |                                                                             |
| ElasticSearch     | 9300                   | Not in Linkerd's default set of opaque ports                                |
| Memcache          | 11211                  |                                                                             |

If you are using one of those protocols, follow this decision tree to determine
which configuration you need to apply.

- Is the protocol wrapped in TLS?
  - Yes: no configuration required.
  - No: is the destination on the cluster?
    - Yes: is the port in Linkerd's default list of opaque ports?
      - Yes: no configuration required.
      - No: mark port(s) as opaque.
    - No: mark port(s) as skip.

## Marking a port as opaque

You can use the `config.linkerd.io/opaque-ports` annotation to mark a port as
opaque. This instructions Linkerd to skip protocol detection for that port.

This annotation can be set on a workload, service, or namespace. Setting it on a
workload tells meshed clients of that workload to skip protocol detection for
connections established to the workload, and tells Linkerd to skip protocol
detection when reverse-proxying incoming connections. Setting it on a service
tells meshed clients to skip protocol detection when proxying connections to the
service. Set it on a namespace applies this behavior to all services and
workloads in that namespace.

{{< note >}}

Since this annotation informs the behavior of meshed _clients_, it can be
applied to unmeshed services as well as meshed services.

{{< /note >}}

Setting the opaque-ports annotation can be done by using the `--opaque-ports`
flag when running `linkerd inject`. For example, for a MySQL database running on
the cluster using a non-standard port 4406, you can use the commands:

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

## Marking a port as skip

Sometimes it is necessary to bypass the proxy altogether. For example, when
connecting to a server-speaks-first destination that is outside of the cluster,
there is no Service resource on which to set the
`config.linkerd.io/opaque-ports` annotation.

In this case, you can use the `--skip-outbound-ports` flag when running
`linkerd inject` to configure resources to bypass the proxy entirely when
sending to those ports. (Similarly, the `--skip-inbound-ports` flag will
configure the resource to bypass the proxy for incoming connections to those
ports.)

Skipping the proxy can be useful for these situations, as well as for diagnosing
issues, but otherwise should rarely be necessary.

As with opaque ports, multiple skipports can be provided as a comma-delimited
string.

## Using `NetworkPolicy` resources with opaque ports

When a service has a port marked as opaque, any `NetworkPolicy` resources that
apply to the respective port and restrict ingress access will have to be changed
to target the proxy's inbound port instead (by default, `4143`). If the service
has a mix of opaque and non-opaque ports, then the `NetworkPolicy` should target
both the non-opaque ports, and the proxy's inbound port.

A connection that targets an opaque endpoint (i.e a pod with a port marked as
opaque) will have its original target port replaced with the proxy's inbound
port. Once the inbound proxy receives the traffic, it will transparently forward
it to the main application container over a TCP connection.
