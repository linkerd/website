+++
title = "Securing Your Service"
description = "Linkerd encrypts your service's traffic by default."
+++

mTLS is enabled by default, [add your services](/2/tasks/adding-your-service/)
and any requests that originate and terminate within the mesh will be encyrpted.

{{< note >}}
Linkerd relies on [service accounts
](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)
to define identity. This requires that `automountServiceAccountToken: true`
(which is the default) is set on your pods.
{{< /note >}}

To validate that mTLS is working, it is possible to see the edges between
applications, the identites used and a possible message for why that edge is not
mTLS'd. Run:

```bash
linkerd -n linkerd edges deployment
```

The output will look like:

```bash
SRC                  DST                  CLIENT                       SERVER                       MSG
linkerd-controller   linkerd-prometheus   linkerd-controller.linkerd   linkerd-prometheus.linkerd   -
linkerd-web          linkerd-controller   linkerd-web.linkerd          linkerd-controller.linkerd   -
```

The requests from `linkerd-controller` to `linkerd-prometheus` are encrypted and
have valid identities. The `edges` command is based off [the proxy
metrics](/2/reference/proxy-metrics/), it is also possible to watch each request
in real time to understand its status, this can be done by running:

```bash
linkerd -n linkerd tap deploy
```

Looking at the control plane specifically, there will be two main types of output.

```bash
req id=0:7 proxy=in  src=10.138.15.206:51558 dst=10.4.0.18:9998 tls=not_provided_by_remote :method=GET :authority=10.4.0.18:9998 :path=/ready
rsp id=0:7 proxy=in  src=10.138.15.206:51558 dst=10.4.0.18:9998 tls=not_provided_by_remote :status=200 latency=482µs
end id=0:7 proxy=in  src=10.138.15.206:51558 dst=10.4.0.18:9998 tls=not_provided_by_remote duration=32µs response-length=3B
```

This is a readiness probe. As probes are initiated from the kubelet, which is
not in the mesh, there is no identity and these requests are not mTLS'd.
Alternatively:

```bash
req id=0:11 proxy=in  src=10.4.0.15:54740 dst=10.4.0.17:9090 tls=true :method=GET :authority=linkerd-prometheus.linkerd.svc.cluster.local:9090 :path=/api/v1/query
rsp id=0:11 proxy=in  src=10.4.0.15:54740 dst=10.4.0.17:9090 tls=true :status=200 latency=194886µs
end id=0:11 proxy=in  src=10.4.0.15:54740 dst=10.4.0.17:9090 tls=true duration=121µs response-length=375B
```

As both `linkerd-prometheus` and `linkerd-web` are in the mesh and using HTTP to
communicate, the requests are automatically mTLS'd.

To watch the actual wire traffic, Linkerd includes a [debug
sidecar](/2/tasks/using-the-debug-container/) that comes with a selection of
commands that make it easier to verify and debug the service mesh itself. To
take a look at this with [emojivoto](/2/getting-started/), get the demo started
and add the debug sidecar by running:

```bash
curl -sL https://run.linkerd.io/emojivoto.yml \
  | linkerd inject --enable-debug-sidecar - \
  | kubectl apply -f -
```

Once the containers have started up, jump into the `voting` pod with:

```bash
kubectl -n emojivoto exec -it \
    $(kubectl -n emojivoto get po -o name | grep voting) \
    -c linkerd-debug -- /bin/bash
```

From inside the debug sidecar, `tshark` can be used to inspect the raw bytes.
Check it out with:

```bash
tshark -i any -d tcp.port==8080,ssl | grep -v 127.0.0.1
```

This tells `tshark` that port 8080 might be TLS'd and ignores localhost as that
traffic will always be unencrypted. The output will show both unencrypted
communication such as Prometheus scraping metrics as well as the primary
application traffic being entirely opaque externally.

```bash
 131 11.390338699    10.4.0.17 → 10.4.0.23    HTTP 346 GET /metrics HTTP/1.1
  132 11.391486903    10.4.0.23 → 10.4.0.17    HTTP 2039 HTTP/1.1 200 OK  (text/plain)
  133 11.391540872    10.4.0.17 → 10.4.0.23    TCP 68 46766 → 4191 [ACK] Seq=557 Ack=3942 Win=1329 Len=0 TSval=3389590636 TSecr=1915605020
  134 12.128190076    10.4.0.25 → 10.4.0.23    TLSv1.2 154 Application Data
  140 12.129497053    10.4.0.23 → 10.4.0.25    TLSv1.2 149 Application Data
  141 12.129534848    10.4.0.25 → 10.4.0.23    TCP 68 48138 → 8080 [ACK] Seq=1089 Ack=985 Win=236 Len=0 TSval=2234109459 TSecr=617799816
  143 13.140288400    10.4.0.25 → 10.4.0.23    TLSv1.2 150 Application Data
  148 13.141219945    10.4.0.23 → 10.4.0.25    TLSv1.2 136 Application Data
```
