+++
title = "Distributed tracing with Linkerd"
description = "Use Linkerd to help instrument your application with distributed tracing."
+++

Using distributed tracing in practice can be complex, for a high level
explanation of what you get and how it is done, we've assembled a [list of
myths](https://linkerd.io/2019/08/09/service-mesh-distributed-tracing-myths/).

This guide will walk you through configuring and enabling tracing for
[emojivoto](../../getting-started/#step-5-install-the-demo-app). Jump to the end
for some recommendations on the best way to make use of distributed tracing with
Linkerd.

To use distributed tracing, you'll need to:

- Add a collector which receives spans from your application and Linkerd.
- Add a tracing backend to explore traces.
- Modify your application to emit spans.
- Configure Linkerd's proxies to emit spans.

In the case of emojivoto, once all these steps are complete there will be a
topology that looks like:

{{< fig src="/images/tracing/tracing-topology.svg"
        title="Topology" >}}

## Prerequisites

- To use this guide, you'll need to have Linkerd installed on your cluster.
  Follow the [Installing Linkerd Guide](../install/) if you haven't
  already done this.

## Install Trace Collector & Jaeger

The first step of getting distributed tracing setup is installing a collector
onto your cluster. This component consists of "receivers" that consume spans
emitted from the mesh and your applications as well as "exporters" that convert
spans and forward them to a backend.

Next, we will need [Jaeger](https://www.jaegertracing.io/) in your cluster.
The [all inone](https://www.jaegertracing.io/docs/1.8/getting-started/#all-in-one)
configuration will store the traces, make them searchable and provide
visualization of all the data being emitted.

Linkerd now has add-ons which enables users to install extra components that
integrate well with Linkerd. Tracing is such one add-on which includes [OpenCensus
Collector](https://opencensus.io/service/components/collector/)  and
[Jaeger](https://www.jaegertracing.io/)

To add the Tracing Add-On to your cluster,
run:

First, we would need a configuration file where we enable the Tracing Add-On.

```bash
cat >> config.yaml << EOF
tracing:
  enabled: true
EOF
```

This configuration file can also be used to apply Add-On configuration
(not just specific to tracing Add-On). More information on the configuration
fields allowed, can be found [here](https://github.com/linkerd/linkerd2/tree/main/charts/linkerd2#add-ons-configuration)

Now, the above configuration can be applied using the `--config` file
with CLI or through `values.yaml` with Helm.

```bash
linkerd upgrade --config config.yaml | kubectl apply -f -
```

You will now have a `linker-collector` and `linkerd-jaeger`
deployments in the linkerd namespace that are running as part of the mesh.
Collector has been configured to:

- Receive spans from OpenCensus clients
- Export spans to a Jaeger backend

The collector is extremely configurable and can use the
[receiver](https://opencensus.io/service/receivers/) or
[exporter](https://opencensus.io/service/exporters/) of your choice.

Jaeger itself is made up of many
[components](https://www.jaegertracing.io/docs/1.14/architecture/#components).
The all-in-one image bundles all these components into a single container to
make demos and showing tracing off a little bit easier.

Before moving onto the next step, make sure everything is up and running with
`kubectl`:

```bash
kubectl -n linkerd rollout status deploy/linkerd-collector
kubectl -n linkerd rollout status deploy/linkerd-jaeger
```

## Install Emojivoto

 Add emojivoto to your cluster with:

 ```bash
 kubectl apply -f https://run.linkerd.io/emojivoto.yml
 ```

It is possible to use `linkerd inject` to add the proxy to emojivoto as outlined
in [getting started](../../getting-started/). Alternatively, annotations can do the
same thing. You can patch these onto the running application with:

```bash
kubectl -n emojivoto patch -f https://run.linkerd.io/emojivoto.yml -p '
spec:
  template:
    metadata:
      annotations:
        linkerd.io/inject: enabled
        config.linkerd.io/trace-collector: linkerd-collector.linkerd:55678
        config.alpha.linkerd.io/trace-collector-service-account: linkerd-collector
'
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
kubectl -n emojivoto set env --all deploy OC_AGENT_HOST=linkerd-collector.linkerd:55678
```

This command will add an environment variable that enables the applications to
propagate context and emit spans.

## Explore Jaeger

With `vote-bot` starting traces for every request, spans should now be showing
up in Jaeger. To get to the UI, start a port forward and send your browser to
[http://localhost:16686](http://localhost:16686/).

```bash
kubectl -n linkerd port-forward svc/linkerd-jaeger 16686
```

{{< fig src="/images/tracing/jaeger-empty.png"
        title="Jaeger" >}}

You can search for any service in the dropdown and click Find Traces. `vote-bot`
is a great way to get started.

{{< fig src="/images/tracing/jaeger-search.png"
        title="Search" >}}

Clicking on a specific trace will provide all the details, you'll be able to see
the spans for every proxy!

{{< fig src="/images/tracing/example-trace.png"
        title="Search" >}}

There sure are a lot of `linkerd-proxy` spans in that output. Internally, the
proxy has a server and client side. When a request goes through the proxy, it is
received by the server and then issued by the client. For a single request that
goes between two meshed pods, there will be a total of 4 spans. Two will be on
the source side as the request traverses that proxy and two will be on the
destination side as the request is received by the remote proxy.

Additionally, As the proxy adds application meta-data as trace attributes, Users
can directly jump into related resources traces directly from the linkerd-web
dashboard by clicking the Jaeger icon in the Metrics Table, as shown below

{{< fig src="/images/tracing/linkerd-jaeger-ui.png"
        title="Linkerd-Jaeger" >}}

## Cleanup

To cleanup, remove the tracing components along with emojivoto by running:

```bash
kubectl delete ns tracing emojivoto
```

## Troubleshooting

### I don't see any spans for the proxies

The Linkerd proxy uses the [b3
propagation](https://github.com/openzipkin/b3-propagation) format. Some client
libraries, such as Jaeger, use different formats by default. You'll want to
configure your client library to use the b3 format to have the proxies
participate in traces.

### I don't see any traces

Instead of requiring complex client configuration to ensure spans are encrypted
in transit, Linkerd relies on its mTLS implementation. This means that it is
*required* the collector is part of the mesh. If you are using a service account
other than `default` for the collector, the proxies must be configured to use
this as well with the `config.alpha.linkerd.io/trace-collector-service-account`
annotation.

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
    zipkin-collector-host: linkerd-collector.linkerd
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
spending in the proxy and on the wire. To enable Linkerd's participation:

- Set the `config.linkerd.io/trace-collector` annotation on the namespace or pod
  specs that you want to participate in traces. This should be set to the
  address of the OpenCensus collector service.
- Set the `config.alpha.linkerd.io/trace-collector-service-account` annotation
  on the namespace of pod specs that you want to participate in traces. This
  should be set to the name of the service account of the collector and is used
  to ensure secure communication between the proxy and the collector. This can
  be omitted if the collector is running as the default service account.
- Ensure the OpenCensus collector is injected with the Linkerd proxy.

While Linkerd can only actively participate in traces that use the b3
propagation format, Linkerd will always forward unknown request headers
transparently, which means it will never interfere with traces that use other
propagation formats.
