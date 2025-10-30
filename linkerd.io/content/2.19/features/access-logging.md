---
title: HTTP Access Logging
description: Linkerd proxies can be configured to emit HTTP access logs.
---

Linkerd proxies can be configured to generate an HTTP access log that records
all HTTP requests that transit the proxy.

The `config.linkerd.io/access-log` annotation is used to enable proxy HTTP
access logging. Adding this annotation to a namespace or workload configures the
proxy injector to set an environment variable in the proxy container that
configures access logging.

HTTP access logging is disabled by default because it has a performance impact,
compared to proxies without access logging enabled. Enabling access logging may
increase tail latency and CPU consumption under load. The severity of
this performance cost may vary depending on the traffic being proxied, and may
be acceptable in some environments.

{{< note >}}
The proxy's HTTP access log is distinct from proxy debug logging, which is
configured separately. See the documentation on [modifying the proxy log
level](../tasks/modifying-proxy-log-level/) for details on configuring the
proxy's debug logging.
{{< /note >}}

## Access Log Formats

The value of the `config.linkerd.io/access-log` annotation determines the format
of HTTP access log entries, and can be either "apache" or "json".

Setting the `config.linkerd.io/access-log: "apache"` annotation configures the
proxy to emit HTTP access logs in the [Apache Common Log
Format](https://en.wikipedia.org/wiki/Common_Log_Format). For example:

```text {class=disable-copy}
10.42.0.63:51160 traffic.booksapp.serviceaccount.identity.linkerd.cluster.local - [2022-08-23T20:28:20.071809491Z] "GET http://webapp:7000/ HTTP/2.0" 200
10.42.0.63:51160 traffic.booksapp.serviceaccount.identity.linkerd.cluster.local - [2022-08-23T20:28:20.187706137Z] "POST http://webapp:7000/authors HTTP/2.0" 303
10.42.0.63:51160 traffic.booksapp.serviceaccount.identity.linkerd.cluster.local - [2022-08-23T20:28:20.301798187Z] "GET http://webapp:7000/authors/104 HTTP/2.0" 200
10.42.0.63:51160 traffic.booksapp.serviceaccount.identity.linkerd.cluster.local - [2022-08-23T20:28:20.409177224Z] "POST http://webapp:7000/books HTTP/2.0" 303
10.42.0.1:43682 - - [2022-08-23T20:28:23.049685223Z] "GET /ping HTTP/1.1" 200
```

Setting the `config.linkerd.io/access-log: json` annotation configures the proxy
to emit access logs in a JSON format. For example:

```json {class=disable-copy}
{"client.addr":"10.42.0.70:32996","client.id":"traffic.booksapp.serviceaccount.identity.linkerd.cluster.local","host":"webapp:7000","method":"GET","processing_ns":"39826","request_bytes":"","response_bytes":"19627","status":200,"timestamp":"2022-08-23T20:33:42.321746212Z","total_ns":"14441135","trace_id":"","uri":"http://webapp:7000/","user_agent":"Go-http-client/1.1","version":"HTTP/2.0"}
{"client.addr":"10.42.0.70:32996","client.id":"traffic.booksapp.serviceaccount.identity.linkerd.cluster.local","host":"webapp:7000","method":"POST","processing_ns":"30036","request_bytes":"33","response_bytes":"0","status":303,"timestamp":"2022-08-23T20:33:42.436964052Z","total_ns":"14122403","trace_id":"","uri":"http://webapp:7000/authors","user_agent":"Go-http-client/1.1","version":"HTTP/2.0"}
{"client.addr":"10.42.0.70:32996","client.id":"traffic.booksapp.serviceaccount.identity.linkerd.cluster.local","host":"webapp:7000","method":"GET","processing_ns":"38664","request_bytes":"","response_bytes":"2350","status":200,"timestamp":"2022-08-23T20:33:42.551768300Z","total_ns":"6998222","trace_id":"","uri":"http://webapp:7000/authors/105","user_agent":"Go-http-client/1.1","version":"HTTP/2.0"}
{"client.addr":"10.42.0.70:32996","client.id":"traffic.booksapp.serviceaccount.identity.linkerd.cluster.local","host":"webapp:7000","method":"POST","processing_ns":"42492","request_bytes":"46","response_bytes":"0","status":303,"timestamp":"2022-08-23T20:33:42.659401621Z","total_ns":"9274163","trace_id":"","uri":"http://webapp:7000/books","user_agent":"Go-http-client/1.1","version":"HTTP/2.0"}
{"client.addr":"10.42.0.1:56300","client.id":"-","host":"10.42.0.69:7000","method":"GET","processing_ns":"35848","request_bytes":"","response_bytes":"4","status":200,"timestamp":"2022-08-23T20:33:49.254262428Z","total_ns":"1416066","trace_id":"","uri":"/ping","user_agent":"kube-probe/1.24","version":"HTTP/1.1"}
```

## Consuming Access Logs

The HTTP access log is written to the proxy container's `stderr` stream, while
the proxy's standard debug logging is written to the proxy container's `stdout`
stream. Currently, the `kubectl logs` command will always output both the
container's `stdout` and `stderr` streams. However, [KEP
3289](https://github.com/kubernetes/enhancements/pull/3289) will add support for
separating a container's `stdout` or `stderr` in the `kubectl logs` command.
