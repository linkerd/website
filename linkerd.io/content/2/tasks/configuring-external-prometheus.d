+++
title = "Configuring external prometheus instance"
description = "Configure external prometheus to scrape linkerd metrics"
+++

Though Linkerd comes with its own prometheus instance, there can be cases
where a extrnal prometheus instance has to be used for various reasons.
This tutorial shows how to configure a prometheus instance to scrape both
the control-plane as well as the proxy's metrics in a format that is consumable
both by a user as well as Linkerd control-plane components like web, etc.

## Linkerd Scrape Configurations

For the linkerd-prometheus instance, Prometheus's Scrape Config rules are used heavily
to add additional labels around the kubernetes information. 

The following scrape configuration has to be applied to the prometheus instance.

```yaml
    - job_name: 'prometheus'
      static_configs:
      - targets: ['localhost:9090']

    - job_name: 'grafana'
      kubernetes_sd_configs:
      - role: pod
        namespaces:
          names: ['{{.Values.global.namespace}}']
      relabel_configs:
      - source_labels:
        - __meta_kubernetes_pod_container_name
        action: keep
        regex: ^grafana$

    #  Required for: https://grafana.com/grafana/dashboards/315
    - job_name: 'kubernetes-nodes-cadvisor'
      scheme: https
      tls_config:
        ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        insecure_skip_verify: true
      bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
      kubernetes_sd_configs:
      - role: node
      relabel_configs:
      - action: labelmap
        regex: __meta_kubernetes_node_label_(.+)
      - target_label: __address__
        replacement: kubernetes.default.svc:443
      - source_labels: [__meta_kubernetes_node_name]
        regex: (.+)
        target_label: __metrics_path__
        replacement: /api/v1/nodes/$1/proxy/metrics/cadvisor
      metric_relabel_configs:
      - source_labels: [__name__]
        regex: '(container|machine)_(cpu|memory|network|fs)_(.+)'
        action: keep
      - source_labels: [__name__]
        regex: 'container_memory_failures_total' # unneeded large metric
        action: drop

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

It is important to replace templated values(present in `{{}}`) with direct values
for the above configuration to work.