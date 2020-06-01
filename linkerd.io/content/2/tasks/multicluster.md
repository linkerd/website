+++
title = "Getting started with Multicluster"
description = "Get started with Linkerd managing traffic between multiple Kubernetes clusters"
+++

This guide will walk you through installing and configuring Linkerd so that two
clusters can talk to services hosted on both. There are a lot of moving parts
and concepts here, so it is valuable to read through our
[introduction](/2/features/multicluster_support/) that explains how this works
beneath the hood. By the end of this guide, you will understand how to split
traffic between services that live on different clusters.

At a high level, you will:

1. Install Linkerd on two clusters with a shared trust anchor.
1. Prepare the clusters.
1. Link the clusters.
1. Install the demo services to the "target" cluster (`east`).
1. Explicitly export the demo services, to control visibility.
1. Split traffic from pods on the source cluster (`west`) so that it appears to
   be local to the `west` cluster!
1. Look into metrics to get visibility into what traffic is travelling between
   clusters.

TODO: add links to sections

## Prerequisites

- Two clusters, we will refer to them as `east` and `west` in this guide. Follow
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
[trust anchor](https://linkerd.io/2/tasks/generate-certificates/#trust-anchor-certificate)
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
step certificate create identity.linkerd.cluster.local root.crt root.key \
  --profile root-ca --no-password --insecure
```

This certificate will form the common base of trust between all your clusters.
Each proxy will get a copy of this certificate and use it to validate the
certificates that it receives from peers as part of the mTLS handshake. With a
common base of trust, we now need to generate a certificate that can be used in
each cluster to issue certificates to the proxies. If you'd like to get a deeper
picture into how this all works, check out the
[deep dive](/2/features/automatic-mtls/#how-does-it-work).

The trust anchor that we've generated is a self-signed certificate which can be
used to create new certificates (a certificate authority). To generate the
[issuer credentials](/2/tasks/generate-certificates/#issuer-certificate-and-key)
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
the [certificate documentation](/2/tasks/generate-certificates/) for more
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

There are two components required to discover services and route traffic between
clusters. The service mirror is responsible for continuously monitoring services
on a set of target clusters and copying these services from the target cluster
to the local one running the service mirror. Instead of creating a new, special
way to address and interact with services, Linkerd leverages Kubernetes services
so that your application code does not need to change and there is nothing new
to learn.

In addition, there needs to be a component that can be reached external to the
cluster. Requests on one cluster can be routed through the gateway component to
any service inside another cluster. This gateway will be exposed to the public
internet via. a `Service` of type `LoadBalancer`. Only requests verified through
Linkerd's mTLS (with a shared trust anchor) will be allowed through this
gateway. If you're interested, we go into more detail as to why this is
important in
[architecting for multicluster Kubernetes](/2020/02/17/architecting-for-multicluster-kubernetes/#requirement-i-support-hierarchical-networks).

To install these components on both `west` and `east`, you can run:

```bash
for ctx in west east; do
  echo "Installing on cluster: ${ctx} ........."
  linkerd --context=${ctx} multicluster install | \
    kubectl --context=${ctx} apply -f - || exit 1
  echo "-------------\n"
done
```

{{< fig
    alt="install"
    title="Components"
    center="true"
    src="/images/multicluster/components.svg" >}}

Installed into the `linkerd-multicluster` namespace, the gateway is a simple
[NGINX proxy](https://github.com/linkerd/linkerd2/blob/master/charts/linkerd2-multicluster-remote-setup/templates/gateway.yaml#L10)
which has been injected with the Linkerd proxy. On the inbound side, Linkerd
takes care of validating that the connection uses a TLS certificate that is part
of the trust anchor. NGINX takes the request and forwards it to the Linkerd
proxy's outbound side. At this point, the Linkerd proxy is operating like any
other in the data plane and forwards the requests to the correct service. Make
sure the gateway comes up successfully by running:

TODO: not sure this will work in the laptop -> cloud case. TODO: should this all
just be folded into a single command?

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

{{< fig
    alt="service-mirror"
    title="Service Mirror"
    center="true"
    src="/images/multicluster/service-mirror.svg" >}}

The service mirror is a Kubernetes
[controller](https://kubernetes.io/docs/concepts/architecture/controller/) that
connects to a target cluster (`east` in this example). One of its jobs is to
watch the services running on the target cluster and locally mirror any service
that has been exported. In addition, the mirror watches the gateway's service on
the target cluster and adds the public IP address to each mirrored service's
endpoints. It should be up and running by now, but you can verify by running:

```bash
for ctx in west east; do
  echo "Checking cluster: ${ctx} ........."
  kubectl --context=${ctx} -n linkerd-multicluster \
    rollout status deploy/linkerd-service-mirror || break
done
```

Finally, let's do a pass with `check` and make sure all the components are
healthy and ready to go.

```bash
for ctx in west east; do
  echo "Checking cluster: ${ctx} ........."
  linkerd --context=${ctx} check --multicluster || break
  echo "-------------\n"
done
```

If you're interested, you can take a peek at everything that's now running in
both clusters with `kubectl`.

```bash
kubectl --context=west -n linkerd-multicluster get all
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

The next step is to link `west` to `east`. This will create a kubeconfig which
contains the target (`east`) cluster's service account token and connection
details. The kubeconfig will be applied to the source (`west`) cluster as a
secret that can be read by the service mirror in `west`. To do this, you'll want
to run `link` against the `east` context as you're fetching the details required
to connect to that cluster. When applying it, you'll want to use the `west`
context as that is what needs the details. To link the `west` cluster to the
`east` one, run:

```bash
linkerd --context=east multicluster link --cluster-name east |
  kubectl --context=west apply -f -
```

Linkerd will look at your current `east` context, extract the `cluster`
configuration which contains the server location as well as the CA bundle. It
will then fetch the `ServiceAccount` token and merge these pieces of
configuration into a kubeconfig that is a secret.

The service mirror, watches for secrets in the `linkerd-multicluster` namespace
that contain a kubeconfig for remote clusters. Now that we have created the
credentials service mirror needs, it will connect to `east` and mirror any
services that have been exported to `west`. We've not explicitly exported any
services yet, that'll happen in the next step.

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
    -k "github.com/linkerd/website/multicluster/${ctx}/?ref=grampelberg/multi-split"
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
explicitly exported. For the purposes of this guide, we will be mirroring the
`podinfo` service from the `east` cluster to the `west` cluster. To do this, we
must first export the `podinfo` service in the `east` cluster. You can do this
by running:

```bash
kubectl --context=east get svc -n test podinfo -o yaml | \
  linkerd multicluster export-service - | \
  kubectl --context=east apply -f -
```

The `linkerd multicluster export-service` command simply adds a couple
annotations to the service. There's no reason you have to use the command, feel
free to add them yourself! The added annotations are:

```yaml
mirror.linkerd.io/gateway-name: linkerd-gateway
mirror.linkerd.io/gateway-ns: linkerd-multicluster
```

Make sure to configure the values based on how you have configured the
installation. The gateway's service name and namespace are required.

These annotations are picked up by the service mirror component in the `west`
cluster. A `podinfo-east` service is then created in the `test` namespace. Check
it out!

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

The `linkerd cluster` command is simply adding two annotations to the services.
You could do this by hand if you wanted! These configure the gateway that will
be used to send traffic to the annotated service. You can imagine having
multiple gateways in a single cluster that manage traffic differently. This
could either be for security or to separate load requirements. The two
annotations are:

```yaml
mirror.linkerd.io/gateway-name: linkerd-gateway
mirror.linkerd.io/gateway-ns: linkerd-gateway
```

After annotating these services in `east`, the service mirror in `west` will:

1. Create a `multicluster-text` namespace.
1. Create a `backend-one-svc` and `backend-two-svc`.
1. Create endpoints for both services that contain the IP address of the gateway
   in `east`.

To validate that everything is working, check out the services running now in
`west`.

```bash
kubectl --context=west get services -n multicluster-test
```

Take a peek at the endpoints for these services to see where traffic addressed
to them will go!

You should see something similar to:

```text
NAME                     TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
backend-one-svc-remote   ClusterIP   10.97.8.6        <none>        8888/TCP   38s
backend-two-svc-remote   ClusterIP   10.102.239.149   <none>        8888/TCP   29s
```

Notice that the names of the mirrored services have the name of the remote
cluster as a suffix. This is to avoid name collisions. You can now access these
services from any injected pod. Lets give that a try!

First, install our test container (we will need it later as well):

```bash
linkerd --context=local inject https://run.linkerd.io/test-container.yml | kubectl --context=local apply -f -
```

If you ssh in your container and you run
`curl -s http://backend-two-svc-remote:8888 | json_pp`, you will be able to see
the response from the service that is living in the remote cluster.

## Traffic splitting across clusters

Now that we can access services that are outside of our cluster as if they were
local, nothing stops us from leveraging all the features that Linkerd provides.
Let's do some traffic splitting. To begin with, let's install a local service:

```bash
linkerd --context=local inject https://run.linkerd.io/local-service.yml | kubectl --context=local apply -f -
```

In order to split traffic between the two services living on the remote cluster
and the one that lives on the local, we need to define a `TrafficSplit`
resource:

```bash
cat <<EOF | kubectl --context=local apply -f -
apiVersion: split.smi-spec.io/v1alpha1
kind: TrafficSplit
metadata:
  name: cluster-split
  namespace: multicluster-test
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
metrics to analyze traffic across clusters. For example, you can take a look at
the traffic split stats by running
`linkerd --context=local stat ts -n multicluster-test`:

```text
NAME            APEX               LEAF                     WEIGHT   SUCCESS      RPS   LATENCY_P50   LATENCY_P95   LATENCY_P99
cluster-split   backend-zero-svc   backend-one-svc-remote     500m   100.00%   2.6rps         150ms         195ms         199ms
cluster-split   backend-zero-svc   backend-two-svc-remote     500m   100.00%   3.3rps         150ms         195ms         199ms
cluster-split   backend-zero-svc   backend-zero-svc           500m   100.00%   3.0rps           2ms           3ms          17ms
```

It is interesting to observe that the latency of the `backend-one-svc-remote`
and `backend-two-svc-remote` leaf services is much higher, as they reside on the
remote cluster.

Additionally the CLI provides a command to observe the health of all remote
gateways as well as traffic stats relating to them. You can execute
`linkerd --context=local cluster gateways` and get some information regarding
the one remote gateway that is currently being used:

```text
CLUSTER  NAMESPACE        NAME             ALIVE    NUM_SVC  LATENCY_P50  LATENCY_P95  LATENCY_P99
remote   linkerd-gateway  linkerd-gateway  True           2        150ms        195ms        199ms
```

-->

{{< note >}} Multicluster support is experimental. Keep in mind that tooling can
change. {{< /note >}}
