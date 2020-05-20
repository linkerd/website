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

1. Install the service mirror on one cluster (`london` for the purpose of this
   guide).
1. Add the gateway and service account to another cluster (`paris`).
1. Import the service account's credentials to the first cluster (`london`).
1. Install the demo services to the "remote" cluster (`paris`).
1. Explicitly export the demo services, to control visibility.
1. Split traffic from pods on the first cluster (`london`) so that it appears to
   be local to the `london` cluster!
1. Look into metrics to get visibility into what traffic is travelling between
   clusters.

TODO: add links to sections

## Prerequisites

- Two clusters, we will refer to them as `paris` and `london` in this guide.
  Follow along with the
  [blog post](/2020/02/25/multicluster-kubernetes-with-service-mirroring/) as
  you walk through this guide! The easiest way to do this for development is
  running a [kind](https://kind.sigs.k8s.io/docs/user/quick-start/) or
  [k3d](https://github.com/rancher/k3d#usage) cluster locally on your laptop and
  one remotely on a cloud provider, such as
  [AKS](https://azure.microsoft.com/en-us/services/kubernetes-service/).
- Each of these clusters should be configured as `kubectl`
  [contexts](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/).
  We'd recommend you use the names `paris` and `london` so that you can follow
  along with this guide. It is easy to
  [rename contexts](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#-em-rename-context-em-)
  with `kubectl`, so don't feel like you need to keep it all named this way
  forever.
- Elevated privileges on both clusters. We'll be creating service accounts and
  granting extended privileges, so you'll need to be able to do that on your
  test clusters.
- Support for services of type `LoadBalancer` in the `paris` cluster. Check out
  the documentation for your cluster provider or take a look at
  [inlets](https://blog.alexellis.io/ingress-for-your-local-kubernetes-cluster/).
  This is what the `london` cluster will use to communicate with `paris` via the
  gateway.

## Install Linkerd

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
used to create new certificates. To generate the
[issuer credentials](/2/tasks/generate-certificates/#issuer-certificate-and-key)
using the trust anchor, run:

```bash
step certificate create identity.linkerd.cluster.local issuer.crt issuer.key \
  --profile intermediate-ca --not-after 8760h --no-password --insecure \
  --ca root.crt --ca-key root.key
```

An `identity` service in your cluster will use the certificate and key that you
generated here to generate and sign the certificates that each individual proxy
uses. While we will be using the same issuer credentials on each cluster for
this guide, it is a good idea to have separate ones for each cluster. Read
through the [certificate documentation](/2/tasks/generate-certificates/) for
more details.

With a valid trust anchor and issuer credentials, we can install Linkerd on your
`london` and `paris` clusters now.

```bash
linkerd install \
  --identity-trust-anchors-file root.crt \
  --identity-issuer-certificate-file issuer.crt \
  --identity-issuer-key-file issuer.key \
  | tee \
    >(kubectl --context=london apply -f -) \
    >(kubectl --context=paris apply -f -)
```

The output from `install` will get applied to each cluster and come up! You can
verify that everything has come up successfully with `check`.

```bash
linkerd --context=london check
linkerd --context=paris check
```

## Installing the service mirroring component

Linkerd contains a component which is responsible for continuously monitoring a
set of remote clusters and mirroring services from these clusters. In order to
install the mirror on a cluster, you can run the following command:

```bash
kubectl --context=london create ns linkerd-multicluster && \
  linkerd --context=london --namespace linkerd-multicluster \
    install-service-mirror | \
      kubectl --context=london apply -f -
```

The service mirror is a Kubernetes
[controller](https://kubernetes.io/docs/concepts/architecture/controller/). It
connects to a remote cluster (`paris` in this example), watches for updates to
services on that cluster and then creates resources locally to mirror those.

{{< fig
    alt="step-1"
    title="Copy Services"
    center="true"
    src="/images/multicluster/step-1.svg" >}}

At this point, you'll have the mirror installed on your `london` cluster. It
won't be able to do anything yet, we'll get to that in a minute. Make sure that
everything is up and running with:

```bash
linkerd --context=london check --multicluster
```

## Setting up the remote cluster

There are two things that need to be added to the `paris` cluster so that
`london` can mirror services and route traffic there. The first of these is a
gateway.

With a gateway started on the `paris` cluster, there is a way for pods running
in `london` to route traffic to `paris`. It will be exposed to the public
internet via. a `Service` of type `LoadBalancer`. Only requests verified through
Linkerd's mTLS (with a shared trust anchor) will be allowed through this gateway.

For `london` to mirror services from `paris`, the `london` cluster needs to have
credentials. These allow the service mirror component to watch services on
`paris` or the remote cluster and add/remove them from itself (`london`).

This configuration can be added in a single step by running:

```bash
linkerd --context=paris cluster setup-remote | \
  kubectl --context=paris apply -f -
```

We now have a way to mirror services in real time from `paris` to `london` and a
way to route requests from `london` to `paris` without any special networking
configuration.

{{< fig
    alt="step-3"
    title="Gateway"
    center="true"
    src="/images/multicluster/step-3.svg" >}}

To wait for the `linkerd-gateway` deployment to come up, run:

```bash
kubectl --context=paris -n linkerd-multicluster \
  rollout status deploy/linkerd-gateway
```

Take a peek at everything that's running in `paris` now with `kubectl`.

```bash
kubectl --context=paris -n linkerd-multicluster get all
```

## Enabling mirroring of services

With a running service mirror in `london` and an operational gateway in `paris`, it is time to start mirroring services from `paris` to `london`. To do this, we need to create credentials for the service mirror in `london` to use when watching services in `paris`. We've already created a service account to do this with, we just need to extract the credentials from `paris` and apply them to `london`.

```bash
linkerd --context=paris cluster get-credentials --cluster-name=paris \
  | kubectl --context=london -n linkerd-multicluster apply -f -
```

The service mirror, watches for secrets in the `linkerd-multicluster` namespace that contain kubeconfig credentials for remote clusters. Now that we have created the credentials service mirror needs, it will connect to `paris` and mirror any services that have been exported to `london`. We'll export some services in the next step.

Running `check` again will make sure that the service mirror has discovered this secret and can reach `paris`.

```bash
linkerd --context=london check --multicluster
```

{{< note >}}
`get-credentials` assumes that the two clusters will connect to each other with the same configuration as you're using locally. If this is not the case, you'll want to either create a kubeconfig yourself by hand or modify the connection string that is output from the command with something like `sed`.
{{< /note >}}

## Installing the test services

It is time to test this all out! The first step is to add some services that we can mirror. We have some extremely simple backends to add. Apply these to `paris`:

```bash
curl -sL https://run.linkerd.io/remote-services.yml \
  | linkerd --context=paris inject - \
  | kubectl --context=paris apply -f -
```

To wait for this to start up on your cluster, use `wait`.

```bash
kubectl --context=paris -n multicluster-test \
  wait --for=condition=available deploy --all
```

There will be two services, `backend-one-svc` and `backend-two-svc`. They are `ClusterIP` and will not be reachable by anything outside the `paris` cluster right now. To mirror these services to `london` and make it possible for pods in `london` to use them, we'll need to export the services.

## Exporting the services

TODO: need to finish this...

Now that you have all credentials setup you can use the Linkerd CLI to export
the services, making them available to the local cluster. Simply run:

```bash
kubectl --context=remote get svc -n multicluster-test -o yaml | linkerd cluster export-service - | kubectl --context=remote  apply -f -
```

At that point these services should be mirrored on your local cluster. To ensure
this is the case you can do:

```bash
kubectl --context=local get services -n multicluster-test
```

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

{{< note >}}
Multicluster support is experimental. Keep in mind that tooling can
change.
{{< /note >}}
