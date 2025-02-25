---
title: Bringing your own Prometheus
description: Use an existing Prometheus instance with Linkerd.
---

Even though [the linkerd-viz extension](../../features/dashboard/) comes with
its own Prometheus instance, there can be cases where using an external
instance makes more sense for various reasons.

This tutorial shows how to configure an external Prometheus instance to scrape
both the control plane as well as the proxy's metrics in a format that is
consumable both by a user as well as Linkerd control plane components like
web, etc.

{{< docs/production-note >}}

There are two important points to tackle here.

- Configuring external Prometheus instance to get the Linkerd metrics.
- Configuring the linkerd-viz extension to use that Prometheus.

## Prometheus Scrape Configuration

The following scrape configuration has to be applied to the external
Prometheus instance.

{{< note >}}

The below scrape configuration is a [subset of the full `linkerd-prometheus`
scrape
configuration](https://github.com/linkerd/linkerd2/blob/main/viz/charts/linkerd-viz/templates/prometheus.yaml#L60-L139).

{{< /note >}}

Before applying, it is important to replace templated values (present in
`{{}}`) with direct values for the below configuration to work.

```yaml
    - job_name: 'linkerd-controller'
      kubernetes_sd_configs:
      - role: pod
        namespaces:
          names:
          - '{{.Values.linkerdNamespace}}'
          - '{{.Values.namespace}}'
      relabel_configs:
      - source_labels:
        - __meta_kubernetes_pod_container_port_name
        action: keep
        regex: admin-http
      - source_labels: [__meta_kubernetes_pod_container_name]
        action: replace
        target_label: component

    - job_name: 'linkerd-service-mirror'
      kubernetes_sd_configs:
      - role: pod
      relabel_configs:
      - source_labels:
        - __meta_kubernetes_pod_label_component
        - __meta_kubernetes_pod_container_port_name
        action: keep
        regex: linkerd-service-mirror;admin-http$
      - source_labels: [__meta_kubernetes_pod_container_name]
        action: replace
        target_label: component

    - job_name: 'linkerd-proxy'
      kubernetes_sd_configs:
      - role: pod
      relabel_configs:
      - source_labels:
        - __meta_kubernetes_pod_container_name
        - __meta_kubernetes_pod_container_port_name
        - __meta_kubernetes_pod_label_linkerd_io_control_plane_ns
        action: keep
        regex: ^{{default .Values.proxyContainerName "linkerd-proxy" .Values.proxyContainerName}};linkerd-admin;{{.Values.linkerdNamespace}}$
      - source_labels: [__meta_kubernetes_namespace]
        action: replace
        target_label: namespace
      - source_labels: [__meta_kubernetes_pod_name]
        action: replace
        target_label: pod
      # special case k8s' "job" label, to not interfere with prometheus' "job"
      # label
      # __meta_kubernetes_pod_label_linkerd_io_proxy_job=foo =>
      # k8s_job=foo
      - source_labels: [__meta_kubernetes_pod_label_linkerd_io_proxy_job]
        action: replace
        target_label: k8s_job
      # drop __meta_kubernetes_pod_label_linkerd_io_proxy_job
      - action: labeldrop
        regex: __meta_kubernetes_pod_label_linkerd_io_proxy_job
      # __meta_kubernetes_pod_label_linkerd_io_proxy_deployment=foo =>
      # deployment=foo
      - action: labelmap
        regex: __meta_kubernetes_pod_label_linkerd_io_proxy_(.+)
      # drop all labels that we just made copies of in the previous labelmap
      - action: labeldrop
        regex: __meta_kubernetes_pod_label_linkerd_io_proxy_(.+)
      # __meta_kubernetes_pod_label_linkerd_io_foo=bar =>
      # foo=bar
      - action: labelmap
        regex: __meta_kubernetes_pod_label_linkerd_io_(.+)
      # Copy all pod labels to tmp labels
      - action: labelmap
        regex: __meta_kubernetes_pod_label_(.+)
        replacement: __tmp_pod_label_$1
      # Take `linkerd_io_` prefixed labels and copy them without the prefix
      - action: labelmap
        regex: __tmp_pod_label_linkerd_io_(.+)
        replacement:  __tmp_pod_label_$1
      # Drop the `linkerd_io_` originals
      - action: labeldrop
        regex: __tmp_pod_label_linkerd_io_(.+)
      # Copy tmp labels into real labels
      - action: labelmap
        regex: __tmp_pod_label_(.+)
```

You will also need to ensure that your Prometheus scrape interval is shorter
than the time duration range of any Prometheus queries. In order to ensure the
web dashboard and Linkerd Grafana work correctly, we recommend a 10 second
scrape interval:

```yaml
  global:
    scrape_interval: 10s
    scrape_timeout: 10s
    evaluation_interval: 10s
```

The running configuration of the builtin prometheus can be used as a reference.

```bash
kubectl -n linkerd-viz  get configmap prometheus-config -o yaml
```

## Linkerd-Viz Extension Configuration

Linkerd's viz extension components like `metrics-api`, etc depend on the
Prometheus instance to power the dashboard and CLI.

The `prometheusUrl` field gives you a single place through which all these
components can be configured to an external Prometheus URL. This is allowed
both through Helm and the CLI. If the external Prometheus is secured with
basic auth, you can include the credentials in the URL as well.

### Helm

To configure an external Prometheus instance through Helm, you'll set
`prometheusUrl` in your `values.yaml` file:

```yaml
prometheusUrl: http://existing-prometheus.namespace:9090
```

If the external Prometheus is secured with basic auth, you can include the
credentials in the URL as well.

```yaml
prometheusUrl: http://username:password@existing-prometheus.namespace:9090
```

When using an external Prometheus and configuring the `prometheusUrl` field,
Linkerd's Prometheus will still be included in the installation. If you wish
to disable it, be sure to include the following configuration as well:

```yaml
prometheus:
  enabled: false
```

This configuration is **not** persistent across installs: you'll need to pass
the same `values.yaml` for re-installs, upgrades, etc.

More information on installation through Helm can be found
[here](../install-helm/)

### CLI

When installing using the CLI, you can use the `--values` switch to use the
same `values.yaml` that you would with Helm, or you can set the
`prometheusUrl` directly, for example:

```bash
linkerd viz install \
    --set prometheus.enabled=false \
    --set prometheusUrl=http://existing-prometheus.namespace:9090
```
