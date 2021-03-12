+++
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

* gRPC applications that use [grpc-go][grpc-go] must use version 1.3 or later due
  to a [bug](https://github.com/grpc/grpc-go/issues/1120) in earlier versions.
* gRPC applications that use [@grpc/grpc-js][grpc-js] must use version 1.1.0 or later
  due to a [bug](https://github.com/grpc/grpc-node/issues/1475) in earlier versions.

[grpc-go]: https://github.com/grpc/grpc-go
[grpc-js]: https://github.com/grpc/grpc-node/tree/master/packages/grpc-js
