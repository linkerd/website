+++
title = "Dashboard and on-cluster metrics stack"
description = "Linkerd provides a full on-cluster metrics stack, including CLI tools and dashboards."
+++

Linkerd provides a full on-cluster metrics stack, including CLI tools and a web
dashboard.

To access this functionality, install the viz extension:

```bash
linkerd viz install | kubectl apply -f -
```

This extension installs the following components into your `linkerd-viz`
namespace:

* A [Prometheus](https://prometheus.io/) instance
* metrics-api, tap, tap-injector, and web components

These components work together to provide an on-cluster metrics stack.

{{< note >}}
To limit excessive resource usage on the cluster, the metrics stored by this
extension are _transient_. Only the past 6 hours are stored, and metrics do not
persist in the event of pod restart or node outages. This may not be suitable
for production use.
{{< /note >}}

{{< note >}}
This metrics stack may require significant cluster resources. Prometheus, in
particular, will consume resources as a function of traffic volume within the
cluster.
{{< /note >}}

## Linkerd dashboard

The Linkerd dashboard provides a high level view of what is happening with your
services in real time. It can be used to view "golden metrics" (success rate,
requests/second and latency), visualize service dependencies and understand the
health of specific service routes.

One way to pull it up is by running `linkerd viz dashboard` from the command
line.

{{< fig src="/images/architecture/stat.png" title="Top Line Metrics">}}

## Grafana

In earlier versions of Linkerd, the viz extension also pre-installed a Grafana
dashboard. As of Linkerd 2.12, due to licensing changes in Grafana, this is no
longer the case. However, you can still install Grafana on your own—see the
[Grafana docs](../../tasks/grafana/) for instructions on how to create the
Grafana dashboards.

## Examples

In these examples, we assume you've installed the emojivoto example application.
Please refer to the [Getting Started Guide](../../getting-started/) for how to
do this.

You can use your dashboard extension and see all the services in the demo app.
Since the demo app comes with a load generator, we can see live traffic metrics
by running:

```bash
linkerd -n emojivoto viz stat deploy
```

This will show the "golden" metrics for each deployment:

* Success rates
* Request rates
* Latency distribution percentiles

To dig in a little further, it is possible to use `top` to get a real-time
view of which paths are being called:

```bash
linkerd -n emojivoto viz top deploy
```

To go even deeper, we can use `tap` shows the stream of requests across a
single pod, deployment, or even everything in the emojivoto namespace:

```bash
linkerd -n emojivoto viz tap deploy/web
```

All of this functionality is also available in the dashboard, if you would like
to use your browser instead:

{{< gallery >}}

{{< gallery-item src="/images/getting-started/stat.png"
    title="Top Line Metrics">}}

{{< gallery-item src="/images/getting-started/inbound-outbound.png"
    title="Deployment Detail">}}

{{< gallery-item src="/images/getting-started/top.png"
    title="Top" >}}

{{< gallery-item src="/images/getting-started/tap.png"
    title="Tap" >}}

{{< /gallery >}}

## Futher reading

See [Exporting metrics](../../tasks/exporting-metrics/) for alternative ways
to consume Linkerd's metrics.
