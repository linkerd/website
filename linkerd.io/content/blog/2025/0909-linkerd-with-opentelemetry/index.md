---
date: 2025-09-09T00:00:00Z
slug: linkerd-with-opentelemetry
title: |-
  Beyond linkerd-viz: Linkerd Metrics with OpenTelemetry
keywords: [linkerd, opentelemetry, otel]
params:
  author:
    name: Eli Goldberg, Linkerd Ambassador
    avatar: eli-goldberg.jpg
  showCover: true
images: [social.jpg] # Open graph image
---

## TL;DR

Linkerd, the enterprise-grade service mesh that minimizes overhead, now
integrates with [OpenTelemetry](https://opentelemetry.io/), often also simply
called OTel. That's pretty cool because it allows you to collect and export
Linkerd's metrics to your favorite observability tools. This integration
improves your ability to monitor and troubleshoot applications effectively.
Sounds interesting? Read on.

Before we dive into this topic, I want to be sure you have a basic understanding
of Kubernetes. If you're new to it, that's ok! But I'd recommend exploring the
official Kubernetes tutorials and/or experimenting with "Kind" (Kubernetes in
Docker) with
[this simple guide](https://kind.sigs.k8s.io/docs/user/quick-start/).

## What's "Linkerd"?

Ok, let's start with the basics. Linkerd is a free and open source service mesh
built in Rust—a modern programming language known for its memory safety. Simply
put, a service mesh injects a proxy in a sidecar next to each container (in any
relevant Kubernetes Pod), providing encryption (mutual TLS, or mTLS) and
improved observability and reliability. A common use case is load balancing
(that's how Linkerd got on my radar). If your Kubernetes app communicates via
[gRPC](https://grpc.io/), requests aren't automatically distributed among the
gRPC server pods—a capability Kubernetes doesn't provide. Linkerd closes that
gap effectively, but that's not the topic of this blog post. If you're
interested in learning more about that, check out the
[gRPC Load Balancing on Kubernetes without Tears](/2018/11/14/grpc-load-balancing-on-kubernetes-without-tears/)
blog post. Now back to OpenTelemetry.

## Linkerd's observability extension - linkerd-viz

Linkerd has the linkerd-viz extension with a dashboard showing valuable metrics
such as request/response errors, latency, and traffic volumes. This data is
scraped from various pods and the Linkerd proxies running within them by a
Prometheus instance included with the linkerd-viz extension.

On the other hand, the Prometheus instance supplied by linkerd-viz isn't at all
appropriate for production use. Also, while Prometheus is effective for storing
and scraping telemetry data, many organizations prefer to centralize their data
in Application Performance Monitoring (APM) platforms like Datadog, New Relic,
or Coralogix. This means that instead of storing their observability data on
Prometheus, they delegate the responsibility to a 3rd-party solution or vendor,
and to achieve that, they often use OpenTelemetry.

## Cool! So, what's OpenTelemetry?

[OpenTelemetry](https://opentelemetry.io/) is another CNCF project. It's an open
source observability framework that provides standardized protocols and tools
for collecting and routing telemetry data, including logs, metrics, and traces.
While there are many projects used for storing or viewing telemetry, OTel has
become the de facto standard for collecting telemetry data. To learn more about
the project, check out the
[A Complete Introductory Guide to OpenTelemetry](https://betterstack.com/community/guides/observability/what-is-opentelemetry/)
blog post.

OpenTelemetry defines four separate kinds of telemetry components:

- **Receivers** collect data from your application.
- **Processors** transform received data according to rules you define.
- **Exporters** send processed data to your APM.
- Finally, **pipelines** define the overall flow from receivers to processors to
  exporters.

What makes OpenTelemetry so powerful is the vast amount of integrations it has.
The core distribution of the “otel-collector” comes with a few basic supported
receivers, processors and exporters, but you can also switch to the
[community distribution](https://github.com/open-telemetry/opentelemetry-collector-contrib),
which comes with a ton of different integrations.

For this blog post, we'll send those metrics to
[**OpenObserve**](https://openobserve.ai/), a lightweight, open source
observability platform that you can actually run entirely in your cluster, but
feel free to use your favorite APM/observability solution of choice. We'll also
sidestep any questions about linkerd-viz and Prometheus by setting things up to
scrape metrics from Linkerd proxies directly into OpenObserve—that way we don't
have to rely on linkerd-viz at all!

Ok, let's roll up our sleeves and get started.

## Installing OpenObserve

Start by installing OpenObserve by running this command:

```sh
helm repo add openobserve https://charts.openobserve.ai
helm repo update

helm install --wait --create-namespace -n openobserve \
  openobserve openobserve/openobserve-standalone
```

After a few seconds, you'll be able to port forward to the UI:

```sh
kubectl port-forward -n openobserve \
  svc/openobserve-openobserve-standalone 5080:5080
```

Browse to localhost:5080 and use the default credentials to login:

**User**: root&#64;example.com  
**Password**: Complexpass#123

And you're in!

## Installing Linkerd

Installing Linkerd is pretty straightforward. Just follow the
[Getting Started Guide](/2/getting-started/), and you'll have Linkerd running in
~2–5 minutes; you can skip the linkerd-viz part—we won't need that.

Next, inject Linkerd into your workloads (Deployments) by running (use the next
command to inject it into an entire namespace):

```sh
# Inject Linkerd into a specific deployment
kubectl get -n <YOUR_NAMESPACE> deploy/<DEPLOYMENT_NAME> -o yaml \
 | linkerd inject - \
 | kubectl apply -f -
```

Or inject Linkerd into an entire namespace with:

```sh
kubectl get ns <YOUR_NAMESPACE> -o yaml \
 | linkerd inject - \
 | kubectl apply -f -
```

Followed by a restart to all workloads in that namespace

```sh
kubectl rollout restart deployment -n <YOUR_NAMESPACE>
kubectl rollout status deployment -n <YOUR_NAMESPACE>
```

If you follow the guide, you should have Linkerd sidecars injected into your
workloads. The easiest way to verify this, is to just run:

```sh
kubectl get pods
```

You should see 2 containers in each pod (Ready: 2/2).

## Configuring OTel

The following YAMLs deploy a basic otel-collector pipeline, configured to scrape
any Linkerd control-plane or data-plane pods—let's break those down.

First we need to create a Namespace in which the otel-collector will run. Then
we'll create a ClusterRole and ClusterRoleBinding that give the "otel-collector"
ServiceAccount permissions to list Kubernetes workloads that match certain
labels.

This lets otel-collector discover the different pods running with the linkerd
sidecars injected.

We will then attach this ServiceAccount to the "otel-collector" deployment.

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: observability
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: otel-collector
  namespace: observability
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: otel-collector-read
rules:
  - apiGroups: [""]
    resources: ["pods", "endpoints", "services", "namespaces", "nodes"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: otel-collector-read
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: otel-collector-read
subjects:
  - kind: ServiceAccount
    name: otel-collector
    namespace: observability
```

Next, we'll create a ConfigMap configuring otel-collector to scrape
Linkerd-related pods for the metrics we want using a Prometheus receiver, an
OTLP (OTel Protocol) exporter that sends data into OpenObserve, and a pipeline
that links the two together. (We don't define any processors since we don't need
to do any processing.)

```yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: otel-collector-config
  namespace: observability
  labels:
    app: otel-collector
data:
  config.yaml: |
    receivers:
      prometheus/linkerd:
        config:
          global:
            evaluation_interval: 10s
            scrape_interval: 10s
            scrape_timeout: 10s
          scrape_configs:
            - job_name: 'linkerd-controller'
              kubernetes_sd_configs:
              - role: pod
                namespaces:
                  names:
                  - 'linkerd'
                  - 'linkerd-viz'
              relabel_configs:
              - source_labels:
                - __meta_kubernetes_pod_container_port_name
                action: keep
                regex: admin
              - source_labels: [__meta_kubernetes_pod_container_name]
                action: replace
                target_label: component


            - job_name: 'linkerd-multicluster-controller'
              kubernetes_sd_configs:
              - role: pod
              relabel_configs:
              - source_labels:
                - __meta_kubernetes_pod_label_component
                - __meta_kubernetes_pod_container_port_name
                action: keep
                regex: (linkerd-service-mirror|controller);admin$
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
                regex: ^linkerd-proxy;linkerd-admin;linkerd$
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


    exporters:
      otlp/openobserve:
        endpoint: openobserve-openobserve-standalone.openobserve.svc.cluster.local:5081
        headers:
          Authorization: "Basic cm9vdEBleGFtcGxlLmNvbTpDb21wbGV4cGFzcyMxMjM="
          organization: default
          stream-name: default
        tls:
          insecure: true
      debug:
        verbosity: detailed


    service:
      pipelines:
        metrics:
          receivers: [prometheus/linkerd]
          exporters: [debug,otlp/openobserve]
```

Finally, we'll add the otel-collector Deployment with the attached
ServiceAccount and the ConfigMap we've defined above.

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: otel-collector
  namespace: observability
  labels:
    app: otel-collector
spec:
  replicas: 1
  selector:
    matchLabels:
      app: otel-collector
  template:
    metadata:
      labels:
        app: otel-collector
    spec:
      serviceAccountName: otel-collector
      containers:
        - name: otel-collector
          image: otel/opentelemetry-collector:latest
          args: ["--config=/etc/otelcol/config.yaml"]
          volumeMounts:
            - name: otel-config
              mountPath: /etc/otelcol
              readOnly: true
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 500m
              memory: 256Mi
          securityContext:
            runAsNonRoot: true
            allowPrivilegeEscalation: false
      volumes:
        - name: otel-config
          configMap:
            name: otel-collector-config
            items:
              - key: config.yaml
                path: config.yaml
```

Note the exporter -

```yaml
exporters:
  otlp/openobserve:
    endpoint: openobserve-openobserve-standalone.openobserve.svc.cluster.local:5081
    headers:
      Authorization: "Basic cm9vdEBleGFtcGxlLmNvbTpDb21wbGV4cGFzcyMxMjM="
      organization: default
      stream-name: default
    tls:
      insecure: true
  debug:
    verbosity: detailed
```

The token:

```yaml
Authorization: "Basic cm9vdEBleGFtcGxlLmNvbTpDb21wbGV4cGFzcyMxMjM="
```

Is just base64 encoding of the default username and password we used above.

Let's apply the YAML by running:

```sh
kubectl apply -f otel-collector.yaml
```

That's it!

The otel-collector should be up and collecting metrics from Linkerd and sending
them to OpenObserve. Head over to:
[http://localhost:5080/web/metrics](http://localhost:5080/web/metrics). You
should see Linkerd's metrics appear in OpenObserve. If you need to troubleshoot,
check out otel-collector's logs to see if any errors appear.

You can view the source code and a general guide to the above in its GitHub repo
at
[https://github.com/Eli-Goldberg/linkerd-otel](https://github.com/Eli-Goldberg/linkerd-otel).

Linkerd has a ton of valuable information, such as **Volumes**, **Success
Rates,** and **Latency** within those metrics. A lot of DevOps/Platform/SRE
teams build their dashboards using their favorite APM/observability solution
(mostly paid ones), especially when part of a large company. This demonstrates
how you can get Linkerd's metrics and ingest them in your favorite solution.

## Bonus: Linkerd's Auth policy

Linkerd comes with a handy feature called
[Authorization Policies](/2/reference/authorization-policy/). With it, you can
enable or prevent workloads from talking to each other (think firewall) based on
different parameters. For example, which services, meshed or unmeshed, on the
same or separate clusters, which port is being used, etc.?

It's worth noting that right now, all the data is visible to anyone in the
cluster, which isn't great in many cases. In production, you might want to
secure access to those metrics and allow it exclusively from otel-collector.

Stay tuned for my next post about using Linkerd authorization policies to fix
that.
