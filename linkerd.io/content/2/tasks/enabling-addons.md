+++
title = "Enabling Add-Ons"
description = "Great Out-of-the-box experience with various components that integrate well with Linkerd"
aliases = [
  "/2/add-ons/",
]
+++

Linkerd can also be installed with a number of add-ons, allowing users to get a
great out of the box experience around popular service mesh use-cases.
These Add-On's are coupled with the control plane installation
and integrate well with Linkerd.

Add-Ons in Linkerd are optional and configurable. A configuration file is passed
to the install operation (avaialable  both through Helm and CLI).
This config is also stored as a configmap called `linkerd-values`,
allowing upgrades to work seamlessly
without having user to pass the config file again.
Configuration can be updated [during upgrades](https://linkerd.io/2/tasks/upgrade/).

{{< note >}}
Add-on's are available in Linkerd starting from `edge-20.2.3`.
{{< /note>}}

You can find the list of add-ons present in the
[Linkerd2 Add-On's charts directory](https://github.com/linkerd/linkerd2/tree/master/charts/add-ons).

Now, Let us see the installation of the Tracing Add-On. In this demo, We
also enable enable the `control-plane-tracing` flag which would,
make the control-plane components send traces to the collector.

Other Add-Ons would also have a similar installation approach.

## Add-Ons Configuration

The following is the Add-On configuration file, that will be passed to installation.
Here we configure the Tracing Add-On to be enabled, and also overwrite the trace
collector's resources. If values are not overwritten, The default values will be
used.

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

Make sure you have the CLI installed, with an edge release > 2.7.1

linkerd CLI now supports a `addon-config` flag, which is used to pass the confiugration
of add-ons. Now, the above configuration file can be passed as

```bash
# Install with control plane tracing enabled, and a add-on configuration file
linkerd install --control-plane-tracing --addon-config ./config.yaml
```

## Installation through Helm

First, You have to follow the
[usual process of installing Linkerd2 through Helm](https://linkerd.io/2/tasks/install-helm/),
. Only the final installation command is changed to include the add-on configuration.

Now, we pass the add-on configuration file to the helm install command.

```bash
# Install with control plane tracing enabled, and a add-on configuration file
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

## Tracing Demo

First, you should also see two new components be installed
i.e `linkerd-collector` and `linkerd-jaeger`.

```bash
$ kubectl -n linkerd  get deployments
NAME                     READY   UP-TO-DATE   AVAILABLE   AGE
linkerd-collector        1/1     1            1           4m11s
linkerd-controller       1/1     1            1           4m11s
linkerd-destination      1/1     1            1           4m11s
linkerd-grafana          1/1     1            1           4m11s
linkerd-identity         1/1     1            1           4m11s
linkerd-jaeger           1/1     1            1           4m11s
linkerd-prometheus       1/1     1            1           4m11s
linkerd-proxy-injector   1/1     1            1           4m11s
linkerd-smi-metrics      1/1     1            1           4m11s
linkerd-sp-validator     1/1     1            1           4m11s
linkerd-tap              1/1     1            1           4m11s
linkerd-web              1/1     1            1           4m11s
```

Now, The control-plane components traces, along with the linkerd-proxy traces are
sent to the `linkerd-collector`, which are then sent to the `linkerd-jaeger`.
These Traces can be viewed in the jaeger UI by port-forwarding the service as

```bash
kubectl -n linkerd port-forward svc/linkerd-jaeger 16686:16686
```

Traces from the control-plane components can be viewed at `localhost:16886`
