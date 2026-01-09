---
title: HTTP, HTTP/2, and gRPC Proxying
description:
  Linkerd will automatically enable advanced features (including metrics, load
  balancing, retries, and more) for HTTP, HTTP/2, and gRPC connections.
weight: 1
---

Linkerd can proxy all TCP connections. For HTTP connections (including HTTP/1.0,
HTTP/1.1, HTTP/2, and gRPC connections), it will automatically enable advanced
L7 features including [request-level metrics](telemetry/),
[latency-aware load balancing](load-balancing/),
[retries](retries-and-timeouts/), and more.

(See [TCP Proxying and Protocol Detection](protocol-detection/) for details of
how this detection happens automatically, and how it can sometimes fail.)

Note that while Linkerd does [zero-config mutual TLS](automatic-mtls/), it
cannot decrypt TLS connections initiated by the outside world. For example, if
you have a TLS connection from outside the cluster, or if your application does
HTTP/2 plus TLS, Linkerd will treat these connections as raw TCP streams. To
take advantage of Linkerd's full array of L7 features, communication between
meshed pods must be TLS'd by Linkerd, not by the application itself.
