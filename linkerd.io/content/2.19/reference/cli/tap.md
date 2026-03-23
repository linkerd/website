---
title: "tap"
description: "CLI reference for the `linkerd tap` command, including usage and flags."
---

The `linkerd tap` command allows you to observe live traffic to a
Kubernetes resource in your cluster. It streams real-time request logs
and helps diagnose network behavior for services managed by Linkerd.

## Usage

```bash
linkerd viz tap [flags] RESOURCE
```
- **RESOURCE**: The Kubernetes resource you want to observe. This can be
a pod, deployment, or service.

## Important Note on Skipped Ports

If a pod is configured with the annotations:

- `config.linkerd.io/skip-inbound-ports`
- `config.linkerd.io/skip-outbound-ports`

Traffic on those ports bypasses the Linkerd proxy. Because
`linkerd tap` observes traffic through the proxy, **traffic on skipped
ports cannot be tapped**.

## Flags

| Flag | Description | Default |
|------|-------------|---------|
| `--authority` | Display requests with this :authority | n/a |
| `--max-rps` | Maximum requests per second to tap | n/a |
| `--method` | Display requests with this HTTP method | n/a |
| `-n, --namespace string` | Namespace of the specified resource | `default` |
| `-o, --output string` | Output format. One of: `wide`, `json`, `jsonpath` | `table` |
| `--path` | Display requests with paths that start with this prefix | n/a |
| `--scheme` | Display requests with this scheme | n/a |
| `-l, --selector string` | Selector (label query) to filter on, supports `=`, `==`, `!=` | n/a |
| `--to` | Display requests to this resource | n/a |
| `--to-namespace` | Sets the namespace used to lookup the `--to` resource | n/a |

## Examples

1. Tap traffic for a deployment:

```bash
linkerd viz tap deploy/web -n emojivoto
```

2. Tap traffic for a service:

```bash
linkerd viz tap svc/web -n emojivoto
```

## Description

The `tap` command provides a live feed of proxied requests to a
Kubernetes resource. It is commonly used for debugging and observing
service-to-service communication within a Linkerd service mesh.

