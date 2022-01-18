+++
title = "Securing Your Application with mTLS"
description = "Linkerd encrypts your service's traffic by default."
+++

By default, [Linkerd automatically enables mutual Transport Layer Security
(mTLS)](../../features/automatic-mtls/) for TCP traffic between meshed pods, by
establishing and authenticating secure, private TLS connections between Linkerd
proxies. Simply [add your services](../adding-your-service/) to Linkerd,
and Linkerd will take care of the rest.

Linkerd's automatic mTLS is done in a way that's completely transparent to
the application. Of course, sometimes it's helpful to be able to validate
whether mTLS is in effect!

{{< note >}}
Linkerd uses Kubernetes *ServiceAccounts* to define service identity. This
requires that the `automountServiceAccountToken` feature (on by default) has
not been disabled on the pods. See the [Kubernetes service account
documentation](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)
for more.
{{< /note >}}

## Validating mTLS with `linkerd edges`

To validate that mTLS is working, you can view a summary of the TCP
connections between services that are managed by Linkerd using the [`linkerd
edges`](../../reference/cli/edges/) command.  For example:

```bash
linkerd -n linkerd edges deployment
```

The output will look like:

```bash
SRC                  DST                  CLIENT                       SERVER                       MSG
linkerd-controller   linkerd-prometheus   linkerd-controller.linkerd   linkerd-prometheus.linkerd   -
linkerd-web          linkerd-controller   linkerd-web.linkerd          linkerd-controller.linkerd   -
```

In this example, everything is successfully mTLS'd, and the `CLIENT` and
`SERVER` columns denote the identities used, in the form
`service-account-name.namespace`. (See [Linkerd's automatic mTLS
documentation](../../features/automatic-mtls/) for more on what these identities
mean.) If there were a problem automatically upgrading the connection with
mTLS, the `MSG` field would contain the reason why.

## Validating mTLS with `linkerd tap`

Instead of relying on an aggregate, it is also possible to watch the requests
and responses in real time to understand what is getting mTLS'd. We can use the
[`linkerd tap` command](../../reference/cli/tap/) to sample real time request data.
For example:

```bash
linkerd -n linkerd tap deploy
```

Looking at the control plane specifically, there will be two main types of output.

```bash
req id=0:7 proxy=in  src=10.138.15.206:51558 dst=10.4.0.18:9998 tls=not_provided_by_remote :method=GET :authority=10.4.0.18:9998 :path=/ready
rsp id=0:7 proxy=in  src=10.138.15.206:51558 dst=10.4.0.18:9998 tls=not_provided_by_remote :status=200 latency=482µs
end id=0:7 proxy=in  src=10.138.15.206:51558 dst=10.4.0.18:9998 tls=not_provided_by_remote duration=32µs response-length=3B
```

These are calls by the [Kubernetes readiness
probe](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/).
As probes are initiated from the kubelet, which is not in the mesh, there is no
identity and these requests are not mTLS'd, as denoted by the
`tls=not_provided_by_remote` message.

Other requests to the control plane *are* TLS'd:

```bash
req id=0:11 proxy=in  src=10.4.0.15:54740 dst=10.4.0.17:9090 tls=true :method=GET :authority=linkerd-prometheus.linkerd.svc.cluster.local:9090 :path=/api/v1/query
rsp id=0:11 proxy=in  src=10.4.0.15:54740 dst=10.4.0.17:9090 tls=true :status=200 latency=194886µs
end id=0:11 proxy=in  src=10.4.0.15:54740 dst=10.4.0.17:9090 tls=true duration=121µs response-length=375B
```

As both `linkerd-prometheus` and `linkerd-web` are in the mesh and using HTTP
to communicate, the requests are automatically mTLS'd, as denoted by the
`tls=true` output.

## Validating mTLS with tshark

The final way to validate mTLS is to look at raw network traffic within the
cluster.

Linkerd includes a [debug sidecar](../using-the-debug-container/) that
comes with a selection of commands that make it easier to verify and debug the
service mesh itself. For example, with our [*emojivoto* demo
application](../../getting-started/), we can add the debug sidecar by running:

```bash
curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/emojivoto.yml \
  | linkerd inject --enable-debug-sidecar - \
  | kubectl apply -f -
```

We can then establish a remote shell directly in the debug container of a pod in
the `voting` service with:

```bash
kubectl -n emojivoto exec -it \
    $(kubectl -n emojivoto get po -o name | grep voting) \
    -c linkerd-debug -- /bin/bash
```

Once we're inside the debug sidecar, the built-in `tshark` command can be used
to inspect the raw packets on the network interface. For example:

```bash
tshark -i any -d tcp.port==8080,ssl | grep -v 127.0.0.1
```

This tells `tshark` that port 8080 might be TLS'd, and to ignore localhost (as
that traffic will always be unencrypted). The output will show both unencrypted
communication, such as Prometheus scraping metrics, as well as the primary
application traffic being automatically mTLS'd.

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

## Summary

In this guide, we've provided several different ways to validate whether
Linkerd has been able to automatically upgrade connections to mTLS. Note that
there are several reasons why Linkerd may not be able to do this upgrade---see
the "Caveats and future work" section of the [Linkerd automatic mTLS
documentation](../../features/automatic-mtls/)---so if you are relying on Linkerd
for security purposes, this kind of validation can be instructive.
