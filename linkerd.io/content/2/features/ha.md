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
linkerd install --ha | kubectl apply -f -
```

You can override certain aspects of the HA behavior at installation time by
passing other flags to install. For example, you can override the number of
replicas for critical components with the `--controller-replicas` flag:

```bash
linkerd install --ha --controller-replicas=2 | kubectl apply -f -
```

See the full [`install` CLI documentation](/2/reference/cli/install/) for
reference.

To enable HA mode on an existing control plane:

```bash
linkerd upgrade --ha | kubectl apply -f -
```

## Proxy injector failure policy

The HA proxy injector is deployed with a stricter failure policy to enforce
[proxy injection](/2/features/proxy-injection/). This setup ensures that no
un-injected annotated workloads are accidentally scheduled to run on your
cluster.

If proxy injection failed due to unrecognized or timeout errors during the
admission phase, the workload admission will be rejected by the Kubernetes API
server, and the workload will not be deployed.

Hence, it is very important that there is always at least one healthy replica
of the proxy injector webhook running on your cluster.

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

Per recommendation in the Kubernetes
[documentation](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/#avoiding-operating-on-the-kube-system-namespace),
the proxy injector should be disabled for the `kube-system` namespace.

This can be done by labeling the `kube-system` namespace with the following
label:

```bash
kubectl label namespace kube-system config.linkerd.io/admission-webhooks=disabled
```

The Kubernetes API server will omit the proxy injector from the admission phase
of all workloads in namespaces with this label.

If your Kubernetes cluster have built-in reconcilers that would revert any changes
made to the `kube-system` namespace, you should loosen the proxy injector
failure policy following these [instructions](#proxy-injector-failure-policy).

## Pod anti-affinity rules

All critical control plane components are deployed with pod anti-affinity rules
to ensure redundancy.

Linkerd uses a `requiredDuringSchedulingIgnoredDuringExecution` pod
anti-affinity rule to ensure that the Kubernetes scheduler does not colocate
replicas on the same node. A `preferredDuringSchedulingIgnoredDuringExecution`
pod anti-affinity rule is also added to try to schedule replicas in different
zones, where possible.

Note that these anti-affinity rules don't apply to add-on components like
Prometheus, Grafana and the web service.

## Caveats

HA mode assumes that there are always at least three nodes in the Kubernetes
cluster. If this assumption is violated (e.g. the cluster is scaled down to
two or fewer nodes), then the system will likely be left in a non-functional
state.
