---
title: Upgrading Linkerd
description: Perform zero-downtime upgrades for Linkerd.
---

In this guide, we'll walk you through how to perform zero-downtime upgrades for
Linkerd.

{{< note >}}

This page contains instructions for upgrading to the latest edge release of
Linkerd. If you have installed a
[stable distribution](/releases/#recent-versions) of Linkerd, the vendor may
have alternative guidance on how to upgrade. You can find more information about
the different kinds of Linkerd releases on the
[Releases and Versions](/releases/) page.

{{< /note >}}

## Edge releases and data plane version skew

Since a Linkerd upgrade always starts by upgrading the control plane, there is a
period during which the control plane is running the new version, but the data
plane is still running the older version. To assess this skew, we offer the
following recommendations.

Linkerd provides open source _edge release_ packages which can easily be
installed on a Kubernetes cluster. These edge releases are **not** semantically
versioned, i.e. the edge release number itself does not give you any assurance
about breaking changes, incompatibilities, etc. Instead, this information is
available in the [release notes](https://github.com/linkerd/linkerd2/releases)
for each release.

Some edge releases mark the introduction of a new logical version of Linkerd.
For example, the [Releases and Versions page](/releases/#recent-versions)
denotes the "corresponding edge release" for each recent Linkerd version, e.g.
`edge-24.11.8` is the corresponding edge release for Linkerd 2.17.

During the upgrade process, it is usually safe for the control plane to be ahead
of the data plane by up to a full version. For example, `edge-24.11.8` is part
of Linkerd 2.17, so data planes running this version should be compatible with
edge releases within 2.17 or 2.18. However, please be sure to consult the
release notes first.

## Overall upgrade process

There are four components that need to be upgraded:

- [The CLI](#upgrading-the-cli)
- [The control plane](#upgrading-the-control-plane)
- [The control plane extensions](#upgrading-extensions)
- [The data plane](#upgrading-the-data-plane)

These steps should be performed in sequence.

## Before upgrading

Before you commence an upgrade, you should ensure that the current state of
Linkerd is healthy, e.g. by using `linkerd check`. For major version upgrades,
you should also ensure that your data plane is up-to-date, e.g. with
`linkerd check --proxy`, to avoid unintentional version skew.

Make sure that your Linkerd version and Kubernetes version are compatible by
checking Linkerd's [supported Kubernetes versions](../reference/k8s-versions/).

## Upgrading the CLI

The CLI can be used to validate whether Linkerd was installed correctly.

To upgrade the CLI, run:

```bash
curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install-edge | sh
```

Alternatively, you can download the CLI directly via the
[Linkerd releases page](https://github.com/linkerd/linkerd2/releases/).

Verify the CLI is installed and running the expected version with:

```bash
linkerd version --client
```

## Upgrading the control plane

### Upgrading the control plane with the CLI

For users who have installed Linkerd via the CLI, the `linkerd upgrade` command
will upgrade the control plane. This command ensures that all of the control
plane's existing configuration and TLS secrets are retained. Linkerd's CRDs
should be upgraded first, using the `--crds` flag, followed by upgrading the
control plane.

(If you are using a stable release, your vendor's upgrade instructions may have
more information.)

```bash
linkerd upgrade --crds | kubectl apply -f -
linkerd upgrade | kubectl apply -f -
```

Next, we use the `linkerd prune` command to remove any resources that were
present in the previous version but should not be present in this one.

```bash
linkerd prune | kubectl delete -f -
```

### Upgrading the control plane with Helm

For Helm control plane installations, please follow the instructions at
[Helm upgrade procedure](install-helm/#helm-upgrade-procedure).

### Verifying the control plane upgrade

Once the upgrade process completes, check to make sure everything is healthy by
running:

```bash
linkerd check
```

This will run through a set of checks against your control plane and make sure
that it is operating correctly.

To verify the Linkerd control plane version, run:

```bash
linkerd version
```

Which should display the latest versions for both client and server.

## Upgrading extensions

[Linkerd's extensions](extensions/) provide additional functionality to Linkerd
in a modular way. Generally speaking, extensions are versioned separately from
Linkerd releases and follow their own schedule; however, some extensions are
updated alongside Linkerd releases and you may wish to update them as part of
the same process.

Each extension can be upgraded independently. If using Helm, the procedure is
similar to the control plane upgrade, using the respective charts. For the CLI,
the extension CLI commands don't provide `upgrade` subcommands, but using
`install` again is fine. For example:

```bash
linkerd viz install | kubectl apply -f -
linkerd multicluster install | kubectl apply -f -
linkerd jaeger install | kubectl apply -f -
```

Most extensions also include a `prune` command for removing resources which were
present in the previous version but should not be present in the current
version. For example:

```bash
linkerd viz prune | kubectl delete -f -
```

### Upgrading the multicluster extension

Upgrading the multicluster extension doesn't cause downtime in the traffic going
through the mirrored services, unless otherwise noted in the version-specific
notes below. Note however that for the service mirror _deployments_ (which
control the creation of the mirrored services) to be updated, you need to
re-link your clusters through `linkerd multicluster link`.

## Upgrading the data plane

Upgrading the data plane requires updating the proxy added to each meshed
workload. Since pods are immutable in Kubernetes, Linkerd is unable to simply
update the proxies in place. Thus, the standard option is to restart each
workload, allowing the proxy injector to inject the latest version of the proxy
as they come up.

For example, you can use the `kubectl rollout restart` command to restart a
meshed deployment:

```bash
kubectl -n <namespace> rollout restart deploy
```

As described earlier, a skew of one major version between data plane and control
plane is always supported. Thus, for some systems it is possible to do this data
plane upgrade "lazily", and simply allow workloads to pick up the newest proxy
as they are restarted for other reasons (e.g. for new code rollouts). However,
newer features may only be available on workloads with the latest proxy.

A skew of more than one major version between data plane and control plane is
not supported.

### Verify the data plane upgrade

Check to make sure everything is healthy by running:

```bash
linkerd check --proxy
```

This will run through a set of checks to verify that the data plane is operating
correctly, and will list any pods that are still running older versions of the
proxy.

Congratulation! You have successfully upgraded your Linkerd to the newer
version.
