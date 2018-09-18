+++
date = "2018-07-31T12:00:00-07:00"
title = "Prometheus"
description = "Prometheus collects and stores all the Linkerd metrics. It is a component of the control plane and can be integrated with existing metric systems, such as an existing Prometheus install."
aliases = [
  "/2/prometheus/"
]
[menu.l5d2docs]
  name = "Prometheus"
  parent = "observability"
+++

## Exporting Metrics

If you have an existing Prometheus cluster, it is very easy to export Linkerd's
rich telemetry data to your cluster.  Simply add the following item to your
`scrape_configs` in your Prometheus config file (replace `{{.Namespace}}` with
the namespace where Linkerd is running):

```yaml
- job_name: 'linkerd-controller'
  kubernetes_sd_configs:
  - role: pod
    namespaces:
      names: ['{{.Namespace}}']
  relabel_configs:
  - source_labels:
    - __meta_kubernetes_pod_label_linkerd_io_control_plane_component
    - __meta_kubernetes_pod_container_port_name
    action: keep
    regex: (.*);admin-http$
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
    regex: ^linkerd-proxy;linkerd-metrics;{{.Namespace}}$
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
```

That's it!  Your Prometheus cluster is now configured to scrape Linkerd's
metrics.

Linkerd's proxy metrics will have the label `job="linkerd-proxy"`.  Linkerd's
control-plane metrics will have the label `job="linkerd-controller"`.

For more information on specific metric and label definitions, have a look at
[Proxy Metrics](/proxy-metrics),
