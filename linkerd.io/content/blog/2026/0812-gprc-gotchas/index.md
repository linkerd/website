---
date: 2026-08-12T00:00:00Z
title: |-
  gRPC Got Us -- Or Did It?
description: |-
  Be careful with protocol declaration!
keywords: [linkerd, grpc, appprotocol, kubernetes, "protocol declaration"]
params:
  author: flynn
  showCover: true
images: [social.jpg] # Open graph image
---

The other day I ran the Gateway API conformance tests against Linkerd. This is normally a pretty routine chore, but this time, a gRPC routing test failed. This was _extremely_ startling, since Linkerd has supported gRPC routing for about two years now (full GRPCRoute support shipped in [Linkerd 2.16]). Even more confusingly, the specific failure was around routing with weights, and I had used exactly that feature a few days before.

[Linkerd 2.16]: https://linkerd.io/2024/08/13/announcing-linkerd-2.16/

This sort of thing can happen for a lot of different reasons. Maybe someone snuck in a change in Linkerd; maybe there's a bug in the test; maybe the test uses a configuration that's different from my usage. So which is it?

The easiest thing in the world is to just blame it on a bug in the test -- and that's almost never the right reflex. Figuring out what was going on in this case was quite the ride through a lot of different pieces of the ecosystem; it's well worth a more detailed look.

## Intro to gRPC

[gRPC's website](https://grpc.io) defines it as "a modern open source high performance Remote Procedure Call (RPC) framework". RPC is basically the same idea as a function call, just across machines[^1]: you have a named bit of executable code that takes some inputs and returns some data, and you have a defined way to encode those inputs and outputs that preserves type[^2].

[^1]: I know it says "procedure", but I stand by describing it as a function call. Practical RPC implementations date back to the 1980s, but RPC as a concept dates back to the 1960s, so its terminology was influenced by languages like [PL/I] and [ALGOL], which used "procedure" where pretty much all the common languages today (notably the entire C family) use "function". To me, a "procedure" never returns a value and a "function" does, but that's because I started out working in [Pascal] (seriously) before switching to C.

[PL/I]: https://en.wikipedia.org/wiki/PL/I
[ALGOL]: https://en.wikipedia.org/wiki/ALGOL
[Pascal]: https://en.wikipedia.org/wiki/Pascal_(programming_language)

[^2]: gRPC uses [Protocol Buffers](https://protobuf.dev) for this.

Over the wire, gRPC is layered within HTTP/2, so every gRPC call is an HTTP/2 stream with `HEADERS` frames carrying metadata, `DATA` frames carrying the inputs and outputs, and trailers (`HEADERS` frames after all the `DATA` frames) carrying the final status of the gRPC call. Valid gRPC calls are always HTTP `POST` requests with `Content-Type: application/grpc`.

![gPRC is layered within HTTP/2](<grpc-diagram.png>)

This layering means that, at the most basic level, you can route a gRPC request by routing its HTTP/2 stream -- even as far as routing based on which specific gRPC call you're trying to make (which is encoded in the HTTP/2 `PATH`) or routing on custom gRPC metadata (which appears in HTTP/2 headers).

On the other hand, metrics and reliability mechanisms (like [canaries] or [retries]) are not the same for gRPC as for HTTP/2, because - crucially - [every gRPC call returns an HTTP status of 200] _even if the RPC fails_. To understand the real result of a gRPC call, you _must_ look into the trailers to get the gRPC status. If you don't do that, you'll just see the HTTP 200 and believe that you're seeing a 100% success rate.

[canaries]: https://linkerd.io/docs/tasks/configuring-dynamic-request-routing/
[retries]: https://linkerd.io/docs/reference/retries/
[every gRPC call returns an HTTP status of 200]: https://grpc.github.io/grpc/core/md_doc__p_r_o_t_o_c_o_l-_h_t_t_p2.html

So - and this is the first piece of the test-failure puzzle - to do anything significant with gRPC, you have to know you're dealing with gRPC, which means that you have to start by knowing you're dealing with HTTP/2.

## Protocol Detection

This need to know the details of the connection isn't only a gRPC thing, of course. In general, anything more subtle than just passing bytes back and forth with no analysis requires you to know what the protocol is. This includes not just [golden metrics] and reliability, but even basic features like [per-request load balancing] -- after all, you can't choose endpoints for individual requests if you don't know where the requests start and end in the data stream.

[golden metrics]: https://linkerd.io/2-edge/features/telemetry/#golden-metrics
[per-request load balancing]: https://linkerd.io/docs/features/load-balancing/

There are fundamentally only two ways to know what protocol is in play: you can to look at the bytes in transit and figure out what protocol it is (_protocol detection_), or you can be told up front what protocol it is (_protocol declaration_). Linkerd takes the attitude that [detection is friendlier than declaration], so it leans heavily on protocol detection.

[detection is friendlier than declaration]: https://www.buoyant.io/blog/announcing-linkerd-2-18

However, protocol detection requires the client to send some data (think for a second about things like session affinity, where there's no way to know which replica should get the traffic before you hear from the client which session they're part of). Without any data, protocol detection will wait 10 seconds, then give up. This most commonly happens for protocols like SMTP where it's the server that speaks first, but it can also happen when things are overloaded: on a really heavily loaded cluster, it's possible for a client to not ever get enough CPU to send its first bytes until after protocol detection has timed out.

### When Protocol Detection Goes Bad

Here's the second piece of the test-failure puzzle: if protocol detection doesn't get the client data it needs, it doesn't just cause a 10-second delay. Linkerd will also treat the connection as _opaque_: we do mTLS, but otherwise we just pass bytes back and forth with no visibility into the connection at all.

"No visibility into the connection" is _very_ broad. No per-request routing, since we can't know what constitutes a request. No metrics, since we can't see whether a request succeeds or fails. No retries, no canaries, no circuit breaking, and - arguably the most serious problem - no authorization policy.

Preventing this situation no matter what kind of shape the cluster is in is why protocol declaration exists.

## Protocol Declaration

Protocol declaration works based on the (optional) `appProtocol` attribute of a Service: setting `appProtocol` _completely disables_ protocol detection and just uses the protocol you declare. This is the third piece of the puzzle: protocol declaration is an override, and nothing else can overrule it.

`appProtocol` on Service became standard in Kubernetes 1.20 and [supports only certain values]: service names from the the [IANA Service Name and Transport Protocol Port Number Registry], and custom names of the form `domain/protocol`, including the three values defined by Kubernetes itself:

- `kubernetes.io/h2c`: HTTP/2 over cleartext as described in [RFC 9113];
- `kubernetes.io/ws`: WebSocket over cleartext as described in [RFC 6455]; and
- `kubernetes.io/wss`: WebSocket over TLS as described in [RFC 6455].

[supports only certain values]: https://kubernetes.io/docs/concepts/services-networking/service/#application-protocol
[IANA Service Name and Transport Protocol Port Number Registry]: https://www.iana.org/assignments/service-names-port-numbers
[RFC 9113]: https://www.rfc-editor.org/info/rfc9113/
[RFC 6455]: https://www.rfc-editor.org/info/rfc6455/

Since gRPC is _not_ on this list, there is no standard way to use `appProtocol` to specifically declare gRPC.

This is normally less problematic than it might seem, because gRPC doesn't _change_ HTTP/2, it is _encapsulated in_ HTTP/2. Knowing that the protocol is HTTP/2 (which is still true for gRPC) is enough for Linkerd to know how to interpret individual requests, including looking into the headers to see if `Content-Type: application/grpc` shows up. If so, great, this is a gRPC call! and we can interpret the trailers to get the gRPC status.

In other words, setting `appProtocol: kubernetes/h2c` will work just fine for gRPC: Linkerd will trust that the wire protocol is HTTP/2, which will let it use the `Content-Type` to know when to interpret trailers to get the gRPC status.

What you _can't_ do is set `appProtocol: grpc`.

### When `appProtocol` Goes Bad

Linkerd is very strict about accepting only the standard `appProtocol` values. This is the fourth and final piece of the test-failure puzzle: any invalid value for `appProtocol` means that Linkerd assumes the connection is `opaque`. This may seem a bit draconian, but it's the only safe way to go: if we decide to interpret `appProtocol: grpc` to mean cleartext gRPC, what happens if the ecosystem later decides that it should mean gRPC using TLS?

This isn't just an academic concern, to be clear: [KEP 3726] originally attempted to define a `kubernetes.io/grpc` value, but dropped it because no consensus could be reached on whether it would mean cleartext or TLS. (Linkerd could define a `linkerd.io/grpc` and sidestep that confusion; to date, this hasn't seemed necessary, but if you think it is, let me know.)

[KEP 3726]: https://github.com/kubernetes/enhancements/blob/master/keps/sig-network/3726-standard-application-protocols/README.md

## Putting the Puzzle Together

To bring all these threads together: for gRPC to work correctly, service meshes (including Linkerd!) need to know that a connection is using HTTP/2, so that they can figure out to interpret HTTP/2 trailers to understand gRPC status. They can detect HTTP/2, or they can have it declared. For Linkerd, a protocol declaration is an absolute override, and Linkerd treats nonstandard `appProtocol` values as `opaque`.

And the test that failed had been changed to set `appProtocol: grpc` since the last time I'd tried to run it. That was the whole problem: since `grpc` is a nonstandard value, Linkerd switched to `opaque`, which shut off _all_ gRPC processing, including the weighted per-request routing that the test required. The failure isn't subtle at all, but understanding why it happened very much is.[^3]

[^3]: I ended up going all the way down to the `linkerd diagnostics policy` command to make absolutely **certain** that I knew what was happening before working on getting the test fixed. If you can't be that certain, it's probably too early to blame the test.

So if you're using protocol declaration - which we're sure many of you are - first, **pay attention to the standards** when you set up your protocols! A wrong value can produce a very confusing error.

Second, though, is a debugging tip. Linkerd as a project is very big on the idea of "first, do no harm": if you add Linkerd to a working application it should _keep_ working. That means we take the standards quite seriously, and we're very careful about how we handle both protocol detection and protocol declaration. If Linkerd seems to be ignoring a Route that it's marked as `Accepted`, that's always something of a red flag, and incorrect protocol declarations are a great place to start looking.

And props to all the unsung heroes writing tests! Testing is hard, important, and often thankless: more of us should spend time there than do.

----

_Feedback is always welcome; just ping `@flynn` on the [Linkerd Slack](https://slack.linkerd.io)._
