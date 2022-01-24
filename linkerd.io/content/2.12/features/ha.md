+++
title = "High Availability"
description = "The Linkerd control plane can run in high availability (HA) mode."
aliases = [
  "../ha/"
]
+++

For production workloads, Linkerd's control plane can run in high availability
(HA) mode. This mode:

* Runs three replicas of critical control plane components.
* Sets production-ready CPU and memory resource requests on control plane
  components.
* Sets production-ready CPU and memory resource requests on data plane proxies
* *Requires* that the [proxy auto-injector](../proxy-injection/) be
  functional for any pods to be scheduled.
* Sets [anti-affinity
  policies](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity)
  on critical control plane components to ensure, if possible, that they are
  scheduled on separate nodes and in separate zones by default.

## Enabling HA

You can enable HA mode at control plane installation time with the `--ha` flag:

```bash
linkerd install --ha | kubectl apply -f -
```

Also note the Viz extension also supports an `--ha` flag with similar
characteristics:

```bash
linkerd viz install --ha | kubectl apply -f -
```

You can override certain aspects of the HA behavior at installation time by
passing other flags to the `install` command. For example, you can override the
number of replicas for critical components with the `--controller-replicas`
flag:

```bash
linkerd install --ha --controller-replicas=2 | kubectl apply -f -
```

See the full [`install` CLI documentation](../../reference/cli/install/) for
reference.

The `linkerd upgrade` command can be used to enable HA mode on an existing
control plane:

```bash
linkerd upgrade --ha | kubectl apply -f -
```

## Proxy injector failure policy

The HA proxy injector is deployed with a stricter failure policy to enforce
[automatic proxy injection](../proxy-injection/). This setup ensures
that no annotated workloads are accidentally scheduled to run on your cluster,
without the Linkerd proxy. (This can happen when the proxy injector is down.)

If proxy injection process failed due to unrecognized or timeout errors during
the admission phase, the workload admission will be rejected by the Kubernetes
API server, and the deployment will fail.

Hence, it is very important that there is always at least one healthy replica
of the proxy injector running on your cluster.

If you cannot guarantee the number of healthy proxy injector on your cluster,
you can loosen the webhook failure policy by setting its value to `Ignore`, as
seen in the
[Linkerd Helm chart](https://github.com/linkerd/linkerd2/blob/803511d77b33bd9250b4a7fecd36752fcbd715ac/charts/linkerd2/templates/proxy-injector-rbac.yaml#L98).

{{< note >}}
See the Kubernetes
[documentation](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/#failure-policy)
for more information on the admission webhook failure policy.
{{< /note >}}

## Exclude the kube-system namespace

Per recommendation from the Kubernetes
[documentation](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/#avoiding-operating-on-the-kube-system-namespace),
the proxy injector should be disabled for the `kube-system` namespace.

This can be done by labeling the `kube-system` namespace with the following
label:

```bash
kubectl label namespace kube-system config.linkerd.io/admission-webhooks=disabled
```

The Kubernetes API server will not call the proxy injector during the admission
phase of workloads in namespace with this label.

If your Kubernetes cluster have built-in reconcilers that would revert any changes
made to the `kube-system` namespace, you should loosen the proxy injector
failure policy following these [instructions](#proxy-injector-failure-policy).

## Pod anti-affinity rules

All critical control plane components are deployed with pod anti-affinity rules
to ensure redundancy.

Linkerd uses a `requiredDuringSchedulingIgnoredDuringExecution` pod
anti-affinity rule to ensure that the Kubernetes scheduler does not colocate
replicas of critical component on the same node. A
`preferredDuringSchedulingIgnoredDuringExecution` pod anti-affinity rule is also
added to try to schedule replicas in different zones, where possible.

In order to satisfy these anti-affinity rules, HA mode assumes that there
are always at least three nodes in the Kubernetes cluster. If this assumption is
violated (e.g. the cluster is scaled down to two or fewer nodes), then the
system may be left in a non-functional state.

Note that these anti-affinity rules don't apply to add-on components like
Prometheus.

## Scaling Prometheus

The Linkerd Viz extension provides a pre-configured Prometheus pod, but for
production workloads we recommend setting up your own Prometheus instance. To
scrape the data plane metrics, follow the instructions
[here](../../tasks/external-prometheus/). This will provide you
with more control over resource requirement, backup strategy and data retention.

When planning for memory capacity to store Linkerd timeseries data, the usual
guidance is 5MB per meshed pod.

If your Prometheus is experiencing regular `OOMKilled` events due to the amount
of data coming from the data plane, the two key parameters that can be adjusted
are:

* `storage.tsdb.retention.time` defines how long to retain samples in storage.
  A higher value implies that more memory is required to keep the data around
  for a longer period of time. Lowering this value will reduce the number of
  `OOMKilled` events as data is retained for a shorter period of time
* `storage.tsdb.retention.size` defines the maximum number of bytes that can be
  stored for blocks. A lower value will also help to reduce the number of
  `OOMKilled` events

For more information and other supported storage options, see the Prometheus
documentation
[here](https://prometheus.io/docs/prometheus/latest/storage/#operational-aspects).

## Working with Cluster AutoScaler

The Linkerd proxy stores its mTLS private key in a
[tmpfs emptyDir](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir)
volume to ensure that this information never leaves the pod. This causes the
default setup of Cluster AutoScaler to not be able to scale down nodes with
injected workload replicas.

The workaround is to annotate the injected workload with the
`cluster-autoscaler.kubernetes.io/safe-to-evict: "true"` annotation. If you
have full control over the Cluster AutoScaler configuration, you can start the
Cluster AutoScaler with the `--skip-nodes-with-local-storage=false` option.

For more information on this, see the Cluster AutoScaler documentation
[here](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/FAQ.md#what-types-of-pods-can-prevent-ca-from-removing-a-node).
