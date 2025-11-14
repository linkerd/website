---
title: Cluster Configuration
description: Configuration settings unique to providers and install methods.
---

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

The format of the network tag should be something like
`gke-cluster-name-xxxx-node`.

Verify the values:

```bash
echo $MASTER_IPV4_CIDR $NETWORK $NETWORK_TARGET_TAG

# example output
10.0.0.0/28 foo-network gke-foo-cluster-c1ecba83-node
```

Create the firewall rules for `proxy-injector`, `policy-validator` and `tap`:

```bash
gcloud compute firewall-rules create gke-to-linkerd-control-plane \
  --network "$NETWORK" \
  --allow "tcp:8443,tcp:8089,tcp:9443" \
  --source-ranges "$MASTER_IPV4_CIDR" \
  --target-tags "$NETWORK_TARGET_TAG" \
  --priority 1000 \
  --description "Allow traffic on ports 8443, 8089, 9443 for linkerd control-plane components"
```

Finally, verify that the firewall is created:

```bash
gcloud compute firewall-rules describe gke-to-linkerd-control-plane
```

## Cilium

### Turn Off Socket-Level Load Balancing

Cilium can be configured to replace kube-proxy functionality through eBPF. When
running in kube-proxy replacement mode, connections to a `ClusterIP` service
will be established directly to the service's backend at the socket level (i.e.
during TCP connection establishment). Linkerd relies on `ClusterIPs` being
present on packets in order to do service discovery.

When packets do not contain a `ClusterIP` address, Linkerd will instead forward
directly to the pod endpoint that was selected by Cilium. Consequentially, while
mTLS and telemetry will still function correctly, features such as peak EWMA
load balancing, and
[dynamic request routing](../tasks/configuring-dynamic-request-routing/) may not
work as expected.

This behavior can be turned off in Cilium by
[turning off socket-level load balancing for pods](https://docs.cilium.io/en/v1.13/network/istio/#setup-cilium)
through the CLI option `--config bpf-lb-sock-hostns-only=true`, or through the
Helm value `socketLB.hostNamespaceOnly=true`.

### Disable Exclusive Mode

If you're using Cilium as your CNI and then want to install
[linkerd-cni](../features/cni/) on top of it, make sure you install Cilium with
the option `cni.exclusive=false`. This avoids Cilium taking ownership over the
CNI configurations directory. Other CNI plugins like linkerd-cni install
themselves and operate in chain mode with the other deployed plugins by
deploying their configuration into this directory.

## Lifecycle Hook Timeout

Linkerd uses a `postStart` lifecycle hook for all control plane components, and
all injected workloads by default. The hook will poll proxy readiness through
[linkerd-await](https://github.com/linkerd/linkerd-await) and block the main
container from starting until the proxy is ready to handle traffic. By default,
the hook will time-out in 2 minutes.

CNI plugins that are responsible for setting up and enforcing `NetworkPolicy`
resources can interfere with the lifecycle hook's execution. While lifecycle
hooks are running, the container will not reach a `Running` state. Some CNI
plugin implementations acquire the Pod's IP address only after all containers
have reached a running state, and the kubelet has updated the Pod's status
through the API Server. Without access to the Pod's IP, the CNI plugins will not
operate correctly. This in turn will block the proxy from being set-up, since it
does not have the necessary network connectivity.

As a workaround, users can manually remove the `postStart` lifecycle hook from
control plane components. For injected workloads, users may opt out of the
lifecycle hook through the root-level `await: false` option, or alternatively,
behavior can be overridden at a workload or namespace level through the
annotation `config.linkerd.io/proxy-await: disabled`. Removing the hook will
allow containers to start asynchronously, unblocking network connectivity once
the CNI plugin receives the pod's IP.
