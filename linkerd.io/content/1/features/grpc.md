+++
aliases = ["/features/grpc"]
description = "Linkerd supports both HTTP/2 and TLS, allowing it to route gRPC requests, enabling advanced RPC mechanisms such as bidirectional streaming, flow control, and structured data payloads."
title = "gRPC"
weight = 8
[menu.docs]
parent = "features"
weight = 14

+++
Linkerd supports configuring gRPC clients and servers, which can be used to
introduce gRPC easily into your application. Using Linkerd to route gRPC
requests enables resilient distributed communication, as well as support for
structured data, bidirectional streaming, flow control, and robust,
cross-platform client libraries provided by gRPC and Protocol Buffers.

## Transport

The underlying transport used for gRPC is HTTP/2. Linkerd supports [configuring
HTTP/2 enabled routers]({{% linkerdconfig "http-2-protocol" %}}), which can also
be used to route gRPC requests. When gRPC clients send a request, they include
routing information in HTTP/2's `:path` pseudo-header. The path for a gRPC
request is prefixed with `/serviceName/methodName` segments, and Linkerd can be
configured to read the value of that header and route requests accordingly,
using the [Header Path Identifier]({{% linkerdconfig "header-path-identifier"
%}}). For more information on how Linkerd routes requests, see the [Routing](
{{% ref "/1/features/routing.md" %}}) feature page.

## Authentication

Most gRPC language implementations require using TLS, and Linkerd supports
configuring gRPC clients and servers with TLS, although it is not strictly
required. For more information about setting up TLS, see the [TLS]({{% ref
"/1/features/tls.md" %}}) feature page.

## More information

If you'd like to learn more about routing gRPC requests with Linkerd, check out
Buoyant's blog post on the topic:
[HTTP/2, gRPC and Linkerd](https://blog.buoyant.io/2017/01/10/http2-grpc-and-linkerd/),
which provides a thorough introduction.
