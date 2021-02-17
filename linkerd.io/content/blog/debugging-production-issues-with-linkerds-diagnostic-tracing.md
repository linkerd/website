---
slug: 'debugging-production-issues-with-linkerds-diagnostic-tracing'
title: "Debugging production issues with Linkerd's diagnostic tracing"
aliases:
  - /2018/06/19/debugging-production-issues-with-linkerds-diagnostic-tracing/
author: 'dennis'
date: Tue, 19 Jun 2018 23:25:51 +0000
draft: false
featured: false
thumbnail: /uploads/DiagnosticTracing_Linkerd.png
tags:
  [
    debug,
    debugging,
    Linkerd,
    linkerd,
    microservices,
    News,
    tracing,
    Tutorials &amp; How-To's,
  ]
---

[Linkerd 1.4.2](https://github.com/linkerd/linkerd/releases/tag/1.4.2) introduces a new _diagnostic tracing_ feature that allows you to send test requests through the system in order to see how Linkerd routed that request at each hop along the way. Diagnostic tracing allows you to quickly solve common Linkerd troubleshooting scenarios without affecting the state of your production services.

Of the lessons we’ve learned over the last two years from helping companies around the world put Linkerd into production, the one that stands out above the rest is the importance of having solid _runtime diagnostics_. We commonly find that the exact configuration and deployment scheme that worked in staging and dev can exhibit unexpected behavior in production. And just as commonly as they occur, reproducing those anomalies outside of the production environment context can be incredibly difficult.

In part, that’s a fundamental law of software---new problems _always_ crop up in prod (to paraphrase Mike Tyson, “everyone has a plan until they deploy to production”). This is particularly troublesome for Linkerd because of its position in the stack as an integration layer. By sitting at the intersection of the layer 3 network, service discovery, DNS, application behavior, and many other distributed system components, any latent problem in the interaction between these systems can seem to manifest itself as unexpected behavior in Linkerd itself.

When Linkerd first gets introduced into new infrastructure, it naturally becomes the first thing that takes the blame whenever anything goes wrong. Our first inclination is to conclude that failures are happening in the new component. Obviously, it’s that new thing we just put in because everything now routes through it! Therefore, introspective diagnostics are vital to determine what’s actually at fault and showing a path to resolution. (For more about the blame phenomenon, see [How to Put a Service Mesh into Production Without Getting Fired](https://www.youtube.com/watch?v=XA1aGpYzpYg))

To improve this, we’ve been hard at work over the past few months adding runtime diagnostics to Linkerd to allow operators to rapidly diagnose issues in production. Some examples of these diagnostics include the ability to [introspect current Kubernetes and Namerd watch states](https://github.com/linkerd/linkerd/releases/tag/1.4.1). Additionally, we’re happy to now introduce the new diagnostic tracing feature.

## An introduction to diagnostic tracing

Diagnostic tracing is a feature [originally requested by Oliver Beattie](https://github.com/linkerd/linkerd/issues/1732), Head of Engineering at Monzo, during a bout of particularly complex Linkerd production debugging. It was such a great idea that we’ve built it right into Linkerd. Mirroring that troubleshooting scenario and others within the community, we’ve identified several situations where diagnostic tracing could be useful. We found that:

- In situations where other verification mechanisms do not exist, it can be hard to tell if a request was routed correctly to a destination service.
- If multiple Linkerd instances are involved in request routing (linker-to-linker configuration) it can be difficult to identify which exact Linkerd instance failed to route a request.
- The dtab playground UI presumes you already know how a request is identified. It also does not use Linkerd’s actual internal state to identify and route requests. Rather, the UI spins up new service lookup requests on service names. This can cause discrepancies between how the request is actually routed and how the UI thinks Linkerd will route the request.
- It can be difficult to differentiate whether routing failures originated from a failed service or from a failure within Linkerd.

With diagnostic tracing, you can send a test request to a service in production, without affecting its production state, to determine what’s happening in these situations. Each Linkerd instance that proxies the test request gathers information about how it’s configured to route requests to its intended service and adds that information to the response. The result is a detailed list of all Linkerd instances that participate in the request path to a service --- effectively creating a "breadcrumb" trail to that service.

In cases where you want to verify that requests are routed correctly, diagnostic tracing gives you the IP addresses of the destination services where the test request is sent. Diagnostic tracing also gives you step by step name resolution for service names, allowing you to observe how Linkerd resolves these names without having to go through the admin UI.  Finally, because each Linkerd appends its routing context to the response body of test requests, diagnostic tracing shows the role each Linkerd instance plays in the request path and helps you identify which instance may have failed to route a request.

## Diagnostic tracing in practice

Let's walk through a scenario to see how diagnostic tracing can help us troubleshoot service failures. In our scenario, Linkerd is set up in a [linker-to-linker](https://github.com/linkerd/linkerd-examples/blob/b5689b517108c2a79138e34d8357787580106e76/k8s-daemonset/k8s/servicemesh.yml) configuration with some downstream service receiving traffic.

When we send a request to a service (in our example we use a linker-to-linker setup pointing to a hello service) through Linkerd and we see this response:

<!-- markdownlint-disable MD014 -->
```bash
$ curl http://localhost:4140/hello

Invalid response 500
```
<!-- markdownlint-enable MD014 -->

The response doesn't really help us troubleshoot where the problem may be coming from. Is this error message being sent from Linkerd? If so, which Linkerd is it coming from in our linker-to-linker configuration? Is this a message from the hello service itself? It's difficult to tell.

Instead, running a diagnostic trace generates much more useful information. To send a diagnostic trace, set the HTTP method to TRACE and add the “l5d-add-context: true” header.

For example, sending a diagnostic test request using curl would look like this:

<!-- markdownlint-disable MD014 -->
```bash
$ curl -X TRACE -H "l5d-add-context: true"

http://localhost:4140/<service name>
```
<!-- markdownlint-enable MD014 -->

Using this command with our hello service, we see this response:

<!-- markdownlint-disable MD014 -->
```bash
$ curl -X TRACE -H "l5d-add-context: true" http://localhost:4140/hello

invalid response 500

--- Router: incoming ---
request duration: 22 ms
service name: /svc/hello
client name: /%/io.l5d.localhost/#/io.l5d.fs/hello
addresses: [127.0.0.1:7777]
selected address: 127.0.0.1:7777
dtab resolution:
 /svc/hello
 /#/io.l5d.fs/hello (/svc=>/#/io.l5d.fs)
 /%/io.l5d.localhost/#/io.l5d.fs/hello (SubnetLocalTransformer)

--- Router: outgoing ---
request duration: 32 ms
service name: /svc/hello
client name: /%/io.l5d.port/4141/#/io.l5d.fs/hello
addresses: [127.0.0.1:4141]
selected address: 127.0.0.1:4141
dtab resolution:
 /svc/hello
 /#/io.l5d.fs/hello (/svc=>/#/io.l5d.fs)
 /%/io.l5d.port/4141/#/io.l5d.fs/hello (DelegatingNameTreeTransformer$)
```
<!-- markdownlint-enable MD014 -->

The diagnostic trace request gives us much more information to work with! From the response, we can see that the request first hits the "outgoing" Linkerd router or the first linker in the linker-to-linker configuration. Then, the request is forwarded to the "incoming" Linkerd router (the second linker). The request is then forwarded to the hello service at `127.0.0.1:7777` and there is where we see the origins of the `invalid response 500`. With diagnostic tracing, we can deduce the **request duration** between each Linkerd hop. the **service name** used to identify the recipient of the TRACE request, the load balancer set of **IP** **addresses** that point to service, the **selected address** used to forward the test request, and the **dtab resolution** or steps Linkerd takes to resolve a service name to a client name. With this information, we can confirm that the hello service generates the error rather than Linkerd and that Linkerd is indeed routing the request correctly. Pretty neat!

## How it works

Linkerd checks for TRACE requests that have an `l5d-add-context` header set to true and only adds its routing context in the presence of this header. TRACE requests aren't typically used in a production environment, so it is generally safe to forward requests to production services. Furthermore, HTTP TRACE, according to [RFC 7231, section 4.3.8](https://tools.ietf.org/html/rfc7231#section-4.3.8), is intended to be used by clients to test or diagnose how servers downstream react to incoming requests. During diagnostic tracing, other Linkerd instances may encounter a diagnostic trace request. When that happens, that Linkerd instance forwards the request until it reaches some service that responds with an HTTP status code and possibly a response body. By the time the initial client receives the response, each Linkerd that forwards the request has appended its routing context to the response. The client then gets a detailed list of all services and Linkerd instances along request path.

## Distributed tracing vs. Diagnostic tracing

Despite its name, diagnostic tracing is not a substitute for “standard” distributed tracing like Zipkin and OpenTracing. Rather, it is an additional tool that can be used to troubleshoot your applications better. “Standard” distributed tracing is different when compared to diagnostic tracing in several ways:

- Standard distributed tracing observes actual production traffic, while diagnostic tracing sends dedicated test requests.
- Standard distributed tracing gives you a complete picture of your application if you have configured services to forward trace headers, while diagnostic tracing requests are reflected by the first server that responds to the request.
- Standard distributed tracing typically requires you to view traces through some side-channel like the Zipkin UI, while diagnostic tracing can show you the results of a diagnostic test directly in the response body.

Standard distributed tracing can answer questions like “what are the ten slowest requests to occur over the past hour, and where were they slow?”. This often requires a more involved setup process to get this kind of information. While distributed tracing is a powerful debugging tool, diagnostic tracing is quick and easy to use. It gives you concise information about whether you can or cannot route a request to a service and what steps are taken to route a request.

We’re excited to see how the Linkerd community uses this feature and we hope it will be useful in diagnosing the complex and hard-to-reproduce issues that can come up in production deployments! We’d love to hear your thoughts -- if you use Linkerd’s diagnostic tracing to debug a problem, please tell us about it by joining the [Linkerd Slack group](https://linkerd.slack.com/).
