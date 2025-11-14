---
title: Automatic Multicluster Failover
description: Use the Linkerd Failover extension to failover between clusters.
---

The Linkerd Failover extension is a controller which automatically shifts
traffic from a primary service to one or more fallback services whenever the
primary becomes unavailable. This can help add resiliency when you have a
service which is replicated in multiple clusters. If the local service is
unavailable, the failover controller can shift that traffic to the backup
cluster.

Let's see a simple example of how to use this extension by installing the
Emojivoto application on two Kubernetes clusters and simulating a failure in one
cluster. We will see the failover controller shift traffic to the other cluster
to ensure the service remains available.

{{< docs/production-note >}}

## Prerequisites

You will need two clusters with Linkerd installed and for the clusters to be
linked together with the multicluster extension. Follow the steps in the
[multicluster guide](multicluster/) to generate a shared trust root, install
Linkerd, Linkerd Viz, and Linkerd Multicluster, and to link the clusters
together. For the remainder of this guide, we will assume the cluster context
names are "east" and "west" respectively. Please substitute your cluster context
names where appropriate.

## Installing the Failover Extension

Failovers are described using SMI
[TrafficSplit](https://github.com/servicemeshinterface/smi-spec/blob/main/apis/traffic-split/v1alpha1/traffic-split.md)
resources. We install the Linkerd SMI extension and the Linkerd Failover
extension. These can be installed in both clusters, but since we'll only be
initiating failover from the "west" cluster in this example, we'll only install
them in that cluster:

```bash
# Install linkerd-smi in west cluster
> helm --kube-context=west repo add linkerd-smi https://linkerd.github.io/linkerd-smi
> helm --kube-context=west repo up
> helm --kube-context=west install linkerd-smi -n linkerd-smi --create-namespace linkerd-smi/linkerd-smi

# Install linkerd-failover in west cluster
> helm --kube-context=west repo add linkerd-edge https://helm.linkerd.io/edge
> helm --kube-context=west repo up
> helm --kube-context=west install linkerd-failover -n linkerd-failover --create-namespace --devel linkerd-edge/linkerd-failover
```

## Installing and Exporting Emojivoto

We'll now install the Emojivoto example application into both clusters:

```bash
> linkerd --context=west inject https://run.linkerd.io/emojivoto.yml | kubectl --context=west apply -f -
> linkerd --context=east inject https://run.linkerd.io/emojivoto.yml | kubectl --context=east apply -f -
```

Next we'll "export" the `web-svc` in the east cluster by setting the
`mirror.linkerd.io/exported=true` label. This will instruct the multicluster
extension to create a mirror service called `web-svc-east` in the west cluster,
making the east Emojivoto application available in the west cluster:

```bash
> kubectl --context=east -n emojivoto label svc/web-svc mirror.linkerd.io/exported=true
> kubectl --context=west -n emojivoto get svc
NAME          TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)             AGE
emoji-svc     ClusterIP   10.96.41.137    <none>        8080/TCP,8801/TCP   13m
voting-svc    ClusterIP   10.96.247.68    <none>        8080/TCP,8801/TCP   13m
web-svc       ClusterIP   10.96.222.169   <none>        80/TCP              13m
web-svc-east  ClusterIP   10.96.244.245   <none>        80/TCP              92s
```

## Creating the Failover TrafficSplit

To tell the failover controller how to failover traffic, we need to create a
TrafficSplit resource in the west cluster with the
`failover.linkerd.io/controlled-by: linkerd-failover` label. The
`failover.linkerd.io/primary-service` annotation indicates that the `web-svc`
backend is the primary and all other backends will be treated as the fallbacks:

```bash
> cat <<EOF | kubectl --context=west apply -f -
apiVersion: split.smi-spec.io/v1alpha2
kind: TrafficSplit
metadata:
    name: web-svc-failover
    namespace: emojivoto
    labels:
        failover.linkerd.io/controlled-by: linkerd-failover
    annotations:
        failover.linkerd.io/primary-service: web-svc
spec:
    service: web-svc
    backends:
        - service: web-svc
          weight: 1
        - service: web-svc-east
          weight: 0
EOF
```

This TrafficSplit indicates that the local (west) `web-svc` should be used as
the primary, but traffic should be shifted to the remote (east) `web-svc-east`
if the primary becomes unavailable.

## Testing the Failover

We can use the `linkerd viz stat` command to see that the `vote-bot` traffic
generator in the west cluster is sending traffic to the local primary service,
`web-svc`:

```bash
> linkerd --context=west viz stat -n emojivoto svc --from deploy/vote-bot
NAME          MESHED   SUCCESS      RPS   LATENCY_P50   LATENCY_P95   LATENCY_P99   TCP_CONN
web-svc            -    96.67%   2.0rps           2ms           3ms           5ms          1
web-svc-east       -         -        -             -             -             -          -
```

Now we'll simulate the local service becoming unavailable by scaling it down:

```bash
> kubectl --context=west -n emojivoto scale deploy/web --replicas=0
```

We can immediately see that the TrafficSplit has been adjusted to send traffic
to the backup. Notice that the `web-svc` backend now has weight 0 and the
`web-svc-east` backend now has weight 1.

```bash
> kubectl --context=west -n emojivoto get ts/web-svc-failover -o yaml
apiVersion: split.smi-spec.io/v1alpha2
kind: TrafficSplit
metadata:
  annotations:
    failover.linkerd.io/primary-service: web-svc
  creationTimestamp: "2022-03-22T23:47:11Z"
  generation: 4
  labels:
    failover.linkerd.io/controlled-by: linkerd-failover
  name: web-svc-failover
  namespace: emojivoto
  resourceVersion: "10817806"
  uid: 77039fb3-5e39-48ad-b7f7-638d187d7a28
spec:
  backends:
  - service: web-svc
    weight: 0
  - service: web-svc-east
    weight: 1
  service: web-svc
```

We can also confirm that this traffic is going to the fallback using the
`viz stat` command:

```bash
> linkerd --context=west viz stat -n emojivoto svc --from deploy/vote-bot
NAME          MESHED   SUCCESS      RPS   LATENCY_P50   LATENCY_P95   LATENCY_P99   TCP_CONN
web-svc            -         -        -             -             -             -          -
web-svc-east       -    93.04%   1.9rps          25ms          30ms          30ms          1
```

Finally, we can restore the primary by scaling its deployment back up and
observe the traffic shift back to it:

```bash
> kubectl --context=west -n emojivoto scale deploy/web --replicas=1
deployment.apps/web scaled
> linkerd --context=west viz stat -n emojivoto svc --from deploy/vote-bot
NAME          MESHED   SUCCESS      RPS   LATENCY_P50   LATENCY_P95   LATENCY_P99   TCP_CONN
web-svc            -    89.29%   1.9rps           2ms           4ms           5ms          1
web-svc-east       -         -        -             -             -             -          -
```
