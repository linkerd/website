+++
title = "Grafana"
description = "Grafana install instructions and how to link it with the Linkerd Dashboard"
+++

Linkerd provides a full [on-cluster metrics stack](../../features/dashboard/)
that can be leveraged by a Prometheus instance and subsequently by a Grafana
instance, in order to show both the real-time and historical behavior of these
metrics.

First, you need to install Grafana from a variety of possible sources, and then
load the suite of Grafana dashboards that have been pre-configured to consume
the metrics exposed by Linkerd.

## Install Prometheus

Before installing Grafana, make sure you have a working instance of Prometheus
properly configured to consume Linkerd metrics. The Linkerd Viz extension comes
with such a pre-configured Prometheus instance, but you can also [bring your own
Prometheus](../external-prometheus/).

## Install Grafana

The easiest and recommended way is to install Grafana's official Helm chart:

```bash
helm repo add grafana https://grafana.github.io/helm-charts helm install
grafana -n grafana --create-namespace grafana/grafana \
  -f https://raw.githubusercontent.com/linkerd/linkerd2/main/grafana/values.yaml
```

This is fed the default `values.yaml` file, which configures as a default
datasource Linkerd Viz' Prometheus instance, sets up a reverse proxy (more on
that later), and pre-loads all the Linkerd Grafana dashboards that are published
on <https://grafana.com/orgs/linkerd>.

A more complex and production-oriented source is the [Grafana
Operator](https://github.com/grafana-operator/grafana-operator). And there are
also hosted solutions such as [Grafana
Cloud](https://grafana.com/products/cloud/). Those projects provide instructions
on how to easily import the same charts published on
<https://grafana.com/orgs/linkerd>.

## Hook Grafana with Linkerd Viz Dashboard

In the case of in-cluster Grafana instances (such as as the one from the Grafana
Helm chart or the Grafana Operator mentioned above), you can configure them so
that the Linkerd Viz Dashboard will show Grafana Icons in all the relevant items
to provide direct links to the appropriate Grafana Dashboards. For example, when
looking at a list of deployments for a given namespace, you'll be able to go
straight into the Grafana Dashboard providing the same (and more) metrics (plus
their historical behavior) in the Linkerd Deployments Grafana Dashboard.

In order to enable this, just make sure a reverse proxy is set up, as shown in
the sample `grafana/values.yaml` file:

```yaml
grafana.ini:
  server:
    root_url: '%(protocol)s://%(domain)s:/grafana/'
```

And finally, refer the location of your Grafana service in the Linkerd Viz
`values.yaml` entry `grafana.url`. For example, if you installed the Grafana
offical Helm chart in the `grafana` namespace, you can install Linkerd Viz
through the command line like so:

```bash
linkerd viz install --set grafana.url=grafana.grafana:300 \
  | kubectl apply -f -
```
