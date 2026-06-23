---
title: Protocol Detection Errors
description:
  Protocol detection errors indicate that Linkerd doesn't understand the
  protocol in use.
---

Linkerd is capable of proxying all TCP traffic, including TLS connections,
WebSockets, and HTTP tunneling. In most cases where the client speaks first when
a new connection is made, Linkerd can detect the protocol in use, allowing it to
perform per-request routing and metrics.

If your proxy logs contain messages like
`protocol detection timed out after 10s`, or you're experiencing 10-second
delays when establishing connections, you're probably running a situation where
Linkerd cannot detect the protocol. This is most common for protocols where the
server speaks first, and the client is waiting for information from the server.
It may also occur with non-HTTP protocols for which Linkerd doesn't yet
understand the wire format of a request.

You'll need to understand exactly what the situation is to fix this:

- A server-speaks-first protocol will probably need to be configured as a `skip`
  or `opaque` port, as described in the
  [protocol detection documentation](../features/protocol-detection/#configuring-protocol-detection).

- If you're seeing transient protocol detection timeouts, this is more likely to
  indicate a misbehaving workload.

- If you know the protocol is client-speaks-first but you're getting consistent
  protocol detection timeouts, you'll probably need to fall back on a `skip` or
  `opaque` port.

Note that marking ports as `skip` or `opaque` has ramifications beyond protocol
detection timeouts; see the
[protocol detection documentation](../features/protocol-detection/#configuring-protocol-detection)
for more information.
