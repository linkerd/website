---
title: inject
---

The `inject` command is a text transform that modifies Kubernetes manifests
passed to it either as a file or as a stream (`-`) to adds a
`linkerd.io/inject: enabled` annotation to eligible resources in the manifest.
When the resulting annotated manifest is applied to the Kubernetes cluster,
Linkerd's [proxy autoinjector](../../features/proxy-injection/) automatically
adds the Linkerd data plane proxies to the corresponding pods.

Note that there is no *a priori* reason to use this command. In production,
these annotations may be instead set by a CI/CD system, or any other
deploy-time mechanism.

## Manual injection

Alternatively, this command can also perform the full injection purely on the
client side, by enabling with the `--manual` flag. (Prior to Linkerd 2.4, this
was the default behavior.)

{{< docs/cli-examples "inject" >}}

{{< docs/cli-flags "inject" >}}
