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

# Resolutions for check failures

When `linkerd check` reports an error, use the reference below to determine
steps to resolution.

## pre-kubernetes-cluster-setup

These checks only run when the `--pre` flag is set. This flag is intended for
use prior to running `linkerd install`, to verify your cluster is prepared for
installation.

### √ control plane namespace does not already exist

Example failure:
```bash
× control plane namespace does not already exist
    The "linkerd" namespace already exists
```

By default `linkerd install` will create a `linkerd` namespace. Prior to
installation, that namespace should not exist. To check with a different
namespace, run:
```bash
linkerd check --pre --linkerd-namespace linkerd-test
```

### √ can create Kubernetes resources

The subsequent checks in this section validate whether you have permission to
create the Kubernetes resources required for Linkerd installation, specifically:

```
√ can create Namespaces
√ can create ClusterRoles
√ can create ClusterRoleBindings
√ can create CustomResourceDefinitions
```

For more information on cluster access, see
[Step 0](/2/getting-started/#step-0-setup) in our
[Getting Started](/2/getting-started) guide.

## pre-kubernetes-single-namespace-setup

If you do not expect to have the permission for a full cluster install, try the
`--single-namespace` flag, which validates if Linkerd can be installed in a
single namespace, with limited cluster access:
```bash
linkerd check --pre --single-namespace
```

### √ control plane namespace exists

```bash
× control plane namespace exists
    The "linkerd" namespace does not exist
```

In `--single-namespace` mode, `linkerd check` assumes that the installer does
not have permission to create a namespace, so the installation namespace must
already exist.

By default the `linkerd` namespace is used. To use a different namespace run:
```bash
linkerd check --pre --single-namespace --linkerd-namespace linkerd-test
```

### √ can create Kubernetes resources

The subsequent checks in this section validate whether you have permission to
create the Kubernetes resources required for Linkerd `--single-namespace`
installation, specifically:

```bash
√ can create Roles
√ can create RoleBindings
```

For more information on cluster access, see
[Step 0](/2/getting-started/#step-0-setup) in our
[Getting Started](/2/getting-started) guide.

## kubernetes-api

Example failures:
```bash
× can initialize the client
    error configuring Kubernetes API client: stat badconfig: no such file or directory
× can query the Kubernetes API
    Get https://8.8.8.8/version: dial tcp 8.8.8.8:443: i/o timeout
```

Ensure that your system is configured to connect to a Kubernetes cluster.
Validate that the `KUBECONFIG` environment variable is set properly, and/or
`~/.kube/config` points to a valid cluster.

Also verify that these command works:
```bash
kubectl config view
kubectl cluster-info
kubectl version
```

For more information see:
https://kubernetes.io/docs/tasks/access-application-cluster/access-cluster/

## kubernetes-version

Example failure:
```bash
× is running the minimum Kubernetes API version
    Kubernetes is on version [1.7.16], but version [1.8.0] or more recent is required
```

Linkerd requires at least version `1.8.0`. Verify your cluster version with:
```bash
kubectl version
```

## linkerd-existence

### √ control plane namespace exists

Example failure:
```bash
× control plane namespace exists
    The "linkerd" namespace does not exist
```

Ensure the Linkerd control plane namespace exists:
```bash
kubectl get ns
```

The default control plane namespace is `linkerd`. If you installed Linkerd into
a different namespace, specify that in your check command:

```bash
linkerd check --linkerd-namespace linkerdtest
```

### √ controller pod is running

Example failure:
```bash
× controller pod is running
    No running pods for "linkerd-controller"
```

Validate the state of the controller pod with:

```bash
$ kubectl -n linkerd get all
NAME                                      READY     STATUS    RESTARTS   AGE
pod/linkerd-controller-b8c4c48c8-pflc9    4/4       Running   0          18m
...

NAME                             TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE
service/linkerd-controller-api   ClusterIP   10.100.116.151   <none>        8085/TCP            41m
...

NAME                                 DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/linkerd-controller   1         1         1            1           18m
...

NAME                                            DESIRED   CURRENT   READY     AGE
replicaset.apps/linkerd-controller-b8c4c48c8    1         1         1         18m
...
```

Check the controller's logs with:
```bash
linkerd logs --control-plane-component controller
```

### √ can initialize the client

Example failure:
```bash
× can initialize the client
    parse http:// bad/: invalid character " " in host name
```

Verify that a well-formed `--api-addr` parameter was specified, if any:
```bash
linkerd check --api-addr " bad"
```

### √ can query the control plane API

Example failure:
```bash
× can query the control plane API
    Post http://8.8.8.8/api/v1/Version: context deadline exceeded
```

This check indicates a connectivity failure between the cli and the Linkerd
control plane. To verify connectivity, manually connect to the controller pod:
```bash
kubectl -n linkerd port-forward $(
  kubectl -n linkerd get po --selector=linkerd.io/control-plane-component=controller -o jsonpath='{.items[*].metadata.name}'
) 9995:9995
```

...and then curl the `/metrics` endpoint:
```bash
curl localhost:9995/metrics
```

## linkerd-api

### √ control plane pods are ready

Example failure:
```bash
× control plane pods are ready
    No running pods for "linkerd-web"
```

Verify the state of the control plane pods with:
```bash
$ kubectl -n linkerd get po
NAME                                      READY     STATUS    RESTARTS   AGE
pod/linkerd-controller-b8c4c48c8-pflc9    4/4       Running   0          45m
pod/linkerd-grafana-776cf777b6-lg2dd      2/2       Running   0          1h
pod/linkerd-prometheus-74d66f86f6-6t6dh   2/2       Running   0          1h
pod/linkerd-web-5f6c45d6d9-9hd9j          2/2       Running   0          3m
```

### √ can query the control plane API

Example failure:
```bash
× can query the control plane API
    Post https://localhost:6443/api/v1/namespaces/linkerd/services/linkerd-controller-api:http/proxy/api/v1/SelfCheck: context deadline exceeded
```

Check the logs on the control-plane's public API:
```bash
linkerd logs --control-plane-component controller --container public-api
```

### √ [kubernetes] control plane can talk to Kubernetes

Example failure:
```bash
× [kubernetes] control plane can talk to Kubernetes
    Error calling the Kubernetes API: FAIL
```

Check the logs on the control-plane's public API:
```bash
linkerd logs --control-plane-component controller --container public-api
```

### √ [prometheus] control plane can talk to Prometheus

Example failure:
```bash
× [prometheus] control plane can talk to Prometheus
    Error calling Prometheus from the control plane: FAIL
```

Validate that the Prometheus instance is up and running:
```bash
kubectl -n linkerd get all | grep prometheus
```
Check the Prometheus logs:
```bash
linkerd logs --control-plane-component prometheus
```
Check the logs on the control-plane's public API:
```bash
linkerd logs --control-plane-component controller --container public-api
```

## linkerd-service-profile

Example failure:
```bash
‼ no invalid service profiles
    ServiceProfile "bad" has invalid name (must be "<service>.<namespace>.svc.cluster.local")
```

Validate the structure of your service profiles:
```bash
$ kubectl -n linkerd get sp
NAME                                               AGE
bad                                                51s
linkerd-controller-api.linkerd.svc.cluster.local   1m
```

## linkerd-version

### √ can determine the latest version

Example failure:
```bash
× can determine the latest version
    Get https://versioncheck.linkerd.io/version.json?version=edge-19.1.2&uuid=test-uuid&source=cli: context deadline exceeded
```

Ensure you can connect to the Linkerd version check endpoint from the
environment the `linkerd` cli is running:
```bash
$ curl "https://versioncheck.linkerd.io/version.json?version=edge-19.1.2&uuid=test-uuid&source=cli"
{"stable":"stable-2.1.0","edge":"edge-19.1.2"}
```

### √ cli is up-to-date

Example failure:
```bash
‼ cli is up-to-date
    is running version 19.1.1 but the latest edge version is 19.1.2
```

See the page on [Upgrading Linkerd](/2/upgrade).

## control-plane-version

Example failures:
```bash
‼ control plane is up-to-date
    is running version 19.1.1 but the latest edge version is 19.1.2
‼ control plane and cli versions match
    mismatched channels: running stable-2.1.0 but retrieved edge-19.1.2
```

See the page on [Upgrading Linkerd](/2/upgrade).


## linkerd-data-plane

These checks only run when the `--proxy` flag is set. This flag is intended for
use after running `linkerd inject`, to verify the injected proxies are operating
normally.

### √ data plane namespace exists

Example failure:
```bash
$ check --proxy --namespace foo
...
× data plane namespace exists
    The "foo" namespace does not exist
```

Ensure the `--namespace` specified exists, or, omit the paramater to check all
namespaces.

### √ data plane proxies are ready

Example failure:
```bash
× data plane proxies are ready
    No "linkerd-proxy" containers found
```

Ensure you have injected the Linkerd proxy into your application via the
`linkerd inject` command.

For more information on `linkerd inject`, see
[Step 5: Install the demo app](/2/getting-started/#step-5-install-the-demo-app)
in our [Getting Started](/2/getting-started) guide.

### √ data plane proxy metrics are present in Prometheus

Example failure:
```bash
× data plane proxy metrics are present in Prometheus
    Data plane metrics not found for linkerd/linkerd-controller-b8c4c48c8-pflc9.
```

Ensure Prometheus can connect to each `linkerd-proxy` via the Prometheus
dashboard:

```bash
kubectl -n linkerd port-forward svc/linkerd-prometheus 9090
```

...and then browse to http://localhost:9090/targets, validate the
`linkerd-proxy` section.


### √ data plane is up-to-date

Example failure:
```bash
‼ data plane is up-to-date
    linkerd/linkerd-prometheus-74d66f86f6-6t6dh: is running version 19.1.2 but the latest edge version is 19.1.3
```

See the page on [Upgrading Linkerd](/2/upgrade).

### √ data plane and cli versions match

```bash
‼ data plane and cli versions match
    linkerd/linkerd-web-5f6c45d6d9-9hd9j: is running version 19.1.2 but the latest edge version is 19.1.3
```

See the page on [Upgrading Linkerd](/2/upgrade).
