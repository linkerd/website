---
title: Configuring Proxy Discovery Cache
description: Changing proxy discover cache timeouts when using slow clients.
---

The Linkerd proxy maintains in-memory state, such as discovery results, requests
and connections. This state is cached to allow the proxy to process traffic more
efficiently. Cached discovery results also improve resiliency in the face of
control plane outages.

To ensure the CPU and memory footprint is low, cached entries are dropped if
they go unused for some amount of time. If an entry is not referenced within the
timeout, it will be evicted. If it is referenced, the timer resets.

These timeouts are handle via these two config values:

- `proxy.outboundDiscoveryCacheUnusedTimeout`: Defines the eviction timeout for
  cached service discovery results, connections and clients. Defaults to `5s`.
- `proxy.inboundDiscoveryCacheUnusedTimeout`: Defines the eviction timeout for
  cached policy discovery results. Defaults to `90s`.

These values can be configured globally (affecting all the data plane) via Helm
or the CLI at install/upgrade time, or with annotations at a namespace or
workload level for affecting only workloads under a given namespace or specific
workloads.

## Configuring via Helm

When installing/upgrading Linkerd via [Helm](install-helm/), you can use the
`proxy.outboundDiscoveryCacheUnusedTimeout` and
`proxy.inboundDiscoveryCacheUnusedTimeout` values. For example:

```bash
helm upgrade linkerd-control-plane \
  --set proxy.outboundDiscoveryCacheUnusedTimeout=60s \
  --set proxy.inboundDiscoveryCacheUnusedTimeout=120s \
  linkerd/linkerd-control-plane
```

## Configuring via the Linkerd CLI

As with any Helm value, these are available via the `--set` flag:

```bash
linkerd upgrade \
  --set proxy.outboundDiscoveryCacheUnusedTimeout=60s \
  --set proxy.inboundDiscoveryCacheUnusedTimeout=120s \
  | kubectl apply -f -
```

## Configuring via Annotations

You can also use the
`config.linkerd.io/proxy-outbound-discovery-cache-unused-timeout` and
`config.linkerd.io/proxy-inbound-discovery-cache-unused-timeout` annotations at
the namespace or pod template level:

```yaml
kind: Deployment
apiVersion: apps/v1
metadata:
  name: my-deployment
  # ...
spec:
  template:
    metadata:
      annotations:
        config.linkerd.io/proxy-outbound-discovery-cache-unused-timeout: "60s"
        config.linkerd.io/proxy-inbound-discovery-cache-unused-timeout: "120s"
  # ...
```

Note that these values need to be present before having injected your workloads.
For applying to existing workloads, you'll need to roll them out.

## When to Change Timeouts

In the vast majority of cases the default values will just work. You should
think about experimenting with larger values when using slow clients (5 RPS or
less across two or more replicas) where clients would experience unexpected
connection closure errors as soon as the control plane comes down. A higher
cache idle timeout for discovery results can help mitigating these problems.
