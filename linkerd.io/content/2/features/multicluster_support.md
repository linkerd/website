+++
title = "Multicluster support"
description = "Linkerd provides service discovery across clusters"
+++


Linkerd provides service discovery across clusters. This means that it is
possible to address services that live on remote clusters as if they were
local ones. The latter enables one to use all the features that Linkerd
provides such as automatic mTLS, traffic splitting and observability across
clusters.

In this tutorial, we will demonstrate how you can split traffic between
services that live on different clusters.

## Prerequisites

To begin with, we assume that you have two distinct clusters and your `kubectl`
is configured with two contexts `remote` and `local`. In our scenario the local
cluster is one that is hosted on a development machine while the `remote` lives
on the cloud. Additionally you need to ensure that you have Linkerd installed on
both clusters and that the certificates used by both installations share the same
trust anchors.

## Installing the service mirroring component

Linkerd contains a component, which is responsible for continuously monitoring
a set of remote clusters and mirroring exported services from these clusters.
In order to install it you can run the following command:

```bash
 linkerd --context=local install-service-mirror | kubectl --context=local apply -f -
```

## Creating mirroring credentials on the remote cluster

The way the service mirroring component operates is that is establishes watches
to remote clusters. For that purpose it needs to have the required credentials
to access remote services through the Kubernetes API. In order to install these
credentials on the remote cluster you can run the following command:

```bash
linkerd --context=remote cluster create-credentials | kubectl --context=remote apply -f -
```

This will provision `ServiceAccount`, `ClusterRoleBinding` and a `ClusterRole`
with the necessary RBAC onto the remote cluster.

## Enabling mirroring of services

The service mirroring component, watches for secrets that contain credentials
for remote clusters. When such a secret is created, the component starts to
mirror services from the remote cluster. In order to generate this secret and
deploy it on the local cluster you can run:

```bash
linkerd --context=remote cluster get-credentials --cluster-name=remote | kubectl --context=local apply -f -
```

## Deploying the service gateway on the remote cluster

Incoming cluster traffic needs to go through a gateway. This is why every
mirrored service needs to specify the gateway that knows how to route traffic
to it. The gateway implementation can be completely bespoke as long as it knows
how to route traffic to in-cluster services. For your convenience we have
provided a reference implementation that you can use and improve. In order to
install it, run the following command:

```bash
kubectl --context=remote apply -f https://run.linkerd.io/multicluster-gateway.yml
```

Normally, you would like this gateway pod to be meshed so we get all the
benefits of Linkerd. You can inject it by running:

```bash
kubectl --context=remote get deploy linkerd-gateway -o yaml  \
                        | linkerd --context=remote  inject - \
                        | kubectl  --context=remote apply -f -
```

## Installing the test services

Now that you have everything setup, you can deploy some services on the remote
cluster and access them from the local one. You can do that with:

```bash
linkerd --context=remote inject https://run.linkerd.io/remote-services.yml | kubectl --context=remote apply -
```

This will deploy two services `backend-one-svc` and `backend-two-svc` that
both listen on port 8888 and serve slightly different responses.

## Exporting the services

Now that you have all credentials setup you can use the Linkerd CLI to export
the services, making them available to the local cluster. Simply run:

```bash
linkerd --context=remote cluster export-service \
                     --service-name=backend-one-svc \
                     --service-namespace=default \
                     --gateway-name=linkerd-gateway \
                     --gateway-ns=default
linkerd --context=remote cluster export-service \
                     --service-name=backend-two-svc \
                     --service-namespace=default \
                     --gateway-name=linkerd-gateway \
                     --gateway-ns=default
```

You should see something similar to:

```text
Service default/backend-one-svc is now exported
Service default/backend-two-svc is now exported
```

At that point these services should be mirrored on your local cluster. To
ensure this is the case you can do:

```bash
kubectl --context=local get services --all-namespaces
```

You should see something similar to:

```text
NAMESPACE     NAME                     TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                  AGE
default       backend-one-svc-remote   ClusterIP   10.102.82.188    <none>        8888/TCP                 27s
default       backend-two-svc-remote   ClusterIP   10.104.47.11     <none>        8888/TCP                 27s
default       kubernetes               ClusterIP   10.96.0.1        <none>        443/TCP                  105m
```

Notice that the names of the mirrored services have the name of the remote
cluster as a suffix. This is to avoid name collisions. You can now access these
services from any injected pod. Lets give that a try!

First, install our test container (we will need it later as well):

```bash
linkerd --context=local inject https://run.linkerd.io/test-container.yml | kubectl --context=local apply -f -
```

If you ssh in your container and you run
`curl -s http://backend-two-svc-remote:8888 | json_pp`, you will be able
to see the response from the service that is living in the remote cluster.

## Traffic splitting across clusters

Now that we can access services that are outside of our cluster as if they
were local, nothing stops us from leveraging all the features that Linkerd
provides. Let's do some traffic splitting. To begin with, let's install a local
service:

```bash
linkerd --context=local inject https://run.linkerd.io/local-service.yml | kubectl --context=local apply -f -
```

In order to split traffic between the two services living on the remote cluster
and the one that lives on the local, we need to define a `TrafficSplit` resource:

```bash
cat <<EOF | kubectl --context=local apply -f -
apiVersion: split.smi-spec.io/v1alpha1
kind: TrafficSplit
metadata:
  name: cluster-split
  namespace: default
spec:
  service: backend-zero-svc
  backends:
  - service: backend-zero-svc
    weight: 500m
  - service: backend-one-svc-remote
    weight: 500m
  - service: backend-two-svc-remote
    weight: 500m
EOF
```

Now you can run in your test container:

```bash
for ((i=1;i<=100;i++)); do  curl -s http://backend-zero-svc:8888 | json_pp ; done
```

You will observe that some of the responses are coming from the local service,
while some are coming from one of the remote services. Linkerd is effectively
splitting the traffic between three services, located across two separate
clusters, while giving you end-to-end TLS!

```text
{
   "requestUID" : "in:http-sid:terminus-grpc:-1-h1:8888-521010098",
   "payload" : "hello-remote-2"
}
{
   "payload" : "hello-local-0",
   "requestUID" : "in:http-sid:terminus-grpc:-1-h1:8888-646858400"
}
{
   "payload" : "hello-remote-1",
   "requestUID" : "in:http-sid:terminus-grpc:-1-h1:8888-702914531"
}
{
   "requestUID" : "in:http-sid:terminus-grpc:-1-h1:8888-826137500",
   "payload" : "hello-local-0"
}
```

## Observing metrics

Since all of our services are injected with the Linkerd Proxy we can now use
metrics to analyze traffic across clusters. For example, you can take a look
at the traffic split stats by running `linkerd stat ts`:

```text
NAME            APEX               LEAF                     WEIGHT   SUCCESS      RPS   LATENCY_P50   LATENCY_P95   LATENCY_P99
cluster-split   backend-zero-svc   backend-one-svc-remote     500m   100.00%   2.6rps         150ms         195ms         199ms
cluster-split   backend-zero-svc   backend-two-svc-remote     500m   100.00%   3.3rps         150ms         195ms         199ms
cluster-split   backend-zero-svc   backend-zero-svc           500m   100.00%   3.0rps           2ms           3ms          17ms
```

It is interesting to observe that the latency of the `backend-one-svc-remote`
and `backend-two-svc-remote` leaf services is much higher, as they reside on
the remote cluster.

In addition to that, you can open up Grafana and take a look at the
`Linkerd Multicluster` dashboard. This dashboard gives you an overview of
the traffic that is flowing to each remote cluster, broken down by gateway
and service.

{{< fig src="/images/multicluster/grafana.png" title="Multicluster Dashboard" >}}

{{< note >}}
Multicluster support is experimental. Keep in mind that tooling can change.
{{< /note >}}
