+++
title = "High Availability"
description = "The Linkerd control plane can run in high availability (HA) mode."
aliases = [
  "/2/ha/"
]
+++

For production workloads, Linkerd's control plane can run in high availability
(HA) mode. This mode:

* Runs three replicas of critical control plane components.
* Sets production-ready CPU and memory resource requests on control plane
  components.
* Sets production-ready CPU and memory resource requests on data plane proxies
* *Requires* that the [proxy auto-injector](/2/features/proxy-injection/) be
  functional for any pods to be scheduled.
* Sets [anti-affinity
  policies](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity)
  on critical control plane components to achieve, if possible, that they are
  scheduled on separate nodes and in separate zones by default. Optionally,
  the scheduling on separate nodes can be made a hard requirement using a flag.

## Enabling HA

You can enable HA mode at control plane installation time with the `--ha` flag:

```bash
linkerd install --ha | kubectl apply -f
```

You can override certain aspects of the HA behavior at installation time by
passing other flags to install. For example, you can override the number of
replicas for critical components with the `--controller-replicas` flag:

```bash
linkerd install --ha --controller-replicas=2 | kubectl apply -f
```

See the full [`install` CLI documentation](/2/reference/cli/install/) for
reference.

## Critical components

Replication and anti-affinity rules are applied to all control
plane components except Prometheus, Grafana, and the web service, which are
considered non-critical.

## Caveats

HA mode assumes that there are always at least three nodes in the Kubernetes
cluster. If this assumption is violated (e.g. the cluster is scaled down to two
or fewer nodes), then the system will likely be left in a non-functional state.

However, this behavior can be mitigated by applying a label to the `kube-system`
namespace to specify that it should be ignored by the proxy injector mutating
webhook:

```bash
kubectl label namespace kube-system config.linkerd.io/admission-webhooks=disabled
```
