+++
date = "2018-07-31T12:00:00-07:00"
title = "HTTP, HTTP/2, and gRPC Proxying"
description = "Linkerd will automatically enable advanced features (including metrics, load balancing, retries, and more) for HTTP, HTTP/2, and gRPC connections."
weight = 1
+++

Linkerd can proxy all TCP connections, and will automatically enable advanced
features (including metrics, load balancing, retries, and more) for HTTP,
HTTP/2, and gRPC connections. (See
[TCP Proxying and Protocol Detection](../protocol-detection/) for details of how
this detection happens).

## Notes

* gRPC applications that use grpc-go must use grpc-go version 1.3 or later due
  to a [bug](https://github.com/grpc/grpc-go/issues/1120) in earlier versions.
