---
title: Debugging 502s
description: Determine why Linkerd is returning 502 responses.
---

When the Linkerd proxy encounters connection errors while processing a request,
it will typically return an HTTP 502 (Bad Gateway) response. It can be very
difficult to figure out why these errors are happening because of the lack of
information available.

## Why do these errors only occur when Linkerd is injected?

Linkerd turns connection errors into HTTP 502 responses. This can make issues
which were previously undetected suddenly visible. This is a good thing. Linkerd
also changes the way that connections to your application are managed: it
re-uses persistent connections and establishes an additional layer of connection
tracking. Managing connections in this way can sometimes expose underlying
application or infrastructure issues such as misconfigured connection timeouts
which can manifest as connection errors.

## Why can't Linkerd give a more informative error message?

From the Linkerd proxy's perspective, it just sees its connections to the
application refused or closed without explanation. This makes it nearly
impossible for Linkerd to report any error message in the 502 response. However,
if these errors coincide with the introduction of Linkerd, it does suggest that
the problem is related to connection re-use or connection tracking. Here are
some common reasons why the application may be refusing or terminating
connections.

## Common Causes of Connection Errors

### Connection Idle Timeouts

Some servers are configured with a connection idle timeout (for example,
[this timeout in the Go HTTP server](https://golang.org/src/net/http/server.go#L2535]).
This means that the server will close any connections which do not receive any
traffic in the specified time period. If any requests are already in transit
when the connection shutdown is initiated, those requests will fail. This
scenario is likely to occur if you have traffic with a regular period (such as
liveness checks, for example) and an idle timeout equal to that period.

To remedy this, ensure that your server's idle timeouts are sufficiently long so
that they do not close connections which are actively in use.

### Half-closed Connection Timeouts

During the shutdown of a TCP connection, each side of the connection must be
closed independently. When one side is closed but the other is not, the
connection is said to be "half-closed". It is valid for the connection to be in
this state, however, the operating system's connection tracker can lose track of
connections which remain half-closed for long periods of time. This can lead to
responses not being delivered and to port conflicts when establishing new
connections which manifest as 502 responses.

You can use a
[script to detect half-closed connections](https://gist.github.com/adleong/0203b0864af2c29ddb821dd48f339f49)
on your Kubernetes cluster. If you detect a large number of half-closed
connections, you have a couple of ways to remedy the situation.

One solution would be to update your application to not leave connections
half-closed for long periods of time or to stop using software that does this.
Unfortunately, this is not always an option.

Another option is to increase the connection tracker's timeout for half-closed
connections. The default value of this timeout is platform dependent but is
typically 1 minute or 1 hour. You can view the current value by looking at the
file `/proc/sys/net/netfilter/nf_conntrack_tcp_timeout_close_wait` in any
injected container. To increase this value, you can use the
`--close-wait-timeout` flag with `linkerd inject`. Note, however, that setting
this flag will also set the `privileged` field of the proxy init container to
true. Setting this timeout to 1 hour is usually sufficient and matches the
[value used by kube-proxy](https://github.com/kubernetes/kubernetes/issues/32551).
