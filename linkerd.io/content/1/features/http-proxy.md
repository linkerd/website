+++
aliases = ["/getting-started/http-proxy", "/features/http-proxy"]
description = "Linkerd can act as an HTTP proxy, which is widely supported by almost all modern HTTP clients, making it easy to integrate into existing applications."
title = "HTTP proxy integration"
weight = 6
[menu.docs]
parent = "features"
weight = 16

+++
Virtually all HTTP clients support making calls through an intermediate proxy.
Traditionally, this was used to operate in firewalled environments where
connections to the external world were restricted. However, since Linkerd
functions as an HTTP proxy, and since using a proxy can often be accomplished
without code changes, this approach also offers an easy integration path for
applications that use HTTP.

## Linkerd as an HTTP proxy

Linkerd can act as an HTTP proxy without any additional configuration, providing
key features such as [load balancing]({{% ref "/1/features/load-balancing.md" %}}),
[service discovery]({{% ref "/1/features/service-discovery.md" %}}) and [dynamic
request routing]({{% ref "/1/features/routing.md" %}}) at no extra cost. By default
Linkerd routes HTTP requests based on the HTTP host that is sent as part of the
request. For example, suppose that Linkerd is running locally on port 4140, and
that it has been configured to route requests to instances of the "hello"
service running elsewhere. In that scenario, you could take advantage of
Linkerd's proxy integration and make a curl request to the "hello" service with:

```bash
http_proxy=localhost:4140 curl http://hello/
```

With the `http_proxy` variable set, curl will send the proxy request directly to
Linkerd, without actually looking up "hello" in DNS. Linkerd will in turn look
up the "hello" service in whichever backend it is configured to use for service
discovery, and it will route the request accordingly.

## Using an HTTP proxy

Configuring your application to use an HTTP proxy can often be done without code
changes. However, the specifics of this configuration are language-dependent.
Here are some examples for common setups:

* **C, Go, Python, Ruby, Perl, PHP, curl, wget, Node.js' request package**:
  these languages and utilities support an `http_proxy` environment variable,
  which sets a global HTTP proxy across all requests. Simply set the variable
  and you're good to go.

* **Java, Scala, Clojure, and JVM languages**: the JVM can be configured to use
  an HTTP proxy by setting the `http.proxyHost` and `http.proxyPort` environment
  variables, (e.g. `java -Dhttp.proxyHost=127.0.0.1 -Dhttp.proxyPort=4140 ...`).

* **Node.js**. For Node, there is no convenient code-free approach to using a
  global proxy. Options include the
  [request](https://www.npmjs.com/package/request) or
  [global tunnel](https://www.npmjs.com/package/global-tunnel) packages.

## Alternatives

In principle, Linkerd can route on any component of the request, from incoming
port to payload content. In practice, for HTTP calls, it is most natural to
route on the host (using the default [`methodAndHost` identifier]({{%
linkerdconfig "method-and-host-identifier" %}})) or on the URL path (using the
[`path` identifier]({{% linkerdconfig "path-identifier" %}})).

If a global HTTP proxy approach is not possible, any mechanism that allows
setting the host or URL path while connecting to Linkerd will also work. For
example, proxy settings can often be configured directly in the HTTP client on
a per-request basis. Alternatively, connecting directly to Linkerd and setting
an explicit `Host:` header as part of the request will allow Linkerd to route
on that host just as the proxy approach would.

Another alternative if you are running on Kubernetes is using
[transparent proxying]({{% ref "/1/features/transparent-proxying.md" %}}) via
iptables rules.
