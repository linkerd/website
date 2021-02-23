---
slug: 'prometheus-the-right-way-lessons-learned-evolving-conduits-prometheus-integration'
title: "Prometheus the Right Way: Lessons learned evolving Conduit's Prometheus integration"
aliases:
  - /2018/05/17/prometheus-the-right-way-lessons-learned-evolving-conduits-prometheus-integration/
author: 'andrew'
date: Thu, 17 May 2018 18:21:51 +0000
thumbnail: /uploads/prometheus-the-right-way.png
draft: false
featured: false
tags: [Conduit, Uncategorized]
---

Conduit is now part of Linkerd! [Read more >]({{< relref
"conduit-0-5-and-the-future" >}})

_This post was coauthored by_ [_Frederic Branczyk_](https://twitter.com/fredbrancz)_, a member of the Prometheus team._

[Conduit](https://conduit.io/) is an open source service mesh for Kubernetes. One of its features is a full telemetry pipeline, built on [Prometheus](https://prometheus.io/), that automatically captures service success rates, latency distributions, request volumes, and much more.

In the 0.4.0 release, in collaboration with [Frederic Branczyk](https://twitter.com/fredbrancz), a member of the upstream Prometheus team, we rewrote this pipeline from the ground up. This post shares some of the lessons we learned about Prometheus along the way.

## Telemetry pipeline: a first pass

Conduit aims to provide top-line service metrics without requiring any configuration or code changes. No matter what your Kubernetes application does or what language it’s written in, Conduit should expose critical service metrics like success rates without any effort on your part. To do this, Conduit instruments all traffic as it passes through the Conduit proxies, aggregates this telemetry information, and reports the results. This is known as the “telemetry pipeline,” and Prometheus is a central component.

When we released Conduit 0.2.0 in January, it included a first pass at user-visible telemetry. In this initial iteration, Conduit was extremely liberal in how it recorded metrics, storing histograms for every possible combination of request metadata (including paths, etc), and exposing this information at extremely small time granularities (down to the second).

In order to do this without incurring latency or significant memory consumption in the proxy, we maintained a fixed-sized buffer of events, which the proxy periodically sent to the control plane to be processed. The control plane aggregated these events, using the Kubernetes API to discover interesting source and destination labels, and in turn exposed these detailed metrics to be scraped by Prometheus. Conduit’s control plane contained a dedicated service, called Telemetry, that exposed an API with distinct read and write paths.

{{< fig
  alt="Initial telemetry pipeline architecture" src="/uploads/2018/05/conduit-prom-1-1024x656-1024x656.png"
  title="Initial telemetry pipeline architecture" >}}

### Writes

In this initial version, proxies pushed metrics via a [gRPC write interface][proto] provided by the Telemetry service. The overall telemetry flow was:

1. The Conduit proxies (one in each Kubernetes Pod) push metrics to our Telemetry service via a gRPC interface.
2. The Telemetry service aggregates data from each proxy.
3. The Telemetry service exposes this aggregated data on a `/metrics` endpoint.
4. Prometheus collects from the Telemetry service’s `/metrics` endpoint.

Here is just a small snippet of that gRPC write interface:

```protobuf
message ReportRequest {
  Process process = 1;
  enum Proxy {
    INBOUND = 0;
    OUTBOUND = 1;
  }
  Proxy proxy = 2;
  repeated ServerTransport server_transports = 3;
  repeated ClientTransport client_transports = 4;
  repeated RequestScope requests = 5;
}
message Process {
  string node = 1;
  string scheduled_instance = 2;
  string scheduled_namespace = 3;
}
message ServerTransport {
  common.IPAddress source_ip = 1;
  uint32 connects = 2;
  repeated TransportSummary disconnects = 3;
  common.Protocol protocol = 4;
}
...
```

### Reads

Similarly, the initial read path used a [gRPC read interface](https://github.com/runconduit/conduit/blob/v0.2.0/proto/controller/telemetry/telemetry.proto#L7-L35) for the Public API to query the Telemetry service, and followed a comparable flow:

1. Public API service queries Telemetry for metrics via gRPC.
2. Telemetry service queries Prometheus.
3. Telemetry service repackages the data from Prometheus.
4. Telemetry service returns repackaged data to the Public API.

## A collaboration

When we announced the Conduit 0.2.0 release on Twitter, it resulted in this seemingly innocuous reply: {{< tweet 959111860871225344 >}} Frederic helped us identify a number of issues in the telemetry pipeline we had designed:

- The push model required the Telemetry service to hold and aggregate a lot of state that was already present in all the proxies.
- Recency of data was inconsistent due to timing difference between proxy push intervals and Prometheus collection intervals.
- Though the Telemetry service appeared as a single collection target to Prometheus, we were essentially simulating a group of proxies by overloading metric labels.
- It was challenging to iterate, modify, and add new metric types. The read and write gRPC interfaces were acting as inflexible wrappers around an established Prometheus metrics format and query language.

In addition, Conduit had re-implemented a lot of functionality that was already provided by Prometheus, and didn’t take advantage of some functionality it should have:

- Prometheus operates with pull model.
- Prometheus already has excellent [Kubernetes service discovery support](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#%3Ckubernetes_sd_config%3E).
- Prometheus has a flexible and powerful [query language](https://prometheus.io/docs/prometheus/latest/querying/basics/).

## Telemetry pipeline: doin’ it right

With Frederic’s pointers in mind, we set about stripping away any functionality in Conduit that could be offloaded onto Prometheus. The most obvious component for removal was the Telemetry service itself, which was aggregating data across proxies on the write side, and serving metrics queries on the read side: two things Prometheus could already do itself.

Removal of the Telemetry service meant that the proxies needed to serve a `/metrics` endpoint that Prometheus could collect from. To populate this, we developed a [metrics recording and serving module](https://github.com/runconduit/conduit/tree/86bb701be8ce5904334a29452fca25d0f507f6dc/proxy/src/telemetry/metrics) specific to our Rust proxy. On the read side, we then needed to wire up the Public API directly to Prometheus. Fortunately much of that integration code already existed in the Telemetry service, so we simply moved that Prometheus client code into the Public API.

These changes allowed us to delete our gRPC read and write APIs, and yielded a much simpler and more flexible architecture:

{{< fig
  alt="Conduit Telemetry The Right Way" src="/uploads/2018/05/conduit-prom-2-1024x509-1024x509.png"
  title="Updated telemetry pipeline architecture" >}}

The new telemetry pipelines were significantly easier to reason about:

### Write pipeline

- Rust proxies serve a `/metrics` endpoint.
- Prometheus pulls from each proxy, discovered via Kubernetes service discovery.

### Read pipeline

- Public API queries Prometheus for metrics.

We released the redesigned metrics pipeline with Conduit 0.4.0, and there was much rejoicing.

{{< tweet 986115332657045505 >}}

### Plus some cool new features

The new telemetry pipeline also unlocked a number of notable cool new features, including advancements to the `conduit stat` command and an easy Grafana integration:

```bash
$ conduit -n emojivoto stat deploy
NAME       MESHED   SUCCESS      RPS   LATENCY_P50   LATENCY_P95   LATENCY_P99
emoji         1/1   100.00%   2.0rps           5ms          10ms          10ms
vote-bot      1/1         -        -             -             -             -
voting        1/1    87.72%   0.9rps           6ms          16ms          19ms
web           1/1    93.91%   1.9rps           8ms          41ms          48ms
```

{{< fig
  alt="Conduit Grafana Dashboard"
  src="/uploads/2018/05/conduit-grafana-1-1024x556-1024x556.png"
  title="Conduit Grafana dashboard" >}}

## Looking ahead

Of course, there’s still a lot more work to do on the Conduit service mesh and its telemetry system, including:

- Leveraging [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics) for more complete Kubernetes resource information.
- Leveraging [Kubernetes Mixins](https://github.com/kubernetes-monitoring/kubernetes-mixin) for more flexible generation of Grafana dashboards.
- Immediate expiration of metrics in the proxy when Kubernetes services go away, in order to make appropriate use of Prometheus' staleness handling.
- Long-term metrics storage.

We hope you enjoyed this summary of how and why we rewrote Conduit’s telemetry pipeline to better make use of Prometheus. What to try the results for yourself? [Follow the Conduit quickstart](https://conduit.io/getting-started/) and get service metrics on any Kubernetes 1.8+ app in about 60 seconds.

If you like this sort of thing, please come get involved! Conduit is open source, everything is up on the [GitHub repo](https://github.com/runconduit/conduit), and we love new contributors. Hop into the [conduit-users](https://groups.google.com/forum/#!forum/conduit-users), [conduit-dev](https://groups.google.com/forum/#!forum/conduit-dev), and [conduit-announce](https://groups.google.com/forum/#!forum/conduit-announce) mailing lists, the [#conduit Slack channel](https://slack.linkerd.io/), and take a look at the issues marked “[help wanted](https://github.com/runconduit/conduit/labels/help%20wanted)”. For more details on upcoming Conduit releases, check out our [Public Roadmap](https://conduit.io/roadmap/).

[proto]: https://github.com/runconduit/conduit/blob/v0.2.0/proto/proxy/telemetry/telemetry.proto
