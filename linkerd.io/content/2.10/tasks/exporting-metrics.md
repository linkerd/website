+++
title = "Exporting Metrics"
description = "Integrate Linkerd's Prometheus with your existing metrics infrastructure."
aliases = [
  "../prometheus/",
  "../observability/prometheus/",
  "../observability/exporting-metrics/"
]
+++

By design, Linkerd only keeps metrics data for a short, fixed window of time
(currently, 6 hours). This means that if Linkerd's metrics data is valuable to
you, you will probably want to export it into a full-fledged metrics store.

Internally, Linkerd stores its metrics in a Prometheus instance that runs as
part of the Viz extension. The following tutorial requires the viz extension
to be installed with prometheus enabled. There are several basic approaches
to exporting metrics data from Linkerd:

- [Federating data to your own Prometheus cluster](#federation)
- [Using a Prometheus integration](#integration)
- [Extracting data via Prometheus's APIs](#api)
- [Gather data from the proxies directly](#proxy)

Additionally, it is possible to use the ability to deploy a sidecar container
inside the linkerd-prometheus pod to run any tool capable of exporting data
from Prometheus:

- [Exporting data to Google Cloud Monitoring](#stackdriver)

## Using the Prometheus federation API {#federation}

If you are using Prometheus as your own metrics store, we recommend taking
advantage of Prometheus's *federation* API, which is designed exactly for the
use case of copying data from one Prometheus to another.

Simply add the following item to your `scrape_configs` in your Prometheus config
file (replace `{{.Namespace}}` with the namespace where the Linkerd Viz
extension is running):

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

Alternatively, if you prefer to use Prometheus' ServiceMonitors to configure
your Prometheus, you can use this ServiceMonitor YAML (replace `{{.Namespace}}`
with the namespace where Linkerd Viz extension is running):

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  labels:
    k8s-app: linkerd-prometheus
    release: monitoring
  name: linkerd-federate
  namespace: {{.Namespace}}
spec:
  endpoints:
  - interval: 30s
    scrapeTimeout: 30s
    params:
      match[]:
      - '{job="linkerd-proxy"}'
      - '{job="linkerd-controller"}'
    path: /federate
    port: admin-http
    honorLabels: true
    relabelings:
    - action: keep
      regex: '^prometheus$'
      sourceLabels:
      - '__meta_kubernetes_pod_container_name'
  jobLabel: app
  namespaceSelector:
    matchNames:
    - {{.Namespace}}
  selector:
    matchLabels:
      component: prometheus
```

That's it! Your Prometheus cluster is now configured to federate Linkerd's
metrics from Linkerd's internal Prometheus instance.

Once the metrics are in your Prometheus, Linkerd's proxy metrics will have the
label `job="linkerd-proxy"` and Linkerd's control plane metrics will have the
label `job="linkerd-controller"`. For more information on specific metric and
label definitions, have a look at [Proxy Metrics](../../reference/proxy-metrics/).

For more information on Prometheus' `/federate` endpoint, have a look at the
[Prometheus federation docs](https://prometheus.io/docs/prometheus/latest/federation/).

## Using a Prometheus integration {#integration}

If you are not using Prometheus as your own long-term data store, you may be
able to leverage one of Prometheus's [many
integrations](https://prometheus.io/docs/operating/integrations/) to
automatically extract data from Linkerd's Prometheus instance into the data
store of your choice. Please refer to the Prometheus documentation for details.

## Extracting data via Prometheus's APIs {#api}

If neither Prometheus federation nor Prometheus integrations are options for
you, it is possible to call Prometheus's APIs to extract data from Linkerd.

For example, you can call the federation API directly via a command like:

```bash
curl -G \
  --data-urlencode 'match[]={job="linkerd-proxy"}' \
  --data-urlencode 'match[]={job="linkerd-controller"}' \
  http://prometheus.linkerd-viz.svc.cluster.local:9090/federate
```

{{< note >}}
If your data store is outside the Kubernetes cluster, it is likely that
you'll want to set up
[ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
at a domain name of your choice with authentication.
{{< /note >}}

Similar to the `/federate` API, Prometheus provides a JSON query API to
retrieve all metrics:

```bash
curl http://prometheus.linkerd-viz.svc.cluster.local:9090/api/v1/query?query=request_total
```

## Gathering data from the Linkerd proxies directly {#proxy}

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

Alternatively, `linkerd diagnostics proxy-metrics` can be used to retrieve
proxy metrics for a given workload.

## Exporting data to Google Cloud Monitoring {#stackdriver}

Google's engineering team provide a
[stackdriver-prometheus-sidecar](https://github.com/Stackdriver/stackdriver-prometheus-sidecar)
tool that directly reads the Prometheus write-ahead log and forwards selected
metrics to [Google Cloud Monitoring](https://cloud.google.com/monitoring)
(formerly known as Stackdriver).  With a bit of elbow grease, you can use it to
get many of Linkerd's internal metrics visible in your Google dashboards, which
is extremely useful (a) for dashboard centralization, and (b) if you want to
use Linkerd metrics to drive [Google Service Monitoring
SLOs](https://cloud.google.com/stackdriver/docs/solutions/slo-monitoring).

Unfortunately, a set of interlocking limitations in both the sidecar tool and
the Google Cloud Monitoring API make this somewhat less than a plug-and-play
process:

- the sidecar cannot directly translate and forward Prometheus
  [histogram](https://prometheus.io/docs/practices/histograms/) metrics to GCM
  [distribution](https://cloud.google.com/monitoring/charts/charting-distribution-metrics)
  metrics. So if you want to, for example, forward the 50th and 90th percentile
  latencies for a linkerd service, you will need to set up Prometheus
  [recording rules](https://prometheus.io/docs/prometheus/latest/configuration/recording_rules/)
  to extract the metrics from the histogram using the
  [histogram\_quantile](https://prometheus.io/docs/prometheus/latest/querying/functions/#histogram_quantile)
  function.
- the sidecar requires that you use the [default naming
  format](https://prometheus.io/docs/practices/rules/#naming-and-aggregation)
  when defining recording rules, e.g. `linkerd_job:svc_latency_ms:p50_30s`
- but `:` characters are [not valid](https://cloud.google.com/monitoring/api/v3/naming-conventions#naming-types-and-labels)
  in Google Cloud Monitoring metric descriptors, so you need to use the sidecar's
  ability to [rename](https://github.com/Stackdriver/stackdriver-prometheus-sidecar#file)
  metrics en route to Google.

Luckily all of these issues can be dealt with, they just require that there be
a number of moving parts in play here.

The instructions from here on in assume that you are using
[helm](https://linkerd.io/2.10/tasks/install-helm/) to install linkerd-viz; if
you are using Kustomize it should be reasonably straightforward to produce a
similar result.

### Create the sidecar container {#sidecar_container}

Google does not provide a public docker image for the sidecar, so you will need
to build your own.  Luckily, it's reasonably straightforward:

```dockerfile
ARG GO_VERSION=1.17
ARG RUN_IMAGE_BASE="gcr.io/distroless/static:latest"
FROM --platform=linux/amd64 golang:${GO_VERSION} as build
ARG SIDECAR_VERSION=0.10.1
WORKDIR /src
RUN git clone https://github.com/Stackdriver/stackdriver-prometheus-sidecar.git
WORKDIR /src/stackdriver-prometheus-sidecar
RUN git checkout $SIDECAR_VERSION
RUN make build

FROM --platform=linux/amd64 $RUN_IMAGE_BASE
COPY --from=build /src/stackdriver-prometheus-sidecar/stackdriver-prometheus-sidecar /bin/stackdriver-prometheus-sidecar
EXPOSE 9091
ENTRYPOINT ["/bin/stackdriver-prometheus-sidecar"]
```

(Note that when you are initially installing and debugging, it might be
helpful to set `RUN_IMAGE_BASE` to something with a shell, e.g. `alpine`
or `busybox`.)

Build and push that image to your project's [Google Container
Registry](https://cloud.google.com/container-registry) e.g.
`gcr.io/${GCP_PROJECT}/stackdriver-prometheus-sidecar:0.10.1`.

Once you've got the container available, you need to set it up to run alongside
the `linkerd-prometheus` container in the `linkerd-viz` namespace.

### Create a recording_rules.yml as a configmap {#sidecar_recording_rules}

This is the file where we will extract simple gauge metrics from the
[histograms](https://prometheus.io/docs/practices/histograms/) that Linkerd
uses to store service latency data.

Note that in this example we are creating four gauge metrics: the 50th and 99th
percentile, as averaged over 30 and 300 seconds.  Depending on your particular
needs you may want to adjust this.

```bash
$ kubectl --namespace=linkerd-viz create -f- <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: linkerd-prometheus-recording-rules
  namespace: linkerd-viz
data:
  recording_rules.yml: |
    groups:
    - name: service_aggregations
      rules:
      # warning: you _must_ export minimally an 'instance' and 'job' label, otherwise the
      # sidecar will drop it on the floor; see long and ugly discussion culminating at
      # https://github.com/Stackdriver/stackdriver-prometheus-sidecar/issues/104#issuecomment-529595575
      - record: linkerd_job:svc_response_rate_30s:sum
        expr: sum(rate(response_total{namespace="default", direction="outbound", dst_service=~".+", status_code=~".+"}[30s])) by (dst_service, instance, job, status_code)
      - record: linkerd_job:svc_latency_ms:p50_30s
        expr: histogram_quantile(0.50, sum(rate(response_latency_ms_bucket{namespace="default", direction="outbound", dst_service=~".+"}[30s])) by (le, dst_service, instance, job))
      - record: linkerd_job:svc_latency_ms:p99_30s
        expr: histogram_quantile(0.99, sum(rate(response_latency_ms_bucket{namespace="default", direction="outbound", dst_service=~".+"}[30s])) by (le, dst_service, instance, job))
      - record: linkerd_job:svc_latency_ms:p50_300s
        expr: histogram_quantile(0.50, sum(rate(response_latency_ms_bucket{namespace="default", direction="outbound", dst_service=~".+"}[300s])) by (le, dst_service, instance, job))
      - record: linkerd_job:svc_latency_ms:p99_300s
        expr: histogram_quantile(0.99, sum(rate(response_latency_ms_bucket{namespace="default", direction="outbound", dst_service=~".+"}[300s])) by (le, dst_service, instance, job))
      # warning: because we are exporting a COUNTER metric here, you _must_ sum by all
      # fields that, if they change, implicitly reset the counter (although you can elide
      # fields which change in lockstep e.g. "pod_template_hash" with "pod"), otherwise you will
      # export a "counter" that potentially resets to random numbers: stackdriver will sorta cope
      # but Service Monitoring will have a cow.
      - record: linkerd_job:response_total:sum
        expr: sum(response_total{namespace="default", direction="inbound"}) by (app, pod, instance, job, classification, status_code)
```

### Create a sidecar.yml as a configmap {#sidecar_config}

`sidecar.yml` is the [configuration
file](https://github.com/Stackdriver/stackdriver-prometheus-sidecar#file) for
the sidecar process: you use it to rename metrics and to statically set metric
types when necessary.

Note that here is where we rename our Prometheus recorded metrics from the
Prometheus-style `level:metric:operations` format that the sidecar requires, to
a value that Google Cloud Monitoring will accept as a [valid metric
name](https://cloud.google.com/monitoring/api/v3/naming-conventions#naming-types-and-labels).

```bash
$ kubectl --namespace=linkerd-viz create -f- <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: linkerd-prometheus-sidecar-config
  namespace: linkerd-viz
data:
  sidecar.yml: |
    #
    # this is the configuration file for the stackdriver-prometheus-sidecar container:
    # https://github.com/Stackdriver/stackdriver-prometheus-sidecar#file
    #
    # rename all recorded metrics to valid GCM metric descriptors
    metric_renames:
    - from: linkerd_job:svc_response_rate_30s:sum
      to: recorded_svc_response_rate_30s
    - from: linkerd_job:svc_latency_ms:p50_30s
      to: recorded_svc_latency_ms_p50_30s
    - from: linkerd_job:svc_latency_ms:p99_30s
      to: recorded_svc_latency_ms_p99_30s
    - from: linkerd_job:svc_latency_ms:p50_300s
      to: recorded_svc_latency_ms_p50_300s
    - from: linkerd_job:svc_latency_ms:p99_300s
      to: recorded_svc_latency_ms_p99_300s
    - from: linkerd_job:response_total:sum
      to: recorded_svc_response_cumulative
    # force the export of our recorded Prometheus COUNTER metrics
    # as GCM CUMULATIVE metrics with a `double` value. (This does not
    # seem to reliably happen automatically.)
    static_metadata:
    - metric: recorded_svc_response_cumulative
      type: counter
      value_type: double
      help: aggregated response totals to each linkerd service
    - metric: linkerd_job:response_total:sum
      type: counter
      value_type: double
      help: aggregated response totals to each linkerd service
EOF
```

### Add the sidecar and the configmaps to the linkerd-prometheus pod {#sidecar_deploy}

You can do this using the `ruleConfigMapMounts` and `sidecarContainers`
sections of the `values.yaml` for the linkerd-viz chart:

*IMPORTANT* -- take careful note of the `--include` flag that is the last
option to the sidecar command.  This is where you specify a regular expression
that determines which prometheus metrics we are going to forward to Google
Cloud Monitoring.  In this example we are forwarding _only_ the metrics from
[our recording rules](#sidecar_recording_rules).  You may wish to forward others,
but be aware of the [limitations noted above](#stackdriver).

```yaml
prometheus:
  ruleConfigMapMounts:
  - name: "recording-rules"
    subPath: "recording_rules.yml"
    configMap: "linkerd-prometheus-recording-rules"
  - name: "sidecar-config"
    subPath: "sidecar.yml"
    configMap: "linkerd-prometheus-sidecar-config"
  sidecarContainers:
  - name: stackdriver-prometheus-sidecar
    image: gcr.io/<MY_PROJECT_ID>/stackdriver-prometheus-sidecar:0.10.1
    imagePullPolicy: always
    terminationMessagePath: /dev/termination.log
    terminationMessagePolicy: File
    volumeMounts:
    - name: "data"
      mountPath: "/data"
    - name: "sidecar-config"
      mountPath: "/etc/sidecar.yml"
      subPath: "sidecar.yml"
      readOnly: true
    command:
    - "/bin/stackdriver-prometheus-sidecar"
    - "--config-file=/etc/sidecar.yml"
    - "--stackdriver.project-id=<MY_PROJECT_ID>",
    - "--stackdriver.kubernetes.location=<MY_CLUSTER_REGION>",
    - "--stackdriver.kubernetes.cluster-name=<MY_CLUSER_ID>",
    - "--prometheus.wal-directory=/data/wal",
    - "--include={__name__=~\"^linkerd_job.+\"}"
```

With this in place, use helm to install or update the [linkerd-viz
chart](https://artifacthub.io/packages/helm/linkerd2/linkerd-viz). Afterward,
you should see the sidecar container running inside the linkerd-prometheus pod:

```bash
$ kubectl -n linkerd-viz get \
  $(kubectl -n linkerd-viz get pod -l component=prometheus -o name) \
  -o=jsonpath='{.spec.containers[*].name}'

sidecar prometheus linkerd-proxy
```

The logs of the sidecar container should indicate that it started up correctly:

```bash
$ kubectl -n linkerd-viz logs \
  -f $(kubectl -n linkerd-viz get pod -l component=prometheus -o name) \
  sidecar

level=info ts=2022-05-11T18:04:13.241Z caller=main.go:293 msg="Starting Stackdriver Prometheus sidecar" version="(version=0.10.1, branch=master, revision=c71f5bff8cb6f26b5f72ac751b68c993a79f0dbd)"
level=info ts=2022-05-11T18:04:13.241Z caller=main.go:294 build_context="(go=go1.17.5, user=n@invidious.local, date=20211227-20:58:03)"
level=info ts=2022-05-11T18:04:13.241Z caller=main.go:295 host_details="(Linux 5.4.170+ #1 SMP Sat Feb 26 10:02:52 PST 2022 x86_64 prometheus-857fcbbf8c-kd5x9 (none))"
level=info ts=2022-05-11T18:04:13.241Z caller=main.go:296 fd_limits="(soft=1048576, hard=1048576)"
level=info ts=2022-05-11T18:04:13.249Z caller=main.go:598 msg="Web server started"
level=info ts=2022-05-11T18:04:13.249Z caller=main.go:579 msg="Stackdriver client started"
level=info ts=2022-05-11T18:05:16.258Z caller=manager.go:153 component="Prometheus reader" msg="Starting Prometheus reader..."
level=info ts=2022-05-11T18:05:16.276Z caller=manager.go:215 component="Prometheus reader" msg="reached first record after start offset" start_offset=0 skipped_records=0
```

...and within 3-5 minutes you should be able to find the metrics in Google
Cloud Monitoring with a [Metric
Type](https://cloud.google.com/monitoring/api/v3/naming-conventions#resource-name)
of e.g., `external.googleapis.com/prometheus/recorded_svc_latency_ms_p50_30s`
and a [Resource
Type](https://cloud.google.com/monitoring/api/resources#tag_k8s_container) of
`k8s_container`.
