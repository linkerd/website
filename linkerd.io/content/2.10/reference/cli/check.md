+++
title = "check"
aliases = [
  "/2.10/check-reference/"
]
+++

{{< cli/description "check" >}}

Take a look at the [troubleshooting](../../../tasks/troubleshooting/) documentation
for a full list of all the possible checks, what they do and how to fix them.

{{< cli/examples "check" >}}

## Example output

```bash
$ linkerd check
kubernetes-api
--------------
√ can initialize the client
√ can query the Kubernetes API

kubernetes-version
------------------
√ is running the minimum Kubernetes API version

linkerd-existence
-----------------
√ control plane namespace exists
√ controller pod is running
√ can initialize the client
√ can query the control plane API

linkerd-api
-----------
√ control plane pods are ready
√ control plane self-check
√ [kubernetes] control plane can talk to Kubernetes
√ [prometheus] control plane can talk to Prometheus

linkerd-service-profile
-----------------------
√ no invalid service profiles

linkerd-version
---------------
√ can determine the latest version
√ cli is up-to-date

control-plane-version
---------------------
√ control plane is up-to-date
√ control plane and cli versions match

Status check results are √
```

{{< cli/flags "check" >}}

## Subcommands

Check supports subcommands as part of the
[Multi-stage install](../../../tasks/install/#multi-stage-install) feature.

### config

{{< cli/description "check config" >}}

{{< cli/examples "check config" >}}

{{< cli/flags "check config" >}}
