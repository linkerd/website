+++
title = "Proxy Metrics"
description = "The Linkerd proxy natively exports Prometheus metrics for all incoming and outgoing traffic."
aliases = [
  "/proxy-metrics/",
  "../proxy-metrics/",
  "../observability/proxy-metrics/"
]
+++

The Linkerd proxy exposes metrics that describe the traffic flowing through the
proxy.  The following metrics are available at `/metrics` on the proxy's metrics
port (default: `:4191`) in the [Prometheus format][prom-format].

## Protocol-Level Metrics

* `request_total`: A counter of the number of requests the proxy has received.
  This is incremented when the request stream begins.

* `response_total`: A counter of the number of responses the proxy has received.
  This is incremented when the response stream ends.

* `response_latency_ms`: A histogram of response latencies. This measurement
  reflects the [time-to-first-byte][ttfb] (TTFB) by recording the elapsed time
  between the proxy processing a request's headers and the first data frame of the
  response. If a response does not include any data, the end-of-stream event is
  used. The TTFB measurement is used so that Linkerd accurately reflects
  application behavior when a server provides response headers immediately but is
  slow to begin serving the response body.

* `route_request_total`, `route_response_latency_ms`, and `route_response_total`:
  These metrics are analogous to `request_total`, `response_latency_ms`, and
  `response_total` except that they are collected at the route level.  This
  means that they do not have `authority`, `tls`, `grpc_status_code` or any
  outbound labels but instead they have:
  * `dst`: The authority of this request.
  * `rt_route`: The name of the route for this request.

* `control_request_total`, `control_response_latency_ms`, and `control_response_total`:
  These metrics are analogous to `request_total`, `response_latency_ms`, and
  `response_total` but for requests that the proxy makes to the Linkerd control
  plane.  Instead of `authority`, `direction`, or any outbound labels, instead
  they have:
  * `addr`: The address used to connect to the control plane.

* `inbound_http_authz_allow_total`: A counter of the total number of inbound
  HTTP requests that were authorized.
  * `authz_name`: The name of the authorization policy used to allow the request.

* `inbound_http_authz_deny_total`: A counter of the total number of inbound
  HTTP requests that could not be processed due to being denied by the
  authorization policy.

* `inbound_http_route_not_found_total`: A counter of the total number of
  inbound HTTP requests that could not be associated with a route.

Note that latency measurements are not exported to Prometheus until the stream
_completes_. This is necessary so that latencies can be labeled with the appropriate
[response classification](#response-labels).

### Labels

Each of these metrics has the following labels:

* `authority`: The value of the `:authority` (HTTP/2) or `Host` (HTTP/1.1)
               header of the request.
* `direction`: `inbound` if the request originated from outside of the pod,
               `outbound` if the request originated from inside of the pod.
* `tls`: `true` if the request's connection was secured with TLS.

#### Response Labels

The following labels are only applicable on `response_*` metrics.

* `status_code`: The HTTP status code of the response.

#### Response Total Labels

In addition to the labels applied to all `response_*` metrics, the
`response_total`, `route_response_total`, and `control_response_total` metrics
also have the following labels:

* `classification`: `success` if the response was successful, or `failure` if
                    a server error occurred. This classification is based on
                    the gRPC status code if one is present, and on the HTTP
                    status code otherwise.
* `grpc_status_code`: The value of the `grpc-status` trailer.  Only applicable
                      for gRPC responses.

{{< note >}}
Because response classification may be determined based on the `grpc-status`
trailer (if one is present), a response may not be classified until its body
stream completes. Response latency, however, is determined based on
[time-to-first-byte][ttfb], so the `response_latency_ms` metric is recorded as
soon as data is received, rather than when the response body ends. Therefore,
the values of the `classification` and `grpc_status_code` labels are not yet
known when the `response_latency_ms` metric is recorded.
{{< /note >}}

#### Outbound labels

The following labels are only applicable if `direction=outbound`.

* `dst_deployment`: The deployment to which this request is being sent.
* `dst_k8s_job`: The job to which this request is being sent.
* `dst_replicaset`: The replica set to which this request is being sent.
* `dst_daemonset`: The daemon set to which this request is being sent.
* `dst_statefulset`: The stateful set to which this request is being sent.
* `dst_replicationcontroller`: The replication controller to which this request
                               is being sent.
* `dst_namespace`: The namespace to which this request is being sent.
* `dst_service`: The service to which this request is being sent.
* `dst_pod_template_hash`: The [pod-template-hash][pod-template-hash] of the pod
                           to which this request is being sent. This label
                           selector roughly approximates a pod's `ReplicaSet` or
                           `ReplicationController`.

#### Prometheus Collector labels

The following labels are added by the Prometheus collector.

* `instance`: ip:port of the pod.
* `job`: The Prometheus job responsible for the collection, typically
         `linkerd-proxy`.

##### Kubernetes labels added at collection time

Kubernetes namespace, pod name, and all labels are mapped to corresponding
Prometheus labels.

* `namespace`: Kubernetes namespace that the pod belongs to.
* `pod`: Kubernetes pod name.
* `pod_template_hash`: Corresponds to the [pod-template-hash][pod-template-hash]
                       Kubernetes label. This value changes during redeploys and
                       rolling restarts. This label selector roughly
                       approximates a pod's `ReplicaSet` or
                       `ReplicationController`.

##### Linkerd labels added at collection time

Kubernetes labels prefixed with `linkerd.io/` are added to your application at
`linkerd inject` time. More specifically, Kubernetes labels prefixed with
`linkerd.io/proxy-*` will correspond to these Prometheus labels:

* `daemonset`: The daemon set that the pod belongs to (if applicable).
* `deployment`: The deployment that the pod belongs to (if applicable).
* `k8s_job`: The job that the pod belongs to (if applicable).
* `replicaset`: The replica set that the pod belongs to (if applicable).
* `replicationcontroller`: The replication controller that the pod belongs to
                           (if applicable).
* `statefulset`: The stateful set that the pod belongs to (if applicable).

### Example

Here's a concrete example, given the following pod snippet:

```yaml
name: vote-bot-5b7f5657f6-xbjjw
namespace: emojivoto
labels:
  app: vote-bot
  linkerd.io/control-plane-ns: linkerd
  linkerd.io/proxy-deployment: vote-bot
  pod-template-hash: "3957278789"
  test: vote-bot-test
```

The resulting Prometheus labels will look like this:

```bash
request_total{
  pod="vote-bot-5b7f5657f6-xbjjw",
  namespace="emojivoto",
  app="vote-bot",
  control_plane_ns="linkerd",
  deployment="vote-bot",
  pod_template_hash="3957278789",
  test="vote-bot-test",
  instance="10.1.3.93:4191",
  job="linkerd-proxy"
}
```

## Transport-Level Metrics

The following metrics are collected at the level of the underlying transport
layer.

* `tcp_open_total`: A counter of the total number of opened transport
  connections.
* `tcp_close_total`: A counter of the total number of transport connections
  which have closed.
* `tcp_open_connections`: A gauge of the number of transport connections
  currently open.
* `tcp_write_bytes_total`: A counter of the total number of sent bytes. This is
  updated when the connection closes.
* `tcp_read_bytes_total`: A counter of the total number of received bytes. This
  is updated when the connection closes.
* `tcp_connection_duration_ms`: A histogram of the duration of the lifetime of a
  connection, in milliseconds. This is updated when the connection closes.
* `inbound_tcp_errors_total`: A counter of the total number of inbound TCP
  connections that could not be processed due to a proxy error.
* `outbound_tcp_errors_total`: A counter of the total number of outbound TCP
  connections that could not be processed due to a proxy error.
* `inbound_tcp_authz_allow_total`: A counter of the total number of TCP
  connections that were authorized.
* `inbound_tcp_authz_deny_total`: A counter of the total number of TCP
  connections that were denied

### Labels

Each of these metrics has the following labels:

* `direction`: `inbound` if the connection was established either from outside the
                pod to the proxy, or from the proxy to the application,
               `outbound` if the connection was established either from the
                application to the proxy, or from the proxy to outside the pod.
* `peer`: `src` if the connection was accepted by the proxy from the source,
          `dst` if the connection was opened by the proxy to the destination.

Note that the labels described above under the heading "Prometheus Collector labels"
are also added to transport-level metrics, when applicable.

#### Connection Close Labels

The following labels are added only to metrics which are updated when a
connection closes (`tcp_close_total` and `tcp_connection_duration_ms`):

* `classification`: `success` if the connection terminated cleanly, `failure` if
  the connection closed due to a connection failure.

[prom-format]: https://prometheus.io/docs/instrumenting/exposition_formats/#format-version-0.0.4
[pod-template-hash]: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#pod-template-hash-label
[ttfb]: https://en.wikipedia.org/wiki/Time_to_first_byte

## Identity Metrics

* `identity_cert_expiration_timestamp_seconds`: A gauge of the time when the
  proxy's current mTLS identity certificate will expire (in seconds since the UNIX
  epoch).
* `identity_cert_refresh_count`: A counter of the total number of times the
  proxy's mTLS identity certificate has been refreshed by the Identity service.
