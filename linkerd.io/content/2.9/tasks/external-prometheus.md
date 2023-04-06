+++
title = "Bringing your own Prometheus"
description = "Use an existing Prometheus instance with Linkerd."
+++

Even though Linkerd comes with its own Prometheus instance, there can be cases
where using an external instance makes more sense for various reasons.

{{< note >}}
Note that this approach requires you to manually add and maintain additional
scrape configuration in your Prometheus configuration.
If you prefer to use the default Linkerd Prometheus add-on,
you can export the metrics to your existing monitoring infrastructure
following [these instructions](../exporting-metrics/).
{{< /note >}}

This tutorial shows how to configure an external Prometheus instance to scrape both
the control plane as well as the proxy's metrics in a format that is consumable
both by a user as well as Linkerd control plane components like web, etc.

{{< trylpt >}}

There are two important points to tackle here.

- Configuring external Prometheus instance to get the Linkerd metrics.
- Configuring the Linkerd control plane components to use that Prometheus.

## Prometheus Scrape Configuration

The following scrape configuration has to be applied to the external
Prometheus instance.

{{< note >}}
The below scrape configuration is a [subset of `linkerd-prometheus` scrape configuration](https://github.com/linkerd/linkerd2/blob/a1be60aea183efe12adba8c97fadcdb95cdcbd36/charts/add-ons/prometheus/templates/prometheus.yaml#L69-L147).
{{< /note >}}

Before applying, it is important to replace templated values (present in `{{}}`)
with direct values for the below configuration to work.

```yaml
    - job_name: 'linkerd-controller'

      scrape_interval: 10s
      scrape_timeout: 10s

      kubernetes_sd_configs:
      - role: pod
        namespaces:
          names: ['{{.Values.global.namespace}}']
      relabel_configs:
      - source_labels:
        - __meta_kubernetes_pod_label_linkerd_io_control_plane_component
        - __meta_kubernetes_pod_container_port_name
        action: keep
        regex: (.*);admin-http$
      - source_labels: [__meta_kubernetes_pod_container_name]
        action: replace
        target_label: component

    - job_name: 'linkerd-service-mirror'

      scrape_interval: 10s
      scrape_timeout: 10s

      kubernetes_sd_configs:
      - role: pod
      relabel_configs:
      - source_labels:
        - __meta_kubernetes_pod_label_linkerd_io_control_plane_component
        - __meta_kubernetes_pod_container_port_name
        action: keep
        regex: linkerd-service-mirror;admin-http$
      - source_labels: [__meta_kubernetes_pod_container_name]
        action: replace
        target_label: component

    - job_name: 'linkerd-proxy'

      scrape_interval: 10s
      scrape_timeout: 10s

      kubernetes_sd_configs:
      - role: pod
      relabel_configs:
      - source_labels:
        - __meta_kubernetes_pod_container_name
        - __meta_kubernetes_pod_container_port_name
        - __meta_kubernetes_pod_label_linkerd_io_control_plane_ns
        action: keep
        regex: ^{{default .Values.global.proxyContainerName "linkerd-proxy" .Values.global.proxyContainerName}};linkerd-admin;{{.Values.global.namespace}}$
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

The running configuration of the builtin prometheus can be used as a reference.

```bash
kubectl -n linkerd  get configmap linkerd-prometheus-config -o yaml
```

## Control Plane Components Configuration

Linkerd's control plane components like `public-api`, etc depend
on the Prometheus instance to power the dashboard and CLI.

The `global.prometheusUrl` field gives you a single place through
which all these components can be configured to an external Prometheus URL.
This is allowed both through the CLI and Helm.

### CLI

This can be done by passing a file with the above field to the `config` flag,
which is available both through `linkerd install` and `linkerd upgrade` commands

```yaml
global:
  prometheusUrl: existing-prometheus.xyz:9090
```

Once applied, this configuration is persistent across upgrades, without having
the user passing it again. The same can be overwritten as needed.

When using an external Prometheus and configuring the `global.prometheusUrl`
field, Linkerd's Prometheus will still be included in installation.

If you wish to disable this included Prometheus, be sure to include the
following configuration as well:

```yaml
prometheus:
  enabled: false
```

### Helm

The same configuration can be applied through `values.yaml` when using Helm.
Once applied, Helm makes sure that the configuration is
persistent across upgrades.

More information on installation through Helm can be found
[here](../install-helm/)
