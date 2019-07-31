+++
title = "Modifying the Proxy Log Level"
description = "Linkerd proxy log levels can be modified dynamically to assist with debugging."
+++

Emitting logs is an expensive operation for a network proxy, and by default,
the Linkerd data plane proxies are configured to only log exceptional events.
However, sometimes it is useful to increase the verbosity of proxy logs to
assist with diagnosing proxy behavior. Happily, Linkerd allows you to modify
these logs dynamically.

The log level a Linkerd proxy can be modified on the fly by setting the
`config.linkerd.io/proxy-log-level` annotation on the pod.  In both cases,
these changes will be picked up automatically, and the resulting logs can be
viewed with `kubectl logs`.

The syntax of the proxy log level can be found in the [proxy log level
reference](/2/reference/proxy-log-level/).

Note that logging has a noticeable, negative impact on proxy throughput. If the
pod will continue to serve production traffic, you may wish to reset the log
level once you are done.
