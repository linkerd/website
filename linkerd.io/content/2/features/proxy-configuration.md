+++
title = "Proxy Configuration"
description = "Linkerd provides a set of annotations that can be used to override the data plane proxy's configuration."
weight = 10
+++

Linkerd provides a set of annotations that can be used to override the data plane proxy's configuration. This is useful for overriding the default configurations of [auto-injected proxies](/2/features/proxy-injection).

The following is the list of supported annotations:

Annotation                                   | Description
-------------------------------------------- | -----------
`config.linkerd.io/admin-port`               | Proxy port to serve metrics on
`config.linkerd.io/control-port`             | Proxy port to use for control
`config.linkerd.io/enable-external-profiles` | Enable service profiles for non-Kubernetes services
`config.linkerd.io/image-pull-policy`        | Docker image pull policy
`config.linkerd.io/inbound-port`             | Proxy port to use for inbound traffic
`config.linkerd.io/init-image`               | Linkerd init container image name
`config.linkerd.io/outbound-port`            | Proxy port to use for outbound traffic
`config.linkerd.io/proxy-cpu-limit`          | Maximum amount of CPU units that the proxy sidecar can use
`config.linkerd.io/proxy-cpu-request`        | Amount of CPU units that the proxy sidecar requests
`config.linkerd.io/proxy-image`              | Linkerd proxy container image name
`config.linkerd.io/proxy-log-level`          | Log level for the proxy
`config.linkerd.io/proxy-memory-limit`       | Maximum amount of Memory that the proxy sidecar can use
`config.linkerd.io/proxy-memory-request`     | Amount of Memory that the proxy sidecar requests
`config.linkerd.io/proxy-uid`                | Run the proxy under this user ID
`config.linkerd.io/proxy-version`            | Tag to be used for Linkerd images
`config.linkerd.io/skip-inbound-ports`       | Ports that should skip the proxy and send directly to the application
`config.linkerd.io/skip-outbound-ports`      | Outbound ports that should skip the proxy

For example, to update an auto-injected proxy's CPU and memory resources, and skip inbound ports list, we insert the appropriate annotations to the `spec.template.metadata.annotations` of the owner's YAML spec, using `kubectl edit` like this:

```
spec:
  template:
    metadata:
      annotations:
        config.linkerd.io/linkerd-version: edge-19.3.3
        config.linkerd.io/proxy-cpu-limit: "1.5"
        config.linkerd.io/proxy-cpu-request: "0.2"
        config.linkerd.io/proxy-memory-limit: 2Gi
        config.linkerd.io/proxy-memory-request: 128Mi
        config.linkerd.io/skip-inbound-ports: 4222,6222
```

Note that configuration overrides on proxies injected using the `linkerd inject` command is planned for release 2.4. Follow this [GitHub issue](https://github.com/linkerd/linkerd2/issues/2590) for progress.
