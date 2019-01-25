+++
date = "2016-09-23T13:43:54-07:00"
title = "Check"
description = "Check the Linkerd installation for potential problems."
weight = 1
aliases = [
  "/2/check-reference/"
]
[menu.l5d2docs]
  name = "Check"
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
[Frequently Asked Questions](/2/faq).

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

# Check options

```bash
$ linkerd check --help
Check the Linkerd installation for potential problems.

The check command will perform a series of checks to validate that the linkerd
CLI and control plane are configured correctly. If the command encounters a
failure it will print additional information about the failure and exit with a
non-zero exit code.

Usage:
  linkerd check [flags]

Examples:
  # Check that the Linkerd control plane is up and running
  linkerd check

  # Check that the Linkerd control plane can be installed in the "test" namespace
  linkerd check --pre --linkerd-namespace test

  # Check that the Linkerd data plane proxies in the "app" namespace are up and running
  linkerd check --proxy --namespace app

Flags:
      --expected-version string   Overrides the version used when checking if Linkerd is running the latest version (mostly for testing)
  -h, --help                      help for check
  -n, --namespace string          Namespace to use for --proxy checks (default: all namespaces)
      --pre                       Only run pre-installation checks, to determine if the control plane can be installed
      --proxy                     Only run data-plane checks, to determine if the data plane is healthy
      --single-namespace          When running pre-installation checks (--pre), only check the permissions required to operate the control plane in a single namespace
      --wait duration             Retry and wait for some checks to succeed if they don't pass the first time (default 5m0s)

Global Flags:
      --api-addr string            Override kubeconfig and communicate directly with the control plane at host:port (mostly for testing)
      --context string             Name of the kubeconfig context to use
      --kubeconfig string          Path to the kubeconfig file to use for CLI requests
  -l, --linkerd-namespace string   Namespace in which Linkerd is installed [$LINKERD_NAMESPACE] (default "linkerd")
      --verbose                    Turn on debug logging
```

