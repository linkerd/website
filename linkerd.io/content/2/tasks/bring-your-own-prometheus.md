+++
title = "Bring your own Prometheus"
description = "Make it easy to use exisiting prometheus with Linkerd"
+++

{{< note >}}
It is strongly advised to use `linkerd-prometheus` instead of using the exisiting
one, to have a good separation of concerns. Things like remote_write, etc can be
configured in the `linkerd-prometheus` to get a global view of metrics as
shown [here](https://linkerd.io/2/tasks/exporting-metrics/)
{{< /note >}}

There are cases where users want to use their own prometheus with Linkerd. With
the new Add-On model in Linkerd, This is possible as Prometheus is not now a required
component.

There are two important points to tackle here.

- Configuring the exisiting prometheus to get the linkerd proxy metrics.
- Configuring the linkerd control plane components to use existing prometheus.

## Prometheus Scrape Configuration

The following configuration has to be present under `scrape-configs` to get the
required metrics from the linkerd proxies

```yaml
    - job_name: 'linkerd-controller'
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

The full prometheus config that you recieve with `linkerd-prometheus` can be
found [here](https://github.com/linkerd/linkerd2/blob/master/charts/linkerd2/templates/prometheus.yaml#L17)

## Control Plane components configuration

As the control plane components like `public-api`, etc depend on
the prometheus instance to power dashboards and CLI,
`global.prometheusUrl` gives you a single place through which all these components
can be configured. This can be done both through Helm and CLI.

### CLI

This is done by passing a file with the above field to `addon-config` field.

```yaml
global:
  prometheusUrl: exisiting-prometheus.xyz:9090/api/prom
```

{{< note >}}
Rather than the plain url of the existing prometheus. The query path of the
instance has to be passed which is usually at `api/prom`
{{</note>}}

This configuration is persistent across upgrades, without having
the user to pass it again. The same can be overwritten as needed.

### Helm

The same configuration can be applied through `values.yaml` when using Helm.
Once applied Helm also makes sure that the configuraiton is
persistent across upgrades.

More information on installation through Helm can be found
[here](https://linkerd.io/2/tasks/install-helm/index.html)

## Troubleshooting

### Linkerd Check tooling
