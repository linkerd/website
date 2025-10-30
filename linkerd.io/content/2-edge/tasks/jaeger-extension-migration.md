---
title: Migrating away from the Linkerd-jaeger extension
description: Move from the deprecated Linkerd-jaeger extension to a modern distributed tracing setup.
---

Starting with the Linkerd 2.19 release, the Linkerd-jaeger extension will no
longer receive updates. It will continue to work with the Linkerd 2.19 release
and associated edge releases, but the extension is now unmaintained and may stop
working in a future Linkerd release.

## Migrating away from the extension

We recommend migrating away from the Linkerd-jaeger extension entirely and
install dedicated tracing infrastructure on your cluster instead, e.g. by
following our [guide to distributed tracing with Linkerd](distributed-tracing).

Once you have the tracing infrastructure inside your cluster that is not managed
by the extension, you can remove it safely from your cluster by running:

```bash
kubectl delete ns linkerd-jaeger
```

Then, restart all meshed pods.

## Using the Linkerd-jaeger trace collector

If you already rely on the tracing collector and Jaeger instance installed by
the extension, you may continue to use it as a temporary measure. Note that the
tracing collector and Jaeger used by the extension are very old versions, but
should continue to work with newer versions of Linkerd for the foreseeable
future.

First, in your Linkerd-jaeger installation, set the following values:

```yaml
webhook:
  enabled: false
```

{{< note >}}
The most recent versions of the Linkerd CLI no longer have the `linkerd jaeger`
commands. This guide assumes that you manage your Linkerd-jaeger installation
through Helm or another similar mechanism. If necessary, you can use an earlier
version of the CLI with these commands.
{{< /note >}}

Then, in your Linkerd control plane installation, set the following values:

```yaml
proxy:
  tracing:
    enabled: true
    collector:
      endpoint: collector.linkerd-jaeger:4317
      meshIdentity:
        serviceAccountName: collector
        namespace: linkerd-jaeger
```

{{< note >}}
This assumes you have made no changes to the collector configuration in your
Linkerd-jaeger installation. If you have changed the endpoint or already brought
your own tracing collector, you will have to update the `endpoint` as well as
the `serviceAccountName` and `namespace` in the `meshIdentity` in the above
config. See our [guide on distributed tracing](distributed-tracing) for more
information on how to set these values.
{{< /note >}}

Finally, restart all meshed pods.
