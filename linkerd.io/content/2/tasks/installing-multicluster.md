+++
title = "Installing Multi-cluster Components"
description = "Allow Linkerd to manage cross-cluster communication."
+++

Multicluster support in Linkerd requires extra installation and configuration on
top of the default [control plane installation](/2/tasks/install/). This guide
walks through this installation and configuration as well as common problems
that you may encounter. For a detailed walkthrough and explanation of what's
going on, check out [getting started](/2/tasks/multicluster/).

If you'd like to use an existing [Ambassador](https://www.getambassador.io/)
installation, check out the
[leverage](/2/tasks/installing-multicluster/#leverage-ambassador) instructions.
Alternatively, check out the Ambassador
[documentation](https://www.getambassador.io/docs/latest/howtos/linkerd2/#multicluster-operation)
for a more detailed explanation of the configuration and what's going on.

## Requirements

- Two clusters.
- A [control plane installation](/2/tasks/install/) in each cluster that shares
  a common
  [trust anchor](https://linkerd.io/2/tasks/generate-certificates/#trust-anchor-certificate).
  If you have an existing installation, see the
  [trust anchor bundle](/2/tasks/installing-multicluster/#trust-anchor-bundle)
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

On each cluster, run:

```bash
linkerd multicluster install | \
    kubectl apply -f -
```

To verify that everything has started up successfully, run:

```bash
linkerd check --multicluster
```

For a deep dive into what components are being added to your cluster and how all
the pieces fit together, check out the
[getting started documentation](/2/tasks/multicluster/#preparing-your-cluster).

## Step 2: Link the clusters

Each cluster must be linked. This consists of installing several resources in
the source cluster including a secret containing a kubeconfig that allows access
to the target cluster Kubernetes API, a service mirror control for mirroring
services, and a Link custom resource for holding configuration. To link cluster
`west` to cluster `east`, you would run:

```bash
linkerd --context=east multicluster link --cluster-name east |
  kubectl --context=west apply -f -
```

To verify that the credentials were created successfully and the clusters are
able to reach each other, run:

```bash
linkerd --context=west check --multicluster
```

You should also see the list of gateways show up by running:

```bash
linkerd --context=west multicluster gateways
```

For a detailed explanation of what this step does, check out the
[linking the clusters section](/2/tasks/multicluster/#linking-the-clusters).

## Step 3: Export services

Services are not automatically mirrored in linked clusters. By default, only
services with the `mirror.linkerd.io/exported` label will be mirrored. For each
service you would like mirrored to linked clusters, run:

```bash
kubectl label svc foobar mirror.linkerd.io/exported=true
```

{{< note >}} You can configure a different label selector by using the
`--selector` flag on the `linkerd multicluster link` command or by editing
the Link resource created by the `linkerd multicluster link` command.
{{< /note >}}

## Leverage Ambassador

The bundled Linkerd gateway is not required. In fact, if you have an existing
Ambassador installation, it is easy to use it instead! By using your existing
Ambassador installation, you avoid needing to manage multiple ingress gateways
and pay for extra cloud load balancers. This guide assumes that Ambassador has
been installed into the `ambassador` namespace.

First, you'll want to inject the `ambassador` deployment with Linkerd:

```bash
kubectl -n ambassador get deploy ambassador -o yaml | \
    linkerd inject \
    --skip-inbound-ports 80,443 \
    --require-identity-on-inbound-ports 4183 - | \
    kubectl apply -f -
```

This will add the Linkerd proxy, skip the ports that Ambassador is handling for
public traffic and require identity on the gateway port. Check out the
[docs](/2/tasks/multicluster/#security) to understand why it is important to
require identity on the gateway port.

Next, you'll want to add some configuration so that Ambassador knows how to
handle requests:

```bash
cat <<EOF | kubectl --context=${ctx} apply -f -
---
apiVersion: getambassador.io/v2
kind: Module
metadata:
  name: ambassador
  namespace: ambassador
spec:
  config:
    add_linkerd_headers: true
---
apiVersion: getambassador.io/v2
kind: Host
metadata:
  name: wildcard
  namespace: ambassador
spec:
  hostname: "*"
  selector:
    matchLabels:
      nothing: nothing
  acmeProvider:
    authority: none
  requestPolicy:
    insecure:
      action: Route
---
apiVersion: getambassador.io/v2
kind: Mapping
metadata:
  name: public-health-check
  namespace: ambassador
spec:
  prefix: /-/ambassador/ready
  rewrite: /ambassador/v0/check_ready
  service: localhost:8877
  bypass_auth: true
EOF
```

The Ambassador service and deployment definitions need to be patched a little
bit. This adds metadata required by the
[service mirror controller](https://linkerd.io/2020/02/25/multicluster-kubernetes-with-service-mirroring/#step-1-service-discovery).
To get these resources patched, run:

```bash
kubectl --context=${ctx} -n ambassador patch deploy ambassador -p='
spec:
    template:
        metadata:
            annotations:
                config.linkerd.io/enable-gateway: "true"
'
kubectl --context=${ctx} -n ambassador patch svc ambassador --type='json' -p='[
        {"op":"add","path":"/spec/ports/-", "value":{"name": "mc-gateway", "port": 4143}},
        {"op":"replace","path":"/spec/ports/0", "value":{"name": "mc-probe", "port": 80, "targetPort": 8080}}
    ]'
kubectl --context=${ctx} -n ambassador patch svc ambassador -p='
metadata:
    annotations:
        mirror.linkerd.io/gateway-identity: ambassador.ambassador.serviceaccount.identity.linkerd.cluster.local
        mirror.linkerd.io/multicluster-gateway: "true"
        mirror.linkerd.io/probe-path: /-/ambassador/ready
        mirror.linkerd.io/probe-period: "3"
'
```

Now you can install the Linkerd multicluster components onto your target cluster.
Since we're using Ambassador as our gateway, we need to skip installing the
Linkerd gateway by using the `--gateway=false` flag:

```bash
linkerd --context=${ctx} multicluster install --gateway=false | kubectl --context=${ctx} apply -f -
```

With everything setup and configured, you're ready to link a source cluster to
this Ambassador gateway.  Run the `link` command specifying the name and
namespace of your Ambassador service:

```bash
linkerd --context=${ctx} multicluster link --cluster-name=${ctx} --gateway-name=ambassador --gateway-namespace=ambassador \
    | kubectl --context=${src_ctx} apply -f -
```

From the source cluster (the one not running Ambassador), you can validate that
everything is working correctly by running:

```bash
linkerd check --multicluster
```

Additionally, the `ambassador` gateway will show up when listing the active
gateways:

```bash
linkerd multicluster gateways
```

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
  yq -r .global.identityTrustAnchorsPEM > trustAnchor.crt
```

{{< note >}} This command requires [yq](https://github.com/mikefarah/yq). If you
don't have yq, feel free to extract the certificate from the `global.identityTrustAnchorsPEM`
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

Linkerd's multicluster components i.e Gateway and Service Mirror can
be installed via Helm rather than the `linkerd multicluster install` command.

This not only allows advanced configuration, but also allows users to bundle the
multicluster installation as part of their existing Helm based installation
pipeline.

### Adding Linkerd's Helm repository

First, let's add the Linkerd's Helm repository by running

```bash
# To add the repo for Linkerd2 stable releases:
helm repo add linkerd https://helm.linkerd.io/stable
```

### Helm multicluster install procedure

```bash
helm install linkerd2-multicluster linkerd/linkerd2-multicluster
```

The chart values will be picked from the chart's `values.yaml` file.

You can override the values in that file by providing your own `values.yaml`
file passed with a `-f` option, or overriding specific values using the family of
`--set` flags.

Full set of configuration options can be found [here](https://github.com/linkerd/linkerd2/tree/main/charts/linkerd2-multicluster#configuration)

The installation can be verified by running

```bash
linkerd check --multicluster
```

Installation of the gateway can be disabled with the `gateway` setting. By
default this value is true.

### Installing additional access credentials

When the multicluster components are installed onto a target cluster with
`linkerd multicluster install`, a service account is created which source clusters
will use to mirror services.  Using a distinct service account for each source
cluster can be benefitial since it gives you the ability to revoke service mirroring
access from specific source clusters.  Generating additional service accounts
and associated RBAC can be done using the `linkerd multicluster allow` command
through the CLI.

The same functionality can also be done through Helm setting the
`remoteMirrorServiceAccountName` value to a list.

```bash
 helm install linkerd2-mc-source linkerd/linkerd2-multicluster --set remoteMirrorServiceAccountName={source1\,source2\,source3} --kube-context target
```

Now that the multicluster components are installed, operations like linking, etc
can be performed by using the linkerd CLI's multicluster sub-command as per the
[multicluster task](https://linkerd.io/2/features/multicluster).
