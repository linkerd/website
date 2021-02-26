---
slug: 'linkerd-0-9-0-released'
title: 'Linkerd 0.9.0 released'
aliases:
  - /2017/02/23/linkerd-0-9-0-released/
author: 'alex'
date: Thu, 23 Feb 2017 00:24:50 +0000
draft: false
featured: false
thumbnail: /uploads/linkerd_version_009_featured.png
tags: [Linkerd, linkerd, News, Product Announcement]
---

Today we’re happy to release Linkerd 0.9.0, our best release yet! This release is jam packed with internal efficiency upgrades and major improvements to the admin dashboard. We also took this opportunity to make some backwards incompatible changes to simplify Linkerd configuration. See the bottom of this post for a [detailed guide](#config-upgrade-guide) on what changes you’ll need to make to your config to upgrade from 0.8.\* to 0.9.0.

You can download Linkerd 0.9.0 from [github](https://github.com/linkerd/linkerd/releases/tag/0.9.0) or find images on [dockerhub](https://hub.docker.com/r/buoyantio/linkerd). To learn about all the great stuff included in 0.9.0, read on!

## ADMIN DASHBOARD IMPROVEMENTS

We’ve added some bar charts and stats to the admin dashboard to give you further visibility into the performance of your services:

- Added a retries stat to the router’s summary, so you can see at a glance if something is wrong with an underlying service, causing Linkerd to retry requests.
- Added a retries bar chart per router which shows the percentage of your configured retry budget that has been used. (The default budget is 20%.)
- Added a client pool health bar, showing the ratio of live endpoints to total endpoints.

We’ve also made some appearance tweaks to make the dashboard easier to consume:

- Clients now have a colored border to make them easier to distinguish.
- Long transformer prefixes have been hidden! To see the full label, click on the client name.
- Collapsing a client will hide it from the top client requests graph.

## SIMPLER LOGICAL NAMES

Naming and [routing](https://linkerd.io/in-depth/routing/) are some of the most complex aspects to configuring Linkerd, especially for new users. To simplify this, we’re changing the default identifier to produce names like `/svc/foo` rather than `/http/1.1/GET/foo`. These shorter names are easier to understand and to write dtabs for.

We recommend updating your dtabs to use the simpler `/svc` style names. If you don’t want to do that immediately, the previous default `io.l5d.methodAndHost` identifier can still be [configured explicitly]({{< relref "linkerd-0-9-0-released" >}}#config-upgrade-guide).

## MORE IDIOMATIC PROMETHEUS METRICS

We’ve done a lot of work to change the Prometheus metrics output to take advantage of Prometheus’s tags, and to better fit Prometheus metrics naming conventions. As part of this change, the `/admin/metrics/prometheus` endpoint is no longer provided by default. To get this endpoint you need to add the [`io.l5d.prometheus` telemeter](https://linkerd.io/config/0.9.0/linkerd/index.html#prometheus) to your config.

### COUNTERS AND GAUGES

Configuration-specific data has moved from metric names to labels. This should minimize the number of metric names while still providing granular breakdowns of metrics across various configurations. For example:

```txt
rt:http:dst:id:_:io_l5d_fs:service1:path:http:1_1:GET:linkerd:4140:requests
```

Becomes:

```txt
rt:dst_id:dst_path:requests{rt="http", dst_id="#/io.l5d.fs/service1", dst_path="svc/linkerd:4140"}
```

### HISTOGRAMS AND SUMMARIES

Prior to 0.9.0, Linkerd exported histograms as collections of gauges with a stat label. Linkerd now exports histograms as Prometheus summaries. For example:

```txt
rt:http:dst:path:http:1_1:GET:linkerd:4140:request_latency_ms{stat="avg"}
rt:http:dst:path:http:1_1:GET:linkerd:4140:request_latency_ms{stat="count"}
rt:http:dst:path:http:1_1:GET:linkerd:4140:request_latency_ms{stat="max"}
rt:http:dst:path:http:1_1:GET:linkerd:4140:request_latency_ms{stat="min"}
rt:http:dst:path:http:1_1:GET:linkerd:4140:request_latency_ms{stat="p50"}
rt:http:dst:path:http:1_1:GET:linkerd:4140:request_latency_ms{stat="p90"}
...
rt:http:dst:path:http:1_1:GET:linkerd:4140:request_latency_ms{stat="stddev"}
rt:http:dst:path:http:1_1:GET:linkerd:4140:request_latency_ms{stat="sum"}
```

Becomes:

```txt
rt:dst_path:request_latency_ms_avg{rt="http", dst_path="svc/linkerd:4140"}
rt:dst_path:request_latency_ms_count{rt="http", dst_path="svc/linkerd:4140"}
rt:dst_path:request_latency_ms_sum{rt="http", dst_path="svc/linkerd:4140"}
rt:dst_path:request_latency_ms{rt="http", dst_path="svc/linkerd:4140", quantile="0"}
rt:dst_path:request_latency_ms{rt="http", dst_path="svc/linkerd:4140", quantile="0.5"}
rt:dst_path:request_latency_ms{rt="http", dst_path="svc/linkerd:4140", quantile="0.9"}
...
rt:dst_path:request_latency_ms{rt="http", dst_path="svc/linkerd:4140", quantile="1"}
```

## USAGE REPORTING

To continue our never-ending quest to improve Linkerd, we need a broad picture of how users are running it. To this end, 0.9.0 includes some basic anonymized usage reporting. We’ve been careful to capture only non-identifying information, and to make it easy for you to disable this feature. Linkerd captures:

- How it is configured (kinds of namers, initializers, identifiers, transformers, protocols, & interpreters used)
- What environments it is running in (OS, orchestrator, etc),
- Performance metrics

It do not capture the labels of namers/routers, designated service addresses or directories, dtabs, or any request or response data. To review the payload reported at any point, visit `:9990/admin/metrics/usage`. To disable reporting, simply set `enabled: false` in your Linkerd config under the top-level `usage:` section:

```yml
usage:
  enabled: false
```

You can also optionally provide an organization ID string that will help us to identify your organization if you so choose:

```yml
usage:
  orgId: my-org
```

## CONFIG UPGRADE GUIDE

Follow these steps to upgrade an 0.8.\* config into one that will work with 0.9.0:

- The `dtabBase` field to has been renamed to just `dtab`.

FROM

```txt
routers:
- protocol: http
  baseDtab: / => /#/io.l5d.k8s/default/http;
```

TO

```txt
routers:
- protocol: http
  dtab: / => /#/io.l5d.k8s/default/http;
```

- The `io.l5d.commonMetrics` telemeter no longer exists and should be removed from configs. Metrics will continue to be served on `/admin/metrics.json` without requiring that they be enabled via the `io.l5d.commonMetrics` telemeter.
- The `tracers` section has been removed in favor of the `telemetry` section. The only tracer that was previously provided was the `io.l5d.zipkin` tracer. That configuration can be moved directly to the `telemetry` section; none of its configuration options have changed.

  FROM

```txt
tracers:
- kind: io.l5d.zipkin
  sampleRate: 1.0
```

TO

```txt
      telemetry:
      - kind: io.l5d.zipkin
        sampleRate: 1.0
```

- The default `dstPrefix` has changed from the protocol name (e.g. `/http`, `/thrift`, etc.) to simply `/svc`. To get the old behavior you'll need to manually set the`dstPrefix` to the protocol name. E.g. `dstPrefix: /http`.Alternatively, update your dtab to expect names starting with `/svc` instead of with the protocol name. E.g. replace `/http/foo => ...` with `/svc/foo => ...`.

- The default HTTP identifier has changed from `io.l5d.methodAndHost` to `io.l5d.header.token`. To get the old behavior you'll need to manually set the identifier to `io.l5d.methodAndHost`. Alternatively, update your dtab to expect names of the form `/svc/<host>` instead of `/http/1.1/<method>/<host>`.See the section above on [Simpler Logical Names](#simpler-logical-names) to learn about the motivation for these two changes.

  FROM

  ```yml
  routers:
    - protocol: http
      baseDtab: |
        /srv      => /#/io.l5d.k8s/default/http;
        /http/*/* => /srv;
  ```

  TO

```yml
routers:
  - protocol: http
    dtab: |
      /srv      => /#/io.l5d.k8s/default/http;
      /svc      => /srv;
```

OR

```yml
routers:
  - protocol: http
    identifier:
      kind: io.l5d.methodAndHost
    dstPrefix: /http
    dtab: |
      /srv      => /#/io.l5d.k8s/default/http;
      /http/*/* => /srv;
```

## THANKS!

Thank you to all of our users, the wonderful Linkerd community, and an extra special thank you to [Borys Pierov](https://twitter.com/Ashald), [Mark Eijsermans](https://twitter.com/markeijsermans), and [Don Petersen](https://github.com/dpetersen) for their contributions to this release.

If you run into any issues whatsoever porting your Linkerd setup to use 0.9.0, don’t hesitate to hop into the [Linkerd community Slack](http://slack.linkerd.io/), and we’ll help you get it sorted out.
