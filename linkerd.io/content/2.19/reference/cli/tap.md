---
title: "tap"
description: "CLI reference for the `linkerd tap` command, including usage and flags."
---

## `linkerd tap` Command

The `linkerd tap` command allows you to observe live traffic to a Kubernetes resource in your cluster. It streams real-time request logs and helps diagnose network behavior for services managed by Linkerd.

### Usage

```bash
linkerd tap [flags] RESOURCE
```
- **RESOURCE**: The Kubernetes resource you want to observe. This can be a pod, deployment, or service.

### Important Note on Skipped Ports

If a pod is configured with the annotations:

- `config.linkerd.io/skip-inbound-ports`
- `config.linkerd.io/skip-outbound-ports`

traffic on those ports bypasses the Linkerd proxy. Because `linkerd tap` observes traffic through the proxy, **traffic on skipped ports cannot be tapped**.

### Flags
| Flag | Description | Default |
|------|-------------|---------|
| `-n, --namespace string` | Namespace of the resource | `default` |
| `--output string` | Output format: `table`, `json`, or `wide` | `table` |
| `--help` | Show help for tap command | n/a |

### Examples
1. Tap traffic for a deployment:
```bash
linkerd tap deploy/web -n emojivoto
```
2. Tap traffic for a service:
```bash
linkerd tap svc/web -n emojivoto
```
### Description
The `tap` command provides a live feed of proxied requests to a Kubernetes resource. It is commonly used for debugging and observing service-to-service communication within a Linkerd service mesh.


