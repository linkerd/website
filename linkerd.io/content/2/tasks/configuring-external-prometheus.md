+++
title = "Configuring external prometheus instance"
description = "Configure external prometheus to scrape linkerd metrics"
+++

Even though Linkerd comes with its own Prometheus instance, there can be cases
where using a external instance makes more sense for various reasons.
This tutorial shows how to configure a prometheus instance to scrape both
the control plane as well as the proxy's metrics in a format that is consumable
both by a user as well as Linkerd control plane components like web, etc.

## Prometheus Scrape Configuration

For the linkerd-prometheus instance, Prometheus's scrape configuration rules
are used heavily to add additional labels around the Kubernetes information. 

The following scrape configuration has to be applied to the prometheus instance.

{{< note >}}
The below scrape configuration is a subset of [`linkerd-prometheus` scrape configuration](https://github.com/linkerd/linkerd2/blob/main/charts/add-ons/prometheus/templates/prometheus.yaml#L27).
{{< /note >}}

Before applying, It is important to replace templated values(present in `{{}}`)
with direct values for the below configuration to work.

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
