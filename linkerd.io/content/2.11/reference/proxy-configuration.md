+++
title = "Proxy Configuration"
description = "Linkerd provides a set of annotations that can be used to override the data plane proxy's configuration."
+++

Linkerd provides a set of annotations that can be used to **override** the data
plane proxy's configuration. This is useful for **overriding** the default
configurations of [auto-injected proxies](../../features/proxy-injection/).

The following is the list of supported annotations:

{{< cli/annotations "inject" >}}

For example, to update an auto-injected proxy's CPU and memory resources, we
insert the appropriate annotations into the `spec.template.metadata.annotations`
of the owner's pod spec, using `kubectl edit` like this:

```yaml
spec:
  template:
    metadata:
      annotations:
        config.linkerd.io/proxy-cpu-limit: "1"
        config.linkerd.io/proxy-cpu-request: "0.2"
        config.linkerd.io/proxy-memory-limit: 2Gi
        config.linkerd.io/proxy-memory-request: 128Mi
```

See [here](../../tasks/configuring-proxy-concurrency/) for details on tuning the
proxy's resource usage.

For proxies injected using the `linkerd inject` command, configuration can be
overridden using the [command-line flags](../cli/inject/).

## Ingress Mode

Proxy ingress mode is a mode of operation designed to help Linkerd integrate
with certain ingress controllers. Ingress mode is necessary if the ingress
itself cannot be otherwise configured to use the Service port/ip as the
destination.

When an individual Linkerd proxy is set to `ingress` mode, it will route
requests based on their `:authority`, `Host`, or `l5d-dst-override` headers
instead of their original destination. This will inform Linkerd to override the
endpoint selection of the ingress container and to perform its own endpoint
selection, enabling features such as per-route metrics and traffic splitting.

The proxy can be made to run in `ingress` mode by used the `linkerd.io/inject:
ingress` annotation rather than the default `linkerd.io/inject: enabled`
annotation. This can also be done with the `--ingress` flag in the `inject` CLI
command:

```bash
kubectl get deployment <ingress-controller> -n <ingress-namespace> -o yaml | linkerd inject --ingress - | kubectl apply -f -
```
