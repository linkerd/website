+++
aliases = ["/administration/telemetry"]
description = "Describes how to handle metrics exported by Linkerd."
title = "Telemetry"
weight = 3
[menu.docs]
parent = "administration"
weight = 38

+++
Linkerd also publishes machine-readable versions of its metrics in multiple
formats. These metrics are designed to be polled by external metrics-collection
utilities and sent to backends such as [Prometheus](https://prometheus.io/),
[InfluxDB](https://www.influxdata.com/), and
[StatsD](https://github.com/etsy/statsd).

All of the collected metrics are available as JSON using the
`/admin/metrics.json` endpoint. For instance if you have Linkerd running
locally, you can run:

```bash
$ curl -s http://localhost:9990/admin/metrics.json?pretty=1 | head -n4
{
  "clnt/zipkin-tracer/available" : 1.0,
  "clnt/zipkin-tracer/cancelled_connects" : 0,
  "clnt/zipkin-tracer/closes" : 294,
  ...
```

Note that the `pretty=1` param is only required for formatting.

To enable additional metrics endpoints, such as Prometheus, InfluxDB, or StatsD,
have a look at the
[Telemetry section of the Linkerd config]({{% linkerdconfig "telemetry" %}}).

## Prometheus

Linkerd provides a metrics endpoint, `/admin/metrics/prometheus`, specifically
for exporting stats to Prometheus. To enable the Prometheus telemeter, add this
to your Linkerd configuration file:

```yaml
telemetry:
- kind: io.l5d.prometheus
```

You can configure Prometheus to collect stats automatically from your Linkerd
instances by using that endpoint as part of your Prometheus scrape config.
For instance:

```yaml
global:
  scrape_interval: 15s
scrape_configs:
  - job_name: 'linkerd'
    metrics_path: /admin/metrics/prometheus
    static_configs:
    - targets:
      - '1.2.3.4:9990'
      - '2.3.4.5:9990'
      - '3.4.5.6:9990'
```

That configuration would scrape metrics from three separate Linkerd instances.

## InfluxDB

Linkerd provides a metrics endpoint, `/admin/metrics/influxdb`, specifically
for exporting stats in InfluxDB LINE protocol. You can configure
[Telegraf](https://github.com/influxdata/telegraf) to automatically collect stats
from your Linkerd instances. Have a look at the
[InfluxDB section of the linkerd-examples repo](https://github.com/linkerd/linkerd-examples/tree/master/influxdb)
for a complete example.

## StatsD

Linkerd supports pushing metrics to a StatsD backend. Simply add a StatsD config
block to your Linkerd configuration file:

```yaml
telemetry:
- kind: io.l5d.statsd
  experimental: true
  prefix: linkerd
  hostname: 127.0.0.1
  port: 8125
  gaugeIntervalMs: 10000
  sampleRate: 0.01
```
