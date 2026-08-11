---
date: 2026-08-12T00:00:00Z
title: |-
  gRPC Gotchas
description: |-
  Be careful with protocol declaration!
keywords: [linkerd, grpc, appprotocol, kubernetes, "protocol declaration"]
params:
  author: flynn
  showCover: true
images: [social.jpg] # Open graph image
---

The other day I ran the Gateway API conformance tests against Linkerd. This is normally a pretty routine chore, but this time, a gRPC routing test failed. This was _extremely_ startling, since Linkerd has supported gRPC routing for about two years now (it first showed up in Linkerd 2.16). Even more confusingly, the specific failure was around routing with weights, and I had used exactly that feature a few days before.

## gRPC

[gRPC's website](https://grpc.io) defines it as "a modern open source high performance Remote Procedure Call (RPC) framework". RPC is basically the same idea as a function call, just across machines[^1]: you have a named bit of executable code that takes some inputs and returns some data, and you have a defined way to encode those inputs and outputs that preserves type[^2].

[^1]: I know it says "procedure", but I stand by describing it as a function call. Practical RPC dates back to the 1980s; "procedure" is the name used in some older languages where we use "function" today.

[^2]: gRPC uses [Protocol Buffers](https://protobuf.dev) for this.

Over the wire, gRPC is layered over HTTP/2, so every gRPC call is an HTTP/2 stream with `HEADERS` frames carrying metadata, `DATA` frames carrying the inputs and outputs, and trailers (`HEADERS` frames after all the `DATA` frames) carrying the final status of the gRPC call.

![gPRC is layered within HTTP/2](<grpc-diagram.png>)

This layering means that, at the most basic level, you can route a gRPC request by routing its HTTP/2 stream -- even as far as routing based on which specific gRPC call you're trying to make (which is encoded in the HTTP/2 `PATH`) or routing on custom gRPC metadata (which appears as HTTP/2 headers). Valid gRPC calls are always HTTP `POST` requests with `Content-Type: application/grpc`, but that doesn't change anything about routing.

On the other hand, metrics and reliability mechanisms (like canaries or retries) are not the same for gRPC as for HTTP/2, because - crucially - every gRPC call returns an HTTP status of 200 _even if the RPC fails_. To understand the real result of a gRPC call, you _must_ look into the trailers to get the gRPC status. If you don't do that, you'll just see the HTTP 200 and believe that you're seeing a 100% success rate.

So - and this is the first piece of the test-failure puzzle - to do anything significant with gRPC, you have to know you're dealing with gRPC, which means that you have to start by knowing you're dealing with HTTP/2.

## Protocol Detection

This need to know the details of the connection isn't only a gRPC thing, of course. In general, anything more subtle than just passing bytes back and forth with no analysis requires you to know what the protocol is. This includes not just golden metrics and reliability, but even basic features like per-request routing -- after all, you can't route a single request if you don't know where the request starts and ends in the data stream.

There are fundamentally only two ways to know what protocol is in play: you can to look at the bytes in transit and figure out what protocol it is (_protocol detection_), or you can be told up front what protocol it is (_protocol declaration_). We've [written about this] before in the context of Linkerd: protocol detection is far friendlier than forcing the user to declare everything up front, so Linkerd leans heavily on protocol detection.

[written about this]: https://www.buoyant.io/blog/announcing-linkerd-2-18

However, protocol detection requires traffic, and because you can't even know which replica should get traffic before you figure out the protocol, it requires traffic from the _client_. Without any data, protocol detection will wait 10 seconds, then give up. This most commonly happens for protocols like SMTP where it's the server than speaks first, but it can also happen when things are overloaded: on a really heavily loaded cluster, it's possible for a client to not ever get enough CPU to send its first bytes until after protocol detection has timed out.

### When Protocol Detection Goes Bad

Here's the second piece of the test-failure puzzle: when protocol detection fails, it's not just a 10-second delay. Linkerd will also treat the connection as _opaque_: we do mTLS, but otherwise we just pass bytes back and forth with no visibility into the connection at all.

"No visibility into the connection" is _very_ broad. No per-request routing, since we can't know what constitutes a request. No metrics, since we can't see whether a request succeeds or fails. No retries, no canaries, no circuit breaking, and - arguably the most serious problem - no authorization policy.

Preventing this situation no matter what kind of shape the cluster is in is why protocol declaration exists.

## Protocol Declaration

Protocol declaration works based on the (optional) `appProtocol` attribute of a Service: setting `appProtocol` _completely disables_ protocol detection and just uses the protocol you declare. This is the third piece of the puzzle: protocol declaration is an override, and nothing else can overrule it (that's the point).

For the last piece of the puzzle, we have a look a little deeper into `appProtocol`. This field on Service became standard in Kubernetes 1.20 and [supports only certain values]: service names from the the [IANA Service Name and Transport Protocol Port Number Registry], and custom names of the form `domain/protocol`, including the three values defined by Kubernetes itself:

- `kubernetes.io/h2c`: HTTP/2 over cleartext as described in [RFC 9113];
- `kubernetes.io/ws`: WebSocket over cleartext as described in [RFC 6455]; and
- `kubernetes.io/wss`: WebSocket over TLS as described in [RFC 6455].

[supports only certain values]: https://kubernetes.io/docs/concepts/services-networking/service/#application-protocol
[IANA Service Name and Transport Protocol Port Number Registry]: https://www.iana.org/assignments/service-names-port-numbers
[RFC 9113]: https://www.rfc-editor.org/info/rfc9113/
[RFC 6455]: https://www.rfc-editor.org/info/rfc6455/

Since gRPC is _not_ on this list, there is no standard way to use `appProtocol` to specifically declare gRPC.

This is normally less problematic than it might seem, because gRPC doesn't _change_ HTTP/2, it is _encapsulated in_ HTTP/2. Knowing that the protocol is HTTP/2 (which is still true for gRPC) is enough for Linkerd to know how to interpret individual requests, including looking into the headers to see if `Content-Type: application/grpc` shows up. If so, great, this is a gRPC call! and we can interpret the trailers to get the gRPC status.

This means that - though it may sound odd - you can use `appProtocol: kubernetes/h2c` to do the right thing here: that'll force Linkerd to trust that the wire protocol is HTTP/2, and it can see from the `Content-Type` that it needs to interpret trailers to get the gRPC status.

What you _can't_ use is `appProtocol: grpc`.

### When `appProtocol` Goes Bad

Linkerd is very strict about accepting only the standard `appProtocol` values. This is the fourth and final piece of the test-failure puzzle: any invalid value for `appProtocol` means that Linkerd assumes the connection is `opaque`. This may seem a bit draconian, but it's the only safe way to go: _any_ interpretation we choose for a nonstandard value opens us up to breaking changes if the nonstandard value later becomes standardized.

Of course, we could define `linkerd.io/grpc` to mean "use the cleartext HTTP/2 wire protocol and interpret trailers for gRPC statuses"; that would be safe. (Oddly, `kubernetes.io/grpc` seems unlikely: [KEP 3726] originally attempted to include it, but couldn't get consensus over whether it should mean cleartext gRPC or gRPC using TLS.)

[KEP 3726]: https://github.com/kubernetes/enhancements/blob/master/keps/sig-network/3726-standard-application-protocols/README.md

## Putting the Puzzle Together

To recap: for gRPC to work correctly, service meshes (including Linkerd!) need to know that a connection is using HTTP/2, so that they can figure out to interpret HTTP/2 trailers to understand gRPC status. They can detect HTTP/2, or they can have it declared. For Linkerd, a protocol declaration is an absolute override, and Linkerd also won't guess if it sees a nonstandard `appProtocol`.

The test failure I saw? It had been changed to include `appProtocol: grpc` since the last time I'd tried to run. Since that's a nonstandard value, it caused Linkerd to switch to `opaque`, which shut off _all_ gRPC processing, including the weighted per-request routing that the test required.

The moral here is twofold: first, **pay attention to the standards**, especially if you're writing tests meant to validate behavior across implementations -- it's really easy to create pretty subtle bugs otherwise. Second, if you're the one looking at the bug, just remember that blaming the test is always easy and very often wrong -- make sure you really understand what's happening before claiming that the test is at fault. Ultimately, getting this one fixed was easy once it was understood.



