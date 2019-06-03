+++
title = "Using the Debug Container"
description = "Inject the debug container to capture network packets"
+++

In cases where you need network-level visibility into packets entering and
leaving your application, you can use the `--enable-debug-sidecar` option of the
`linkerd inject` command to inject a `debug` sidecar container into your
workload.

This option will deploy a [`tshark`](https://www.wireshark.org/docs/man-pages/tshark.html)
container alongside your application. The default entrypoint starts `tshark`
with the `-i any` option which sets the name of the network interface or pipe
to use for live packet capture. This approach works because applications in a
pod share the same network namespace. You can also use `kubectl exec` to access
the `debug` container to run other pre-installed tools like `tcpdump`, `lsof`
and `iproute2`, or install additional tools in the container.

E.g., to deploy the emojivoto application with the `debug` container, run:

```bash
curl https://run.linkerd.io/emojivoto.yml | linkerd inject --enable-debug-sidecar - | kubectl apply -f -
```

To view all the packets entering and leaving the `vote-bot` service, run:

```bash
kubectl -n emojivoto logs vote-bot-868b7c75f-sjh5r linkerd-debug
```
