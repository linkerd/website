---
title: Grafana
description: Grafana install instructions and how to link it with the Linkerd Dashboard
---

{{< note >}}
These notes apply only to recent Linkerd Edge releases and the upcoming Linkerd
2.12 stable release, which have stripped off the embedded Grafana instance,
recommending users to install it separately as explained below.

For previous versions, this document does not apply.
{{< /note >}}

Linkerd provides a full [on-cluster metrics stack](../../features/dashboard/)
that can be leveraged by a Prometheus instance and subsequently by a Grafana
instance, in order to show both the real-time and historical behavior of these
metrics.

First, you need to install Grafana from a variety of possible sources, and then
load the suite of Grafana dashboards that have been pre-configured to consume
the metrics exposed by Linkerd.

{{< docs/production-note >}}

## Install Prometheus

Before installing Grafana, make sure you have a working instance of Prometheus
properly configured to consume Linkerd metrics. The Linkerd Viz extension comes
with such a pre-configured Prometheus instance, but you can also [bring your own
Prometheus](../external-prometheus/).

## Install Grafana

The easiest and recommended way is to install Grafana's official Helm chart:

```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm install grafana -n grafana --create-namespace grafana/grafana \
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

It's easy to configure Linkerd Viz dashboard and Grafana such that the former
displays Grafana icons in all the relevant items, providing direct links to the
appropriate Grafana Dashboards. For example, when looking at a list of
deployments for a given namespace, you'll be able to go straight into the
Linkerd Deployments Grafana dashboard providing the same (and more) metrics
(plus their historical behavior).

### In-cluster Grafana instances

In the case of in-cluster Grafana instances (such as as the one from the Grafana
Helm chart or the Grafana Operator mentioned above), make sure a reverse proxy
is set up, as shown in the sample `grafana/values.yaml` file:

```yaml
grafana.ini:
  server:
    root_url: '%(protocol)s://%(domain)s:/grafana/'
```

Then refer the location of your Grafana service in the Linkerd Viz `values.yaml`
entry `grafana.url`. For example, if you installed the Grafana official Helm
chart in the `grafana` namespace, you can install Linkerd Viz through the
command line like so:

```bash
linkerd viz install --set grafana.url=grafana.grafana:3000 \
  | kubectl apply -f -
```

### Off-cluster Grafana instances

If you're using a hosted solution like Grafana Cloud, after having imported the
Linkerd dashboards, you need to enter the full URL of the Grafana service in the
Linkerd Viz `values.yaml` entry `grafana.externalUrl`:

```bash
linkerd viz install --set grafana.externalUrl=https://your-co.grafana.net/ \
  | kubectl apply -f -
```

If that single Grafana instance is pointing to multiple Linkerd installations,
you can segregate the dashboards through different prefixes in their UIDs, which
you would configure in the `grafana.uidPrefix` setting for each Linkerd
instance.
