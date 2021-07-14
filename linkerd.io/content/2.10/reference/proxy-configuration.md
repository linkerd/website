+++
title = "Proxy Configuration"
description = "Linkerd provides a set of annotations that can be used to override the data plane proxy's configuration."
+++

Linkerd provides a set of annotations that can be used to **override** the data
plane proxy's configuration. This is useful for **overriding** the default
configurations of [auto-injected proxies](../../features/proxy-injection/).

The following is the list of supported annotations:

{{< cli-2-10/annotations "inject" >}}

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
