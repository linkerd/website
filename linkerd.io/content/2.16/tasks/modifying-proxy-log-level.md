+++
title = "Modifying the Proxy Log Level"
description = "Linkerd proxy log levels can be modified dynamically to assist with debugging."
+++

Emitting logs is an expensive operation for a network proxy, and by default,
the Linkerd data plane proxies are configured to only log exceptional events.
However, sometimes it is useful to increase the verbosity of proxy logs to
assist with diagnosing proxy behavior. Happily, Linkerd allows you to modify
these logs dynamically.

{{< note >}}
The proxy's proxy debug logging is distinct from the proxy HTTP access log,
which is configured separately. See the documentation on [enabling access
logging](../../features/access-logging/) for details on configuring Linkerd
proxies to emit an HTTP access log.
{{< /note >}}

The log level of a Linkerd proxy can be modified on the fly by using the proxy's
`/proxy-log-level` endpoint on the admin-port.

For example, to change the proxy log-level of a pod to
`debug`, run
(replace `${POD:?}` or set the environment-variable `POD` with the pod name):

```sh
kubectl port-forward ${POD:?} linkerd-admin
curl -v --data 'linkerd=debug' -X PUT localhost:4191/proxy-log-level
```

whereby `linkerd-admin` is the name of the admin-port (`4191` by default)
of the injected sidecar-proxy.

The resulting logs can be viewed with `kubectl logs ${POD:?}`.

If changes to the proxy log level should be retained beyond the lifetime of a
pod, add the `config.linkerd.io/proxy-log-level` annotation to the pod template
(or other options, see reference).

The syntax of the proxy log level can be found in the
[proxy log level reference](../../reference/proxy-log-level/).

Note that logging has a noticeable, negative impact on proxy throughput. If the
pod will continue to serve production traffic, you may wish to reset the log
level once you are done.
