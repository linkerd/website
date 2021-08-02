+++
title = "Cluster Configuration"
description = "Configuration settings unique to providers and install methods."
+++

## GKE

### Private Clusters

If you are using a **private GKE cluster**, you are required to create a
firewall rule that allows the GKE operated api-server to communicate with the
Linkerd control plane. This makes it possible for features such as automatic
proxy injection to receive requests directly from the api-server.

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

Create the firewall rules for `proxy-injector` and `tap`:

```bash
gcloud compute firewall-rules create gke-to-linkerd-control-plane \
  --network "$NETWORK" \
  --allow "tcp:8443,tcp:8089" \
  --source-ranges "$MASTER_IPV4_CIDR" \
  --target-tags "$NETWORK_TARGET_TAG" \
  --priority 1000 \
  --description "Allow traffic on ports 8443, 8089 for linkerd control-plane components"
```

Finally, verify that the firewall is created:

```bash
gcloud compute firewall-rules describe gke-to-linkerd-control-plane
```
