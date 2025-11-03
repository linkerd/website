---
title: Network Policy
description: NetworkPolicy must not block the Linkerd inbound port.
---

Communication between two meshed pods will always have its original target port
replaced with the proxy's inbound port (by default, `4143`). Once the inbound
proxy receives the traffic, it will transparently forward it to the main
application container on the original port.

However, this means that any `NetworkPolicy` which blocks the Linkerd inbound
port (`4143`) will block all meshed traffic. For compatibility with Linkerd,
please ensure that any `NetworkPolicy` allows traffic to this port.
