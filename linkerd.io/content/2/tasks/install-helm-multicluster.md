+++
title = "Installing Linkerd multicluster components with Helm"
description = "Install Linkerd multicluster components onto your own Kubernetes cluster using Helm."
+++

Linkerd's multicluster components i.e Gateway and Service Mirror can
be installed via Helm rather than the `linkerd multicluster install` command.

This while not only allows advanced configuration, but also allows users
to bundle the multicluster installation as part of their existing Helm based
installation pipeline.

## Prerequisite: Linkerd2 Installation

Existing Linkerd installation should be present on the cluster before installing
any of the multicluster components, as it is required for them to be meshed which
is done through the Linkerd's proxy-injector.

Linkerd can be installed through [Helm](https://linkerd.io/2/tasks/install-helm)
or [CLI](https://linkerd.io/2/tasks/install/)

## Adding Linkerd's Helm repository

First, Let's add the Linkerd's Helm repository by running

```bash
# To add the repo for Linkerd2 stable releases:
helm repo add linkerd https://helm.linkerd.io/stable
```

## Helm multicluster install procedure

By default, both the multicluster components i.e Service Mirror and Gateway are
installed when no toggle values are added.

```bash
helm install linkerd2-multicluster linkerd/linkerd2-multicluster
```

The chart values will be picked from the chart's `values.yaml` file.

You can override the values in that file by providing your own `values.yaml`
file passed with a `-f` option, or overriding specific values using the family of
`--set` flags.

Full set of configuration options can be found [here](https://github.com/linkerd/linkerd2/tree/master/charts/linkerd2-multicluster#configuration)

The installation can be verified by running

```bash
linkerd check --multicluster
```

### Installing individual components

Individual multicluster components can be enabled or disabled by setting
`serviceMirror` and `gateway` respectively. By default, both of these
values are true.

## Installing access credentials

For the source cluster to be able to access the target cluster's services, Access
credentials have to be present in the target cluster. This can be done using the
`linkerd multicluster allow` command through the CLI.

The same functionality can also be done through Helm by disabling `gateway` and
`serviceMirror` while submitting the remote service account name.

```bash
 helm install linkerd2-mc-soource linkerd/linkerd2-multicluster --set gateway=false --set serviceMirror=false --set remoteMirrorServiceAccountName=source --set installNamespace=false --kube-context target
```

{{< note >}}
`installNamespace` should be disabled if the access credentials are
being created in the same namespace as that of multicluster components to prevent
failure due to namespace ownership conflict between the Helm releases.
{{< /note >}}

Each access credential is created as a separate Helm release providing clear separation.
To revoke access to a particular source cluster, relevant helm release in the target
cluster can be removed without effecting the mutlicluster components
or other access credentials Helm releases.

## Further Reading

Now that the multicluster components are installed, operations like linking, etc
can be performed by using the linkerd CLI's multicluster sub-command as per the
[multicluster task](https://linkerd.io/2/features/multicluster).
