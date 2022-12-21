+++
title = "Validating your mTLS traffic"
description = "You can validate whether or not your traffic is being mTLS'd by Linkerd."
aliases = ["securing-your-service"]
+++

By default, [Linkerd automatically enables mutual Transport Layer Security
(mTLS)](../../features/automatic-mtls/) for TCP traffic between meshed pods, by
establishing and authenticating secure, private TLS connections between Linkerd
proxies. Simply [add your services](../adding-your-service/) to Linkerd,
and Linkerd will take care of the rest.

Linkerd's automatic mTLS is done in a way that's completely transparent to
the application. Of course, sometimes it's helpful to be able to validate
whether mTLS is in effect!

## Validating mTLS with `linkerd viz edges`

To validate that mTLS is working, you can view a summary of the TCP
connections between services that are managed by Linkerd using the [`linkerd
viz edges`](../../reference/cli/viz/#edges) command.  For example:

```bash
linkerd viz -n linkerd edges deployment
```

The output will look like:

```bash
SRC          DST                      SRC_NS        DST_NS    SECURED
prometheus   linkerd-controller       linkerd-viz   linkerd   √
prometheus   linkerd-destination      linkerd-viz   linkerd   √
prometheus   linkerd-identity         linkerd-viz   linkerd   √
prometheus   linkerd-proxy-injector   linkerd-viz   linkerd   √
prometheus   linkerd-sp-validator     linkerd-viz   linkerd   √
```

In this example, everything is successfully mTLS'd, and the `CLIENT` and
`SERVER` columns denote the identities used, in the form
`service-account-name.namespace`. (See [Linkerd's automatic mTLS
documentation](../../features/automatic-mtls/) for more on what these identities
mean.) If there were a problem automatically upgrading the connection with
mTLS, the `MSG` field would contain the reason why.

## Validating mTLS with `linkerd viz tap`

Instead of relying on an aggregate, it is also possible to watch the requests
and responses in real time to understand what is getting mTLS'd. We can use the
[`linkerd viz tap` command](../../reference/cli/viz/#tap) to sample real time
request data.

```bash
linkerd viz -n linkerd tap deploy
```

{{< note >}}
By default, the control plane resources are not tappable. After having
installed the Viz extension (through `linkerd viz install`), you can enable tap
on the control plane components simply by restarting them, which can be done
with no downtime with `kubectl -n linkerd rollout restart deploy`. To enable tap
on the Viz extension itself, issue `kubectl -n linkerd-viz rollout restart
deploy`.
{{< /note >}}

Looking at the control plane specifically, there will be two main types of output.

```bash
req id=0:0 proxy=in  src=10.42.0.1:60318 dst=10.42.0.23:9995 tls=no_tls_from_remote :method=GET :authority=10.42.0.23:9995 :path=/ready
rsp id=0:0 proxy=in  src=10.42.0.1:60318 dst=10.42.0.23:9995 tls=no_tls_from_remote :status=200 latency=267µs
end id=0:0 proxy=in  src=10.42.0.1:60318 dst=10.42.0.23:9995 tls=no_tls_from_remote duration=20µs response-length=3B
```

These are calls by the [Kubernetes readiness
probe](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/).
As probes are initiated from the kubelet, which is not in the mesh, there is no
identity and these requests are not mTLS'd, as denoted by the
`tls=no_tls_from_remote` message.

Other requests to the control plane *are* TLS'd:

```bash
ireq id=2:1 proxy=in  src=10.42.0.31:55428 dst=10.42.0.22:9995 tls=true :method=GET :authority=10.42.0.22:9995 :path=/metrics
rsp id=2:1 proxy=in  src=10.42.0.31:55428 dst=10.42.0.22:9995 tls=true :status=200 latency=1597µs
end id=2:1 proxy=in  src=10.42.0.31:55428 dst=10.42.0.22:9995 tls=true duration=228µs response-length=2272B
```

This connection comes from Prometheus, which in the mesh, so the request is
automatically mTLS'd, as denoted by the `tls=true` output.

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
that traffic will always be unencrypted). The output will show the primary
application traffic being automatically mTLS'd.

```bash
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
