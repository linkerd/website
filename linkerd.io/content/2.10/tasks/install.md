---
title: Installing Linkerd
description: Install Linkerd to your own Kubernetes cluster.
---

Before you can use Linkerd, you'll need to install the
[core control plane](../../reference/architecture/#control-plane). This page
covers how to accomplish that, as well as common problems that you may
encounter.

{{< docs/production-note >}}

Note that the control plane is typically installed by using Linkerd's CLI. See
[Getting Started](../../getting-started/) for how to install the CLI onto your local
environment.

Linkerd also comprises of some first party extensions which add additional features
i.e `viz`, `multicluster` and `jaeger`. See [Extensions](../extensions/)
to understand how to install them.

Note also that, once the control plane is installed, you'll need to "mesh" any
services you want Linkerd active for. See
[Adding Your Service](../adding-your-service/) for how to add Linkerd's data
plane to your services.

## Requirements

Linkerd 2.x requires a functioning Kubernetes cluster on which to run. This
cluster may be hosted on a cloud provider or may be running locally via
Minikube or Docker for Desktop.

You can validate that this Kubernetes cluster is configured appropriately for
Linkerd by running

```bash
linkerd check --pre
```

### GKE

If installing Linkerd on GKE, there are some extra steps required depending on
how your cluster has been configured. If you are using any of these features,
check out the additional instructions.

- [Private clusters](../../reference/cluster-configuration/#private-clusters)

## Installing

Once you have a cluster ready, generally speaking, installing Linkerd is as
easy as running `linkerd install` to generate a Kubernetes manifest, and
applying that to your cluster, for example, via

```bash
linkerd install | kubectl apply -f -
```

See [Getting Started](../../getting-started/) for an example.

{{< note >}}
Most common configuration options are provided as flags for `install`. See the
[reference documentation](../../reference/cli/install/) for a complete list of
options. To do configuration that is not part of the `install` command, see how
you can create a [customized install](../customize-install/).
{{< /note >}}

{{< note >}}
For organizations that distinguish cluster privileges by role, jump to the
[Multi-stage install](#multi-stage-install) section.
{{< /note >}}

## Verification

After installation, you can validate that the installation was successful by
running:

```bash
linkerd check
```

## Uninstalling

See [Uninstalling Linkerd](../uninstall/).

## Multi-stage install

If your organization assigns Kubernetes cluster privileges based on role
(typically cluster owner and service owner), Linkerd provides a "multi-stage"
installation to accommodate these two roles. The two installation stages are
`config` (for the cluster owner) and `control-plane` (for the service owner).
The cluster owner has privileges necessary to create namespaces, as well as
global resources including cluster roles, bindings, and custom resource
definitions. The service owner has privileges within a namespace necessary to
create deployments, configmaps, services, and secrets.

### Stage 1: config

The `config` stage is intended to be run by the cluster owner, the role with
more privileges. It is also the cluster owner's responsibility to run the
initial pre-install check:

```bash
linkerd check --pre
```

Once the pre-install check passes, install the config stage with:

```bash
linkerd install config | kubectl apply -f -
```

In addition to creating the `linkerd` namespace, this command installs the
following resources onto your Kubernetes cluster:

- ClusterRole
- ClusterRoleBinding
- CustomResourceDefinition
- MutatingWebhookConfiguration
- PodSecurityPolicy
- Role
- RoleBinding
- Secret
- ServiceAccount
- ValidatingWebhookConfiguration

To validate the `config` stage succeeded, run:

```bash
linkerd check config
```

### Stage 2: control-plane

Following successful installation of the `config` stage, the service owner may
install the `control-plane` with:

```bash
linkerd install control-plane | kubectl apply -f -
```

This command installs the following resources onto your Kubernetes cluster, all
within the `linkerd` namespace:

- ConfigMap
- Deployment
- Secret
- Service

To validate the `control-plane` stage succeeded, run:

```bash
linkerd check
```
