---
title: Distributed tracing with Linkerd
description: Use Linkerd to help instrument your application with distributed tracing.
---

Using distributed tracing in practice can be complex, for a high level
explanation of what you get and how it is done, we've assembled a [list of
myths](https://linkerd.io/2019/08/09/service-mesh-distributed-tracing-myths/).

This guide will walk you through configuring and enabling tracing for
[emojivoto](../../getting-started/#step-5-install-the-demo-app). Jump to the end
for some recommendations on the best way to make use of distributed tracing with
Linkerd.

To use distributed tracing, you'll need to:

- Install the Linkerd-Jaeger extension.
- Modify your application to emit spans.

In the case of emojivoto, once all these steps are complete there will be a
topology that looks like:

![Topology](/docs/images/tracing/tracing-topology.svg "Topology")

## Prerequisites

- To use this guide, you'll need to have Linkerd installed on your cluster.
  Follow the [Installing Linkerd Guide](../install/) if you haven't
  already done this.

## Install the Linkerd-Jaeger extension

The first step of getting distributed tracing setup is installing the
Linkerd-Jaeger extension onto your cluster. This extension consists of a
collector, a Jaeger backend, and a Jaeger-injector. The collector consumes spans
emitted from the mesh and your applications and sends them to the Jaeger backend
which stores them and serves a dashboard to view them. The Jaeger-injector is
responsible for configuring the Linkerd proxies to emit spans.

To install the Linkerd-Jaeger extension, run the command:

```bash
linkerd jaeger install | kubectl apply -f -
```

You can verify that the Linkerd-Jaeger extension was installed correctly by
running:

```bash
linkerd jaeger check
```

## Install Emojivoto

 Add emojivoto to your cluster and inject it with the Linkerd proxy:

 ```bash
 linkerd inject https://run.linkerd.io/emojivoto.yml | kubectl apply -f -
 ```

Before moving onto the next step, make sure everything is up and running with
`kubectl`:

```bash
kubectl -n emojivoto rollout status deploy/web
```

## Modify the application

Unlike most features of a service mesh, distributed tracing requires modifying
the source of your application. Tracing needs some way to tie incoming requests
to your application together with outgoing requests to dependent services. To do
this, some headers are added to each request that contain a unique ID for the
trace. Linkerd uses the [b3
propagation](https://github.com/openzipkin/b3-propagation) format to tie these
things together.

We've already modified emojivoto to instrument its requests with this
information, this
[commit](https://github.com/BuoyantIO/emojivoto/commit/47a026c2e4085f4e536c2735f3ff3788b0870072)
shows how this was done. For most programming languages, it simply requires the
addition of a client library to take care of this. Emojivoto uses the OpenCensus
client, but others can be used.

To enable tracing in emojivoto, run:

```bash
kubectl -n emojivoto set env --all deploy OC_AGENT_HOST=collector.linkerd-jaeger:55678
```

This command will add an environment variable that enables the applications to
propagate context and emit spans.

## Explore Jaeger

With `vote-bot` starting traces for every request, spans should now be showing
up in Jaeger. To get to the UI, run:

```bash
linkerd jaeger dashboard
```

![Jaeger](/docs/images/tracing/jaeger-empty.png "Jaeger")

You can search for any service in the dropdown and click Find Traces. `vote-bot`
is a great way to get started.

![Search](/docs/images/tracing/jaeger-search.png "Search")

Clicking on a specific trace will provide all the details, you'll be able to see
the spans for every proxy!

![Search](/docs/images/tracing/example-trace.png "Search")

There sure are a lot of `linkerd-proxy` spans in that output. Internally, the
proxy has a server and client side. When a request goes through the proxy, it is
received by the server and then issued by the client. For a single request that
goes between two meshed pods, there will be a total of 4 spans. Two will be on
the source side as the request traverses that proxy and two will be on the
destination side as the request is received by the remote proxy.

## Integration with the Dashboard

After having set up the Linkerd-Jaeger extension, as the proxy adds application
meta-data as trace attributes, users can directly jump into related resources
traces directly from the linkerd-web dashboard by clicking the Jaeger icon in
the Metrics Table, as shown below:

![Linkerd-Jaeger](/docs/images/tracing/linkerd-jaeger-ui.png "Linkerd-Jaeger")

To obtain that functionality you need to install (or upgrade) the Linkerd-Viz
extension specifying the service exposing the Jaeger UI. By default, this would
be something like this:

```bash
linkerd viz install --set jaegerUrl=jaeger.linkerd-jaeger:16686
```

## Cleanup

To cleanup, uninstall the Linkerd-Jaeger extension along with emojivoto by running:

```bash
linkerd jaeger uninstall | kubectl delete -f -
kubectl delete ns emojivoto
```

## Bring your own Jaeger

If you have an existing Jaeger installation, you can configure the OpenCensus
collector to send traces to it instead of the Jaeger instance built into the
Linkerd-Jaeger extension.

```bash
linkerd jaeger install --set collector.jaegerAddr='http://my-jaeger-collector.my-jaeger-ns:14268/api/traces' | kubectl apply -f -
```

It is also possible to manually edit the OpenCensus configuration to have it
export to any backend which it supports. See the
[OpenCensus documentation](https://opencensus.io/service/exporters/) for a full
list.

## Troubleshooting

### I don't see any spans for the proxies

The Linkerd proxy uses the [b3
propagation](https://github.com/openzipkin/b3-propagation) format. Some client
libraries, such as Jaeger, use different formats by default. You'll want to
configure your client library to use the b3 format to have the proxies
participate in traces.

## Recommendations

### Ingress

The ingress is an especially important component for distributed tracing because
it creates the root span of each trace and is responsible for deciding if that
trace should be sampled or not.  Having the ingress make all sampling decisions
ensures that either an entire trace is sampled or none of it is, and avoids
creating "partial traces".

Distributed tracing systems all rely on services to propagate metadata about the
current trace from requests that they receive to requests that they send. This
metadata, called the trace context, is usually encoded in one or more request
headers. There are many different trace context header formats and while we hope
that the ecosystem will eventually converge on open standards like [W3C
tracecontext](https://www.w3.org/TR/trace-context/), we only use the [b3
format](https://github.com/openzipkin/b3-propagation) today. Being one of the
earliest widely used formats, it has the widest support, especially among
ingresses like Nginx.

This reference architecture includes a simple Nginx config that samples 50% of
traces and emits trace data to the collector (using the Zipkin protocol).  Any
ingress controller can be used here in place of Nginx as long as it:

- Supports probabilistic sampling
- Encodes trace context in the b3 format
- Emits spans in a protocol supported by the OpenCensus collector

If using helm to install ingress-nginx, you can configure tracing by using:

```yaml
controller:
  config:
    enable-opentracing: "true"
    zipkin-collector-host: collector.linkerd-jaeger
```

### Client Library

While it is possible for services to manually propagate trace propagation
headers, it's usually much easier to use a library which does three things:

- Propagates the trace context from incoming request headers to outgoing request
  headers
- Modifies the trace context (i.e. starts a new span)
- Transmits this data to a trace collector

We recommend using OpenCensus in your service and configuring it with:

- [b3 propagation](https://github.com/openzipkin/b3-propagation) (this is the
  default)
- [the OpenCensus agent
  exporter](https://opencensus.io/exporters/supported-exporters/go/ocagent/)

The OpenCensus agent exporter will export trace data to the OpenCensus collector
over a gRPC API. The details of how to configure OpenCensus will vary language
by language, but there are [guides for many popular
languages](https://opencensus.io/quickstart/). You can also see an end-to-end
example of this in Go with our example application,
[Emojivoto](https://github.com/adleong/emojivoto).

You may notice that the OpenCensus project is in maintenance mode and will
become part of [OpenTelemetry](https://opentelemetry.io/). Unfortunately,
OpenTelemetry is not yet production ready and so OpenCensus remains our
recommendation for the moment.

It is possible to use many other tracing client libraries as well. Just make
sure the b3 propagation format is being used and the client library can export
its spans in a format the collector has been configured to receive.

## Collector: OpenCensus

The OpenCensus collector receives trace data from the OpenCensus agent exporter
and potentially does translation and filtering before sending that data to
Jaeger. Having the OpenCensus exporter send to the OpenCensus collector gives us
a lot of flexibility: we can switch to any backend that OpenCensus supports
without needing to interrupt the application.

## Backend: Jaeger

Jaeger is one of the most widely used tracing backends and for good reason: it
is easy to use and does a great job of visualizing traces. However, [any backend
supported by OpenCensus](https://opencensus.io/service/exporters/) can be used
instead.

## Linkerd

If your application is injected with Linkerd, the Linkerd proxy will participate
in the traces and will also emit trace data to the OpenCensus collector. This
enriches the trace data and allows you to see exactly how much time requests are
spending in the proxy and on the wire.

While Linkerd can only actively participate in traces that use the b3
propagation format, Linkerd will always forward unknown request headers
transparently, which means it will never interfere with traces that use other
propagation formats.
