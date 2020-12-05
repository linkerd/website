+++
title = "Getting started with Service Topologies"
description = "Learn preference-based traffic routing with Linkerd using Service Topologies"
+++

In this guide, you'll learn how Service Topologies work in Linkerd by
deploying the Emojivoto pods to specific nodes in a cluster using taints and
tolerations. These nodes will include values for the
`topology.kubernetes.io/region` and `topology.kubernetes.io/zone` labels.

## Install k3d and Create a Cluster

For this walkthrough, we'll use [k3d](https://k3d.io/#installation) to deploy a
multi-node cluster with the EndpointSlices and ServiceTopology feature gates
enabled. The Kubernetes version must be at least 1.17 to use the ServiceTopology
feature. Please refer to the [Kubernetes Feature Gate](https://kubernetes.io/docs/reference/command-line-tools-reference/feature-gates/)
docs for details about the versions of Kubernetes for which the EndpointSlices
and ServiceTopology featuers are enabled.

If you have access to a multi-node cluster with EndpointSlices and
ServiceTopology enabled, you can skip this section.

{{< note >}} Unfortunately, there is no standard way to check which feature
gates are enabled for a Kubernetes cluster. If you are using a cluster managed
by cloud pprovider, be sure to check the cloud provider's documentation to
learn how to see the status of the feature gates.

### Create the cluster

Once you have verified that k3d is installed, run the command below to create a
cluster of three k3s v1.19.3 nodes with the EndpointSlices and ServiceTopology
feature gates enabled.

```bash
k3d cluster create linkerd-st --k3s-server-arg '--kube-apiserver-arg=feature-gates=EndpointSlice=true,EndpointSliceProxying=true,ServiceTopology=true' --servers 3 --image docker.io/rancher/k3s:v1.19.3-k3s2
```

When the command returns successfully, run the command `k3d node list` to see
all the nodes that were just created. In the output, you can see that the k3d
naming convention for the servers is `k3d-linkerd-st-server-N`. In the next
section you will add taints and labels to each of these servers (not the load
balancer)

```bash
$ k3d node list
NAME                      ROLE           CLUSTER      STATUS
k3d-linkerd-st-server-0   server         linkerd-st   running
k3d-linkerd-st-server-1   server         linkerd-st   running
k3d-linkerd-st-server-2   server         linkerd-st   running
k3d-linkerd-st-serverlb   loadbalancer   linkerd-st   running
```

When the `kubectl get node` command shows that all nodes are ready, move on to
the next step.

### Install Linkerd

```bash
curl -sL https://run.linkerd.io/install | sh
```

## Configure the nodes in the cluster

In this section you will add taints and labels to the nodes in the cluster. The
taints enable you to force the emojivoto pods to be deployed to specific nodes
and the labels are matched by the ServiceTopology feature to route the traffic.

### Taints

The following taints are used along with tolerations on the emojivoto
deployments to ensure that Pods are deployed to specific nodes.

```bash
kubectl taint node k3d-linkerd-st-server-0 emojivoto=zone:NoSchedule
kubectl taint node k3d-linkerd-st-server-1 emojivoto=region:NoSchedule
kubectl taint node k3d-linkerd-st-server-2 emojivoto=hostname:NoSchedule
```

### Labels

These labels are used by the `topologyKeys` in the emojivoto PodSpecs to
enable traffic routing between pods on specific nodes

```bash
kubectl label node k3d-linkerd-st-server-0 topology.kubernetes.io/region=east topology.kubernetes.io/zone=us
kubectl label node k3d-linkerd-st-server-1 topology.kubernetes.io/region=west topology.kubernetes.io/zone=us
kubectl label node k3d-linkerd-st-server-2 topology.kubernetes.io/region=east topology.kubernetes.io/zone=asia
```

## Review and Deploy modified emojivoto

To test the ServiceTopology feature, we'll use a version of emojivoto whose
Deployments have been modified with tolerations so that the Pods are deployed to
nodes with the matching taints that were added in above.

For example, the PodSpec for the `voting` deployment has a toleration for nodes
with taint `emojivoto=region`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app.kubernetes.io/name: voting
    app.kubernetes.io/part-of: emojivoto
    app.kubernetes.io/version: v10
  name: voting
  namespace: emojivoto
spec:
  ...
  template:
    ...
    spec:
      tolerations:
      - key: "emojivoto"
        operator: "Equal"
        value: "region"
        effect: "NoSchedule"
```

You are encouraged to review all the tolerations in the Deployments to
understand that they are distributed as follows:

- voting is deployed to nodes with taint `emojivoto=region`
  (k3d-linkerd-st-server-1)
- emoji is deployed to nodes with taint `emojivoto=hostname`
  (k3d-linkerd-st-server-2)
- web is deployed to nodes with taint `emojivoto=zone`
  (k3d-linkerd-st-server-0)
- vote-bot is deployed to any node

-- topologyKeys

```bash
$ kubectl po -n emojivoto -owide
NAME                        READY   STATUS    RESTARTS   AGE   IP           NODE                      NOMINATED NODE   READINESS GATES
emoji-d58454574-c96hx       2/2     Running   0          15s   10.42.2.9    k3d-linkerd-st-server-2   <none>           <none>
vote-bot-74566c9df9-vc426   2/2     Running   0          15s   10.42.1.8    k3d-linkerd-st-server-1   <none>           <none>
voting-ff8977d46-lf25l      2/2     Running   0          15s   10.42.1.9    k3d-linkerd-st-server-1   <none>           <none>
web-85964ffd98-rr97k        2/2     Running   0          15s   10.42.0.10   k3d-linkerd-st-server-0   <none>           <none>
```

## View traffic

-- linkerd stat
-- linkerd metrics
-- linkerd edges

## Relabel Nodes
