+++
title = "Installing Linkerd"
description = "Install Linkerd to your own Kubernetes cluster."
aliases = [
  "/2/upgrading/",
  "/2/installing/",
  "/2/rbac/"
]
+++

Before you can use Linkerd, you'll need to install the
[control plane](/2/reference/architecture/#control-plane). This page
covers how to accomplish that, as well as common problems that you may
encounter.

Note that the control plane is typically installed by using Linkerd's CLI. See
[Getting Started](/2/getting-started/) for how to install the CLI onto your local
environment.

Note also that, once the control plane is installed, you'll need to "mesh" any
services you want Linkerd active for. See
[Adding Your Service](/2/adding-your-service/) for how to add Linkerd's data
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

Once you have a cluster ready, generally speaking, installing Linkerd is as
easy as running `linkerd install` to generate a Kubernetes manifest, and
applying that to your cluster, for example, via

```bash
linkerd install | kubectl apply -f -
```

See [Getting Started](/2/getting-started/) for an example.

Finally, after control plane installation, the `linkerd check` command (without
`--pre`) may be used to validate that the installation was successful.

Below we go through some common issues that may prevent successful
installation.

## Google Kubernetes Engine (GKE) clusters with RBAC enabled {#gke}

If you are using GKE with RBAC enabled, you first need to grant a `ClusterRole`
of `cluster-admin` to your Google Cloud account first. This will provide your
current user all the permissions required to install the control plane. To bind
this `ClusterRole` to your user, you can run:

```bash
kubectl create clusterrolebinding cluster-admin-binding-$USER \
    --clusterrole=cluster-admin --user=$(gcloud config get-value account)
```

### Using a private cluster on GKE {#gke-private-cluster}

If you are using a **private GKE cluster**, you are required to create a
Master-to-Node firewall rule to allow GKE to communicate to
`linkerd-proxy-injector` container endpoint port `tcp/8443`.

In this example, we will use [gcloud](https://cloud.google.com/sdk/install) to
simplify the creation of the said firewall rule.

Setup:

```bash
CLUSTER_NAME=your-cluster-name
gcloud config set compute/zone your-zone-or-region
```

Get the cluster `MASTER_IPV4_CIDR`:

```bash
MASTER_IPV4_CIDR=$(gcloud container clusters describe $CLUSTER_NAME \
  | grep "masterIpv4CidrBlock: " \
  | awk '{print $2}')
```

Get the cluster `NETWORK`:

```bash
NETWORK=$(gcloud container clusters describe $CLUSTER_NAME \
  | grep "^network: " \
  | awk '{print $2}')
```

Get the cluster auto-generated `NETWORK_TARGET_TAG`:

```bash
NETWORK_TARGET_TAG=$(gcloud compute firewall-rules list \
  --filter network=$NETWORK --format json \
  | jq ".[] | select(.name | contains(\"$CLUSTER_NAME\"))" \
  | jq -r '.targetTags[0]' | head -1)
```

The format of the network tag should be something like `gke-cluster-name-xxxx-node`.

Verify the values:

```bash
echo $MASTER_IPV4_CIDR $NETWORK $NETWORK_TARGET_TAG

# example output
10.0.0.0/28 foo-network gke-foo-cluster-c1ecba83-node
```

Create the firewall rule:

```bash
gcloud compute firewall-rules create gke-to-linkerd-proxy-injector-8443 \
  --network "$NETWORK" \
  --allow "tcp:8443" \
  --source-ranges "$MASTER_IPV4_CIDR" \
  --target-tags "$NETWORK_TARGET_TAG" \
  --priority 1000
```

Finally, verify that the firewall is created:

```bash
gcloud compute firewall-rules describe gke-to-linkerd-proxy-injector-8443
```

## Uninstalling

See [Uninstalling Linkerd](/2/tasks/uninstall/).
