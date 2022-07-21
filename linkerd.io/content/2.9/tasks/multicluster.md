+++
title = "Multi-cluster communication"
description = "Allow Linkerd to manage cross-cluster communication."
+++

This guide will walk you through installing and configuring Linkerd so that two
clusters can talk to services hosted on both. There are a lot of moving parts
and concepts here, so it is valuable to read through our
[introduction](../../features/multicluster/) that explains how this works beneath
the hood. By the end of this guide, you will understand how to split traffic
between services that live on different clusters.

At a high level, you will:

1. [Install Linkerd](#install-linkerd) on two clusters with a shared trust
   anchor.
1. [Prepare](#preparing-your-cluster) the clusters.
1. [Link](#linking-the-clusters) the clusters.
1. [Install](#installing-the-test-services) the demo.
1. [Export](#exporting-the-services) the demo services, to control visibility.
1. [Verify](#security) the security of your clusters.
1. [Split traffic](#traffic-splitting) from pods on the source cluster (`west`)
   to the target cluster (`east`)

## Prerequisites

- Two clusters. We will refer to them as `east` and `west` in this guide. Follow
  along with the
  [blog post](/2020/02/25/multicluster-kubernetes-with-service-mirroring/) as
  you walk through this guide! The easiest way to do this for development is
  running a [kind](https://kind.sigs.k8s.io/docs/user/quick-start/) or
  [k3d](https://github.com/rancher/k3d#usage) cluster locally on your laptop and
  one remotely on a cloud provider, such as
  [AKS](https://azure.microsoft.com/en-us/services/kubernetes-service/).
- Each of these clusters should be configured as `kubectl`
  [contexts](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/).
  We'd recommend you use the names `east` and `west` so that you can follow
  along with this guide. It is easy to
  [rename contexts](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#-em-rename-context-em-)
  with `kubectl`, so don't feel like you need to keep it all named this way
  forever.
- Elevated privileges on both clusters. We'll be creating service accounts and
  granting extended privileges, so you'll need to be able to do that on your
  test clusters.
- Support for services of type `LoadBalancer` in the `east` cluster. Check out
  the documentation for your cluster provider or take a look at
  [inlets](https://blog.alexellis.io/ingress-for-your-local-kubernetes-cluster/).
  This is what the `west` cluster will use to communicate with `east` via the
  gateway.

## Install Linkerd

{{< fig
    alt="install"
    title="Two Clusters"
    center="true"
    src="/images/multicluster/install.svg" >}}

Linkerd requires a shared
[trust anchor](../generate-certificates/#trust-anchor-certificate)
to exist between the installations in all clusters that communicate with each
other. This is used to encrypt the traffic between clusters and authorize
requests that reach the gateway so that your cluster is not open to the public
internet. Instead of letting `linkerd` generate everything, we'll need to
generate the credentials and use them as configuration for the `install`
command.

We like to use the [step](https://smallstep.com/cli/) CLI to generate these
certificates. If you prefer `openssl` instead, feel free to use that! To
generate the trust anchor with step, you can run:

```bash
step certificate create root.linkerd.cluster.local root.crt root.key \
  --profile root-ca --no-password --insecure
```

This certificate will form the common base of trust between all your clusters.
Each proxy will get a copy of this certificate and use it to validate the
certificates that it receives from peers as part of the mTLS handshake. With a
common base of trust, we now need to generate a certificate that can be used in
each cluster to issue certificates to the proxies. If you'd like to get a deeper
picture into how this all works, check out the
[deep dive](../../features/automatic-mtls/#how-does-it-work).

The trust anchor that we've generated is a self-signed certificate which can be
used to create new certificates (a certificate authority). To generate the
[issuer credentials](../generate-certificates/#issuer-certificate-and-key)
using the trust anchor, run:

```bash
step certificate create identity.linkerd.cluster.local issuer.crt issuer.key \
  --profile intermediate-ca --not-after 8760h --no-password --insecure \
  --ca root.crt --ca-key root.key
```

An `identity` service in your cluster will use the certificate and key that you
generated here to generate the certificates that each individual proxy uses.
While we will be using the same issuer credentials on each cluster for this
guide, it is a good idea to have separate ones for each cluster. Read through
the [certificate documentation](../generate-certificates/) for more
details.

With a valid trust anchor and issuer credentials, we can install Linkerd on your
`west` and `east` clusters now.

```bash
linkerd install \
  --identity-trust-anchors-file root.crt \
  --identity-issuer-certificate-file issuer.crt \
  --identity-issuer-key-file issuer.key \
  | tee \
    >(kubectl --context=west apply -f -) \
    >(kubectl --context=east apply -f -)
```

The output from `install` will get applied to each cluster and come up! You can
verify that everything has come up successfully with `check`.

```bash
for ctx in west east; do
  echo "Checking cluster: ${ctx} .........\n"
  linkerd --context=${ctx} check || break
  echo "-------------\n"
done
```

## Preparing your cluster

{{< fig
    alt="preparation"
    title="Preparation"
    center="true"
    src="/images/multicluster/prep-overview.svg" >}}

In order to route traffic between clusters, Linkerd leverages Kubernetes
services so that your application code does not need to change and there is
nothing new to learn.  This requires a gateway component that routes incoming
requests to the correct internal service. The gateway will be exposed to the
public internet via a `Service` of type `LoadBalancer`. Only requests verified
through Linkerd's mTLS (with a shared trust anchor) will be allowed through this
gateway. If you're interested, we go into more detail as to why this is
important in [architecting for multicluster Kubernetes](/2020/02/17/architecting-for-multicluster-kubernetes/#requirement-i-support-hierarchical-networks).

To install the multicluster components on both `west` and `east`, you can run:

```bash
for ctx in west east; do
  echo "Installing on cluster: ${ctx} ........."
  linkerd --context=${ctx} multicluster install | \
    kubectl --context=${ctx} apply -f - || break
  echo "-------------\n"
done
```

{{< fig
    alt="install"
    title="Components"
    center="true"
    src="/images/multicluster/components.svg" >}}

Installed into the `linkerd-multicluster` namespace, the gateway is a simple
[pause container](https://github.com/linkerd/linkerd2/blob/main/multicluster/charts/linkerd-multicluster/templates/gateway.yaml#L3)
which has been injected with the Linkerd proxy. On the inbound side, Linkerd
takes care of validating that the connection uses a TLS certificate that is part
of the trust anchor, then handles the outbound connection. At this point, the
Linkerd proxy is operating like any other in the data plane and forwards the
requests to the correct service. Make sure the gateway comes up successfully by
running:

```bash
for ctx in west east; do
  echo "Checking gateway on cluster: ${ctx} ........."
  kubectl --context=${ctx} -n linkerd-multicluster \
    rollout status deploy/linkerd-gateway || break
  echo "-------------\n"
done
```

Double check that the load balancer was able to allocate a public IP address by
running:

```bash
for ctx in west east; do
  printf "Checking cluster: ${ctx} ........."
  while [ "$(kubectl --context=${ctx} -n linkerd-multicluster get service \
    -o 'custom-columns=:.status.loadBalancer.ingress[0].ip' \
    --no-headers)" = "<none>" ]; do
      printf '.'
      sleep 1
  done
  printf "\n"
done
```

Every cluster is now running the multicluster control plane and ready to start
mirroring services. We'll want to link the clusters together now!

## Linking the clusters

{{< fig
    alt="link-clusters"
    title="Link"
    center="true"
    src="/images/multicluster/link-flow.svg" >}}

For `west` to mirror services from `east`, the `west` cluster needs to have
credentials so that it can watch for services in `east` to be exported. You'd
not want anyone to be able to introspect what's running on your cluster after
all! The credentials consist of a service account to authenticate the service
mirror as well as a `ClusterRole` and `ClusterRoleBinding` to allow watching
services. In total, the service mirror component uses these credentials to watch
services on `east` or the target cluster and add/remove them from itself
(`west`). There is a default set added as part of
`linkerd multicluster install`, but if you would like to have separate
credentials for every cluster you can run `linkerd multicluster allow`.

The next step is to link `west` to `east`. This will create a credentials
secret, a Link resource, and a service-mirror controller. The credentials secret
contains a kubeconfig which can be used to access the target (`east`) cluster's
Kubernetes API. The Link resource is custom resource that configures service
mirroring and contains things such as the gateway address, gateway identity,
and the label selector to use when determining which services to mirror. The
service-mirror controller uses the Link and the secret to find services on
the target cluster that match the given label selector and copy them into
the source (local) cluster.

 To link the `west` cluster to the `east` one, run:

```bash
linkerd --context=east multicluster link --cluster-name east |
  kubectl --context=west apply -f -
```

Linkerd will look at your current `east` context, extract the `cluster`
configuration which contains the server location as well as the CA bundle. It
will then fetch the `ServiceAccount` token and merge these pieces of
configuration into a kubeconfig that is a secret.

Running `check` again will make sure that the service mirror has discovered this
secret and can reach `east`.

```bash
linkerd --context=west check --multicluster
```

Additionally, the `east` gateway should now show up in the list:

```bash
linkerd --context=west multicluster gateways
```

{{< note >}} `link` assumes that the two clusters will connect to each other
with the same configuration as you're using locally. If this is not the case,
you'll want to use the `--api-server-address` flag for `link`.{{< /note >}}

## Installing the test services

{{< fig
    alt="test-services"
    title="Topology"
    center="true"
    src="/images/multicluster/example-topology.svg" >}}

It is time to test this all out! The first step is to add some services that we
can mirror. To add these to both clusters, you can run:

```bash
for ctx in west east; do
  echo "Adding test services on cluster: ${ctx} ........."
  kubectl --context=${ctx} apply \
    -k "github.com/linkerd/website/multicluster/${ctx}/"
  kubectl --context=${ctx} -n test \
    rollout status deploy/podinfo || break
  echo "-------------\n"
done
```

You'll now have a `test` namespace running two deployments in each cluster -
frontend and podinfo. `podinfo` has been configured slightly differently in each
cluster with a different name and color so that we can tell where requests are
going.

To see what it looks like from the `west` cluster right now, you can run:

```bash
kubectl --context=west -n test port-forward svc/frontend 8080
```

{{< fig
    alt="west-podinfo"
    title="West Podinfo"
    center="true"
    src="/images/multicluster/west-podinfo.gif" >}}

With the podinfo landing page available at
[http://localhost:8080](http://localhost:8080), you can see how it looks in the
`west` cluster right now. Alternatively, running `curl http://localhost:8080`
will return a JSON response that looks something like:

```json
{
  "hostname": "podinfo-5c8cf55777-zbfls",
  "version": "4.0.2",
  "revision": "b4138fdb4dce7b34b6fc46069f70bb295aa8963c",
  "color": "#6c757d",
  "logo": "https://raw.githubusercontent.com/stefanprodan/podinfo/gh-pages/cuddle_clap.gif",
  "message": "greetings from west",
  "goos": "linux",
  "goarch": "amd64",
  "runtime": "go1.14.3",
  "num_goroutine": "8",
  "num_cpu": "4"
}
```

Notice that the `message` references the `west` cluster name.

## Exporting the services

To make sure sensitive services are not mirrored and cluster performance is
impacted by the creation or deletion of services, we require that services be
explicitly exported. For the purposes of this guide, we will be exporting the
`podinfo` service from the `east` cluster to the `west` cluster. To do this, we
must first export the `podinfo` service in the `east` cluster. You can do this
by adding the `mirror.linkerd.io/exported` label:

```bash
kubectl --context=east label svc -n test podinfo mirror.linkerd.io/exported=true
```

{{< note >}} You can configure a different label selector by using the
`--selector` flag on the `linkerd multicluster link` command or by editting
the Link resource created by the `linkerd multicluster link` command.
{{< /note >}}

Check out the service that was just created by the service mirror controller!

```bash
kubectl --context=west -n test get svc podinfo-east
```

From the
[architecture](https://linkerd.io/2020/02/25/multicluster-kubernetes-with-service-mirroring/#step-2-endpoint-juggling),
you'll remember that the service mirror component is doing more than just moving
services over. It is also managing the endpoints on the mirrored service. To
verify that is setup correctly, you can check the endpoints in `west` and verify
that they match the gateway's public IP address in `east`.

```bash
kubectl --context=west -n test get endpoints podinfo-east \
  -o 'custom-columns=ENDPOINT_IP:.subsets[*].addresses[*].ip'
kubectl --context=east -n linkerd-multicluster get svc linkerd-gateway \
  -o "custom-columns=GATEWAY_IP:.status.loadBalancer.ingress[*].ip"
```

At this point, we can hit the `podinfo` service in `east` from the `west`
cluster. This requires the client to be meshed, so let's run `curl` from within
the frontend pod:

```bash
kubectl --context=west -n test exec -c nginx -it \
  $(kubectl --context=west -n test get po -l app=frontend \
    --no-headers -o custom-columns=:.metadata.name) \
  -- /bin/sh -c "apk add curl && curl http://podinfo-east:9898"
```

You'll see the `greeting from east` message! Requests from the `frontend` pod
running in `west` are being transparently forwarded to `east`. Assuming that
you're still port forwarding from the previous step, you can also reach this
from your browser at [http://localhost:8080/east](http://localhost:8080/east).
Refresh a couple times and you'll be able to get metrics from `linkerd stat` as
well.

```bash
linkerd --context=west -n test stat --from deploy/frontend svc
```

We also provide a grafana dashboard to get a feel for what's going on here. You
can get to it by running `linkerd --context=west dashboard` and going to
[http://localhost:50750/grafana/](http://localhost:50750/grafana/d/linkerd-multicluster/linkerd-multicluster?orgId=1&refresh=1m)

{{< fig
    alt="grafana-dashboard"
    title="Grafana"
    center="true"
    src="/images/multicluster/grafana-dashboard.png" >}}

## Security

By default, requests will be going across the public internet. Linkerd extends
its [automatic mTLS](../../features/automatic-mtls/) across clusters to make sure
that the communication going across the public internet is encrypted. If you'd
like to have a deep dive on how to validate this, check out the
[docs](../securing-your-service/). To quickly check, however, you can run:

```bash
linkerd --context=west -n test tap deploy/frontend | \
  grep "$(kubectl --context=east -n linkerd-multicluster get svc linkerd-gateway \
    -o "custom-columns=GATEWAY_IP:.status.loadBalancer.ingress[*].ip")"
```

`tls=true` tells you that the requests are being encrypted!

{{< note >}} As `linkerd edges` works on concrete resources and cannot see two
clusters at once, it is not currently able to show the edges between pods in
`east` and `west`. This is the reason we're using `tap` to validate mTLS here.
{{< /note >}}

In addition to making sure all your requests are encrypted, it is important to
block arbitrary requests coming into your cluster. We do this by validating that
requests are coming from clients in the mesh. To do this validation, we rely on
a shared trust anchor between clusters. To see what happens when a client is
outside the mesh, you can run:

```bash
kubectl --context=west -n test run -it --rm --image=alpine:3 test -- \
  /bin/sh -c "apk add curl && curl -vv http://podinfo-east:9898"
```

## Traffic Splitting

{{< fig
    alt="with-split"
    title="Traffic Split"
    center="true"
    src="/images/multicluster/with-split.svg" >}}

It is pretty useful to have services automatically show up in clusters and be
able to explicitly address them, however that only covers one use case for
operating multiple clusters. Another scenario for multicluster is failover. In a
failover scenario, you don't have time to update the configuration. Instead, you
need to be able to leave the application alone and just change the routing. If
this sounds a lot like how we do [canary](../canary-release/) deployments,
you'd be correct!

`TrafficSplit` allows us to define weights between multiple services and split
traffic between them. In a failover scenario, you want to do this slowly as to
make sure you don't overload the other cluster or trip any SLOs because of the
added latency. To get this all working with our scenario, let's split between
the `podinfo` service in `west` and `east`. To configure this, you'll run:

```bash
cat <<EOF | kubectl --context=west apply -f -
apiVersion: split.smi-spec.io/v1alpha1
kind: TrafficSplit
metadata:
  name: podinfo
  namespace: test
spec:
  service: podinfo
  backends:
  - service: podinfo
    weight: 50
  - service: podinfo-east
    weight: 50
EOF
```

Any requests to `podinfo` will now be forwarded to the `podinfo-east` cluster
50% of the time and the local `podinfo` service the other 50%. Requests sent to
`podinfo-east` end up in the `east` cluster, so we've now effectively failed
over 50% of the traffic from `west` to `east`.

If you're still running `port-forward`, you can send your browser to
[http://localhost:8080](http://localhost:8080). Refreshing the page should show
both clusters.Alternatively, for the command line approach,
`curl localhost:8080` will give you a message that greets from `west` and
`east`.

{{< fig
    alt="podinfo-split"
    title="Cross Cluster Podinfo"
    center="true"
    src="/images/multicluster/split-podinfo.gif" >}}

You can also watch what's happening with metrics. To see the source side of
things (`west`), you can run:

```bash
linkerd --context=west -n test stat trafficsplit
```

It is also possible to watch this from the target (`east`) side by running:

```bash
linkerd --context=east -n test stat \
  --from deploy/linkerd-gateway \
  --from-namespace linkerd-multicluster \
  deploy/podinfo
```

There's even a dashboard! Run `linkerd dashboard` and send your browser to
[localhost:50750](http://localhost:50750/namespaces/test/trafficsplits/podinfo).

{{< fig
    alt="podinfo-split"
    title="Cross Cluster Podinfo"
    center="true"
    src="/images/multicluster/ts-dashboard.png" >}}

## Cleanup

To cleanup the multicluster control plane, you can run:

```bash
for ctx in west east; do
  linkerd --context=${ctx} multicluster uninstall | kubectl --context=${ctx} delete -f -
done
```

If you'd also like to remove your Linkerd installation, run:

```bash
for ctx in west east; do
  linkerd --context=${ctx} uninstall | kubectl --context=${ctx} delete -f -
done
```
