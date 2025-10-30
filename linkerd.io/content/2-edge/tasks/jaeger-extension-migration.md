---
title: Migrating from the Linkerd-jaeger extension
description: A guide on how to use the most modern version tracing in Linkerd.
---

Starting with the Linkerd 2.19 release, the Linkerd-jaeger extension will no
longer receive updates. It will continue to work with the Linkerd 2.19 release
and associated edge, but the extension is now unmaintained and may stop working
in a future Linkerd release without warning.

## Migrating away from the extension

We recommend migrating away from the Linkerd-jaeger extension entirely and
install dedicated tracing infrastructure on your cluster instead. We provide a
[guide for installing a basic tracing setup](distributed-tracing) with
Linkerd.

Once you have the tracing infrastructure inside your cluster that is not managed
by the Linkerd-jaeger extension, you can remove the extension safely from your
cluster by running:

```bash
kubectl delete ns linkerd-jaeger
```

Then, restart all meshed pods.

## Using the Linkerd-jaeger trace collector

You may also continue to use the tracing collector and Jaeger instance provided
by the Linkerd. We do not recommend this as the tracing collector and Jaeger
used by the extension are very old versions, but these will continue to work
with new versions of Linkerd for the foreseeable future.

First, in your Linkerd-jaeger installation, set the following values:

```yaml
webhook:
  enabled: false
```

{{< note >}}
The most recent versions of the Linkerd CLI no longer have the
`linkerd jaeger` commands, which is one of the reasons we recommend against
keeping the extension in your cluster. This guide assumes that you manage your
Linkerd-jaeger installation through Helm or another similar mechanism.
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

Then, restart all meshed pods.
