+++
title = "Enabling Add-ons"
description = "Extend Linkerd's featureset with add-ons."
aliases = [
  "/2/add-ons/",
]
+++

Linkerd can also be installed with a
[number of Add-ons](https://github.com/linkerd/linkerd2/tree/stable-2.9.4/charts/add-ons),
allowing users to get a great out of the box experience around
popular service mesh use-cases.
These optional add-ons extend Linkerd with more features
and integrate well with the existing Linkerd installation and upgrade workflow.

Add-ons in Linkerd are optional and configurable. A configuration file is passed
to the install operation (available  both through Helm and CLI).
This configuration is also stored as a configmap called `linkerd-config-addons`,
allowing upgrades to work seamlessly without having user to pass the configuration
file again. Configuration can be updated [during upgrades](../upgrade/)
by applying configuration in the same manner as that of install.

{{< note >}}
Add-ons are available in Linkerd starting from version `edge-20.2.3`.
{{< /note>}}

You can find the list of add-ons present in the
[Linkerd2 Add-ons charts directory](https://github.com/linkerd/linkerd2/tree/stable-2.9.4/charts/add-ons)
along with their configuration options.

Now, let's understand some common concepts that are applicable across all add-ons.

## Add-ons Configuration

Add-ons can be toggled by using the `<addon-name>.enabled` field.

Apart from this, all the other flags will be specific to the add-on while making
sure common fields like `resources`, etc are referred in the same manner everywhere.

The following is an example configuration file w.r.t tracing Add-On.

```bash
cat > config.yaml << EOF
tracing:
  enabled: true
  collector:
    resources:
      cpu:
        limit: 100m
        request: 10m
      memory:
        limit: 100Mi
        request: 50Mi
EOF
```

The same configuration file can be used both through the CLI and Helm.

## Installation through CLI

linkerd CLI now supports a `config` flag, which is used to pass the configuration
of add-ons. Now, the above configuration file can be passed as

```bash
# Install Linkerd with additional configuration from `./config.yaml`
linkerd install --config ./config.yaml
```

The same `--config` is also available through upgrades to change existing configuration.

## Installation through Helm

First, You have to follow the
usual process of [installing Linkerd2 through Helm](../install-helm/),
. Only the final installation command is changed to include the Add-On configuration.

Now, we pass the add-on configuration file to the helm install command.

```bash
# Install Linkerd through Helm with additional configuration from `./config.yaml`
helm install \
  --name=linkerd2 \
  --set-file global.identityTrustAnchorsPEM=ca.crt \
  --set-file identity.issuer.tls.crtPEM=issuer.crt \
  --set-file identity.issuer.tls.keyPEM=issuer.key \
  --set identity.issuer.crtExpiry=$exp \
  --set global.controlPlaneTracing=true \
  -f config.yaml \
  linkerd-edge/linkerd2
```

Example of Tracing Add-On installation can be found [here](../distributed-tracing/)
