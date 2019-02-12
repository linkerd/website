+++
date = "2016-09-23T13:43:54-07:00"
title = "Check"
description = "Check the Linkerd installation for potential problems."
weight = 1
aliases = [
  "/2/check-reference/"
]
[menu.l5d2docs]
  name = "check"
  parent = "cli"
+++

The `linkerd check` command validates the Linkerd installation for potential
problems, at varying stages of the Linkerd installation lifecycle.

Prior to running `linkerd install`, we recommend running prerequisite checks to
ensure you cluster is ready for installation:
```bash
linkerd check --pre
```

Once Linkerd is installed, you can run the default check command:
```bash
linkerd check
```

To validate a `linkerd inject` command succeeded, you can run additional checks
to verify each `linkerd-proxy` is operating normally:
```bash
linkerd check --proxy
```

For resolutions to common `linkerd check` failures, have a look at
[Resolutions for linkerd check failures](/2/installing/#check).


# Example output

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
√ can query the control plane API
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

# Flags

{{< flags "check" >}}
