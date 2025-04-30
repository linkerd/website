---
title: Installing Multi-cluster Components
description: Allow Linkerd to manage cross-cluster communication.
---

Multicluster support in Linkerd requires extra installation and configuration on
top of the default [control plane installation](install/). This guide
walks through this installation and configuration as well as common problems
that you may encounter. For a detailed walkthrough and explanation of what's
going on, check out [getting started](multicluster/).

{{< docs/production-note >}}

## Requirements

- Two clusters.
- A [control plane installation](install/) in each cluster that shares
  a common
  [trust anchor](generate-certificates/#trust-anchor-certificate).
  If you have an existing installation, see the
  [trust anchor bundle](installing-multicluster/#trust-anchor-bundle)
  documentation to understand what is required.
- Each of these clusters should be configured as `kubectl`
  [contexts](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/).
- Elevated privileges on both clusters. We'll be creating service accounts and
  granting extended privileges, so you'll need to be able to do that on your
  test clusters.
- Support for services of type `LoadBalancer` in the `east` cluster. Check out
  the documentation for your cluster provider or take a look at
  [inlets](https://blog.alexellis.io/ingress-for-your-local-kubernetes-cluster/).
  This is what the `west` cluster will use to communicate with `east` via the
  gateway.

## Step 1: Install the multicluster control plane

In this step you'll install the extension's core components, plus the
controllers that will perform the service mirroring for each one of the target
clusters you wish to connect to. Here we'd like to be able to access the `east`
cluster from the `west` cluster; for this, the following config will suffice
(consult the [linkerd-multicluster chart
docs](https://artifacthub.io/packages/helm/linkerd2-edge/linkerd-multicluster)
for all the options available):

```yaml
controllers:
- link:
    ref:
      name: east
```

Assuming that's stored in `values.yaml`, run this in the `west` cluster:

```bash
linkerd multicluster install -f values.yaml | \
    kubectl apply -f -
```

And this in the `east` cluster:

```bash
linkerd multicluster install | \
    kubectl apply -f -
```

To verify that everything has started up successfully, run this on each cluster:

```bash
linkerd multicluster check
```

For a deep dive into what components are being added to your cluster and how all
the pieces fit together, check out the
[getting started documentation](multicluster/#preparing-your-cluster).

## Step 2: Link the clusters

Even though the controller is already set up in `west`, you still need to
complete the linkage by supplying a Link CR holding the configuration, and a
pair of secrets containing the kubeconfig allowing access to the target cluster
Kubernetes API. These can easily be created manually, or you can also use the
`linkerd multicluster link-gen` command:

```bash
linkerd --context=east multicluster link-gen --cluster-name east |
  kubectl --context=west apply -f -
```

To verify that the credentials were created successfully and the clusters are
able to reach each other, run:

```bash
linkerd --context=west multicluster check
```

The following command also gets you the list of gateways with their status:

```bash
linkerd --context=west multicluster gateways
```

For a detailed explanation of what this step does, check out the
[linking the clusters section](multicluster/#linking-the-clusters).

{{< note >}}
We present here a declarative, GitOps-compatible approach to establishing
multicluster links, available starting with Linkerd `v2.18`. In this method, the
controllers are integrated into the multicluster extension, allowing you to
supply the Link CR and kubeconfig secrets manifests directly, without
necessarily depending on the `linkerd multicluster link` command. This differs
from earlier versions of Linkerd (pre-`v2.18`), where (in addition to the Link
CR and secrets) controller manifests needed to be provided each time a new link
was created, requiring the use of the `linkerd multicluster link` command — a
process that was less suited to a GitOps workflow.
{{< /note >}}

## Step 3: Export services

Services are not automatically mirrored in linked clusters. By default, only
services with the `mirror.linkerd.io/exported` label will be mirrored. For each
service you would like mirrored to linked clusters, run:

```bash
kubectl label svc foobar mirror.linkerd.io/exported=true
```

{{< note >}}
You can use a different label selector by configuring it via the `spec.selector`
field in the Link CR. Or if you rely on the `linkerd multicluster link-gen`
command, using the `--selector` flag.
{{< /note >}}

## Trust Anchor Bundle

To secure the connections between clusters, Linkerd requires that there is a
shared trust anchor. This allows the control plane to encrypt the requests that
go between clusters and verify the identity of those requests. This identity is
used to control access to clusters, so it is critical that the trust anchor is
shared.

The easiest way to do this is to have a single trust anchor certificate shared
between multiple clusters. If you have an existing Linkerd installation and have
thrown away the trust anchor key, it might not be possible to have a single
certificate for the trust anchor. Luckily, the trust anchor can be a bundle of
certificates as well!

To fetch your existing cluster's trust anchor, run:

```bash
kubectl -n linkerd get cm linkerd-config -ojsonpath="{.data.values}" | \
  yq e .identityTrustAnchorsPEM - > trustAnchor.crt
```

{{< note >}} This command requires [yq](https://github.com/mikefarah/yq). If you
don't have yq, feel free to extract the certificate from the `identityTrustAnchorsPEM`
field with your tool of choice.
{{< /note >}}

Now, you'll want to create a new trust anchor and issuer for the new cluster:

```bash
step certificate create root.linkerd.cluster.local root.crt root.key \
   --profile root-ca --no-password --insecure
step certificate create identity.linkerd.cluster.local issuer.crt issuer.key \
  --profile intermediate-ca --not-after 8760h --no-password --insecure \
  --ca root.crt --ca-key root.key
```

{{< note >}} We use the [step cli](https://smallstep.com/cli/) to generate
certificates. `openssl` works just as well! {{< /note >}}

With the old cluster's trust anchor and the new cluster's trust anchor, you can
create a bundle by running:

```bash
cat trustAnchor.crt root.crt > bundle.crt
```

You'll want to upgrade your existing cluster with the new bundle. Make sure
every pod you'd like to have talk to the new cluster is restarted so that it can
use this bundle. To upgrade the existing cluster with this new trust anchor
bundle, run:

```bash
linkerd upgrade --identity-trust-anchors-file=./bundle.crt | \
    kubectl apply -f -
```

Finally, you'll be able to install Linkerd on the new cluster by using the trust
anchor bundle that you just created along with the issuer certificate and key.

```bash
# first, install the Linkerd CRDs on the new cluster
linkerd install --crds | kubectl apply -f -

# then, install the Linkerd control plane, using the key material we created
linkerd install \
  --identity-trust-anchors-file bundle.crt \
  --identity-issuer-certificate-file issuer.crt \
  --identity-issuer-key-file issuer.key | \
  kubectl apply -f -
```

Make sure to verify that the cluster's have started up successfully by running
`check` on each one.

```bash
linkerd check
```

## Installing the multicluster control plane components through Helm

Linkerd's multicluster components i.e the gateway and controllers can be
installed via Helm rather than the `linkerd multicluster install` command.

This not only allows advanced configuration, but also allows users to bundle the
multicluster installation as part of their existing Helm based installation
pipeline.

### Adding Linkerd's Helm repository

First, let's add the Linkerd's Helm repository by running

```bash
# To add the repo for Linkerd stable releases:
helm repo add linkerd https://helm.linkerd.io/stable
```

### Helm multicluster install procedure

```bash
helm install linkerd-multicluster -n linkerd-multicluster --create-namespace linkerd/linkerd-multicluster
```

The chart values will be picked from the chart's `values.yaml` file.

You can override the values in that file by providing your own `values.yaml`
file passed with a `-f` option, or overriding specific values using the family of
`--set` flags.

Full set of configuration options can be found [here](https://github.com/linkerd/linkerd2/tree/main/multicluster/charts/linkerd-multicluster#values)

The installation can be verified by running

```bash
linkerd multicluster check
```

Installation of the gateway can be disabled with the `gateway` setting. By
default this value is true.

### Installing additional access credentials

When the multicluster components are installed onto a target cluster with
`linkerd multicluster install`, a service account is created which source clusters
will use to mirror services.  Using a distinct service account for each source
cluster can be beneficial since it gives you the ability to revoke service mirroring
access from specific source clusters.  Generating additional service accounts
and associated RBAC can be done using the `linkerd multicluster allow` command
through the CLI.

The same functionality can also be done through Helm setting the
`remoteMirrorServiceAccountName` value to a list.

```bash
 helm install linkerd-mc-source linkerd/linkerd-multicluster -n linkerd-multicluster --create-namespace \
   --set remoteMirrorServiceAccountName={source1\,source2\,source3} --kube-context target
```

Now that the multicluster components are installed, operations like linking, etc
can be performed by using the linkerd CLI's multicluster sub-command as per the
[multicluster task](../features/multicluster/).
