+++
date = "2018-07-31T12:00:00-07:00"
title = "Exporting Metrics"
description = "Integrate Linkerd's Prometheus with your existing metrics infrastructure."
aliases = [
  "/2/prometheus/",
  "/2/observability/prometheus/",
  "/2/observability/exporting-metrics/"
]
[menu.l5d2docs]
  name = "Export Metrics"
  parent = "tasks"
+++

By design, Linkerd only keeps metrics data for a short, fixed window of time
(currently, 6 hours). This means that if Linkerd's metrics data is valuable to
you, you will probably want to export it into a full-fledged metrics store.

Internally, Linkerd stores its metrics in a Prometheus instance that runs as
part of the control plane.  There are several basic approaches to exporting
metrics data from Linkerd:

- [Federating data to your own Prometheus cluster](#federation)
- [Using a Prometheus integration](#integration)
- [Extracting data via Prometheus's APIs](#api)
- [Gather data from the proxies directly](#proxy)

# Using the Prometheus federation API {#federation}

If you are using Prometheus as your own metrics store, we recommend taking
advantage of Prometheus's *federation* API, which is designed exactly for the
use case of copying data from one Prometheus to another.

Simply add the following item to your `scrape_configs` in your Prometheus
config file (replace `{{.Namespace}}` with the namespace where Linkerd is
running):

```yaml
- job_name: 'linkerd'
  kubernetes_sd_configs:
  - role: pod
    namespaces:
      names: ['{{.Namespace}}']

  relabel_configs:
  - source_labels:
    - __meta_kubernetes_pod_container_name
    action: keep
    regex: ^prometheus$

  honor_labels: true
  metrics_path: '/federate'

  params:
    'match[]':
      - '{job="linkerd-proxy"}'
      - '{job="linkerd-controller"}'
```

That's it! Your Prometheus cluster is now configured to federate Linkerd's
metrics from Linkerd's internal Prometheus instance.

Once the metrics are in your Prometheus, Linkerd's proxy metrics will have the
label `job="linkerd-proxy"` and Linkerd's control plane metrics will have the
label `job="linkerd-controller"`. For more information on specific metric and
label definitions, have a look at [Proxy Metrics](/2/reference/proxy-metrics/).

For more information on Prometheus' `/federate` endpoint, have a look at the
[Prometheus federation docs](https://prometheus.io/docs/prometheus/latest/federation/).

# Using a Prometheus integration {#integration}

If you are not using Prometheus as your own long-term data store, you may be
able to leverage one of Prometheus's [many
integrations](https://prometheus.io/docs/operating/integrations/) to
automatically extract data from Linkerd's Prometheus instance into the data
store of your choice. Please refer to the Prometheus documentation for details.

# Extracting data via Prometheus's APIs {#api}

If neither Prometheus federation nor Prometheus integrations are options for
you, it is possible to call Prometheus's APIs to extract data from Linkerd.

For example, you can call the federation API directly via a command like:

```bash
curl -G \
  --data-urlencode 'match[]={job="linkerd-proxy"}' \
  --data-urlencode 'match[]={job="linkerd-controller"}' \
  http://prometheus.linkerd.svc.cluster.local:9090/federate
```

Note: if your data store is outside the Kubernetes cluster, it is likely that
you'll want to setup
[ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
at a domain name of your choice with authentication.

Similar to the `/federate` API, Prometheus provides a JSON query API to
retrieve all metrics:

```bash
curl http://prometheus.linkerd.svc.cluster.local:9090/api/v1/query?query=request_total
```

# Gathering data from the Linkerd proxies directly {#proxy}

Finally, if you want to avoid Linkerd's Prometheus entirely, you can query the
Linkerd proxies directly on their `/metrics` endpoint.

For example, to view `/metrics` from a single Linkerd proxy, running in the
`linkerd` namespace:

```bash
kubectl -n linkerd port-forward \
  $(kubectl -n linkerd get pods \
    -l linkerd.io/control-plane-ns=linkerd \
    -o jsonpath='{.items[0].metadata.name}') \
  4191:4191
```

and then:

```bash
curl localhost:4191/metrics
```
