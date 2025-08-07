---
title: Progressive Delivery
description: Reduce deployment risk by automating canary releases based on service
  metrics.
---

Linkerd's [dynamic request routing](../features/request-routing/) allows you
to dynamically shift traffic between services. This can be used to implement
lower-risk  deployment strategies like blue-green deploys and canaries.

But simply shifting traffic from one version of a service to the next is just
the beginning. We can combine traffic splitting with [Linkerd's automatic
*golden metrics* telemetry](../features/telemetry/) and drive traffic
decisions based on the observed metrics. For example, we can gradually shift
traffic from an old deployment to a new one while continually monitoring its
success rate. If at any point the success rate drops, we can shift traffic back
to the original deployment and back out of the release. Ideally, our users
remain happy throughout, not noticing a thing!

In this tutorial, we'll show you how to use two different progressive delivery
tools: [Flagger](https://flagger.app/) and
[Argo Rollouts](https://argoproj.github.io/rollouts/) and how to tie Linkerd's
metrics and request routing together in a control loop, allowing for
fully-automated, metrics-aware canary deployments.

{{< docs/production-note >}}

## Prerequisites

To use this guide, you'll need a Kubernetes cluster running:

- Linkerd and Linkerd-Viz. If you haven't installed these yet, follow the
  [Installing Linkerd Guide](install/).

## Flagger

### Install Flagger

While Linkerd will be managing the actual traffic routing, Flagger automates
the process of creating new Kubernetes resources, watching metrics and
incrementally sending users over to the new version. To add Flagger to your
cluster and have it configured to work with Linkerd, run:

```bash
kubectl apply -k github.com/fluxcd/flagger/kustomize/linkerd
```

This command adds:

- The canary
  [CRD](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/)
  that enables configuring how a rollout should occur.
- RBAC which grants Flagger permissions to modify all the resources that it
  needs to, such as deployments and services.
- A Flagger controller configured to interact with the Linkerd control plane.

To watch until everything is up and running, you can use `kubectl`:

```bash
kubectl -n flagger-system rollout status deploy/flagger
```

### Set up the demo

This demo consists of three components: a load generator, a deployment and a
frontend. The deployment creates a pod that returns some information such as
name. You can use the responses to watch the incremental rollout as Flagger
orchestrates it. A load generator simply makes it easier to execute the rollout
as there needs to be some kind of active traffic to complete the operation.
Together, these components have a topology that looks like:

![Topology](/docs/images/canary/simple-topology.svg "Topology")
{.center}

To add these components to your cluster and include them in the Linkerd
[data plane](../reference/architecture/#data-plane), run:

```bash
kubectl create ns test && \
  kubectl apply -f https://run.linkerd.io/flagger.yml
```

Verify that everything has started up successfully by running:

```bash
kubectl -n test rollout status deploy podinfo
```

Check it out by forwarding the frontend service locally and opening
[http://localhost:8080](http://localhost:8080) locally by running:

```bash
kubectl -n test port-forward svc/frontend 8080
```

{{< note >}}
Request routing occurs on the *client* side of the connection and not the
server side. Any requests coming from outside the mesh will not be shifted and
will always be directed to the primary backend. A service of type `LoadBalancer`
will exhibit this behavior as the source is not part of the mesh. To shift
external traffic, add your ingress controller to the mesh.
{{< /note>}}

### Configure the release

Before changing anything, you need to configure how a release should be rolled
out on the cluster. The configuration is contained in a
[Canary](https://docs.flagger.app/tutorials/linkerd-progressive-delivery)
and MetricTemplate definition. To apply to your cluster, run:

```bash
kubectl apply -f - <<EOF
apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: podinfo
  namespace: test
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: podinfo
  service:
    # service port number
    port: 9898
    # container port number or name (optional)
    targetPort: 9898
    # Reference to the Service that the generated HTTPRoute would attach to.
    gatewayRefs:
      - name: podinfo
        namespace: test
        group: core
        kind: Service
        port: 9898
  analysis:
    interval: 10s
    threshold: 5
    stepWeight: 10
    maxWeight: 100
    metrics:
    - name: success-rate
      templateRef:
        name: success-rate
        namespace: test
      thresholdRange:
        min: 99
      interval: 1m
---
apiVersion: flagger.app/v1beta1
kind: MetricTemplate
metadata:
  name: success-rate
  namespace: test
spec:
  provider:
    type: prometheus
    address: http://prometheus.linkerd-viz:9090
  query: |
    sum(
      rate(
        response_total{
          namespace="{{ namespace }}",
          deployment=~"{{ target }}",
          classification!="failure",
          direction="inbound"
        }[{{ interval }}]
      )
    )
    /
    sum(
      rate(
        response_total{
          namespace="{{ namespace }}",
          deployment=~"{{ target }}",
          direction="inbound"
        }[{{ interval }}]
      )
    )
    * 100
EOF
```

The Flagger controller is watching these definitions and will create some new
resources on your cluster. To watch as this happens, run:

```bash
kubectl -n test get ev --watch
```

A new deployment named `podinfo-primary` will be created with the same number of
replicas that `podinfo` has. Once the new pods are ready, the original
deployment is scaled down to zero. This provides a deployment that is managed by
Flagger as an implementation detail and maintains your original configuration
files and workflows. Once you see the following line, everything is setup:

```bash
0s          Normal    Synced                   canary/podinfo                          Initialization done! podinfo.test
```

In addition to a managed deployment, there are also services created to
orchestrate routing traffic between the new and old versions of your
application. These can be viewed with `kubectl -n test get svc` and should look
like:

```bash
NAME                 TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)    AGE
frontend             ClusterIP   10.7.251.33   <none>        8080/TCP   96m
podinfo              ClusterIP   10.7.252.86   <none>        9898/TCP   96m
podinfo-canary       ClusterIP   10.7.245.17   <none>        9898/TCP   23m
podinfo-primary      ClusterIP   10.7.249.63   <none>        9898/TCP   23m
```

At this point, the topology looks a little like:

![Initialized](/docs/images/canary/initialized.svg "Initialized")
{.center}

{{< note >}}
This guide barely touches all the functionality provided by Flagger. Make sure
to read the [documentation](https://docs.flagger.app/) if you're interested in
combining canary releases with HPA, working off custom metrics or doing other
types of releases such as A/B testing.
{{< /note >}}

### Start the rollout

As a system, Kubernetes resources have two major sections: the spec and status.
When a controller sees a spec, it tries as hard as it can to make the status of
the current system match the spec. With a deployment, if any of the pod spec
configuration is  changed, a controller will kick off a rollout. By default, the
deployment controller will orchestrate a [rolling
update](https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/).

In this example, Flagger will notice that a deployment's spec changed and start
orchestrating the canary rollout. To kick this process off, you can update the
image to a new version by running:

```bash
kubectl -n test set image deployment/podinfo \
  podinfod=quay.io/stefanprodan/podinfo:1.7.1
```

Any kind of modification to the pod's spec such as updating an environment
variable or annotation would result in the same behavior as updating the image.

On update, the canary deployment (`podinfo`) will be scaled up. Once ready,
Flagger will begin to update the HTTPRoute incrementally. With a configured
stepWeight of 10, each increment will increase the weight of `podinfo` by 10.
For each period, the success rate will be observed and as long as it is over the
threshold of 99%, Flagger will continue the rollout. To watch this entire
process, run:

```bash
kubectl -n test get ev --watch
```

While an update is occurring, the resources and traffic will look like this at a
high level:

![Ongoing](/docs/images/canary/ongoing.svg "Ongoing")
{.center}

After the update is complete, this picture will go back to looking just like the
figure from the previous section.

{{< note >}}
You can toggle the image tag between `1.7.1` and `1.7.0` to start the rollout
again.
{{< /note >}}

### Resource

The canary resource updates with the current status and progress. You can watch
by running:

```bash
watch kubectl -n test get canary
```

Behind the scenes, Flagger is splitting traffic between the primary and canary
backends by updating the HTTPRoute resource. To watch how this configuration
changes over the rollout, run:

```bash
kubectl -n test get httproute.gateway.networking.k8s.io podinfo -o yaml
```

Each increment will increase the weight of `podinfo-canary` and decrease the
weight of `podinfo-primary`. Once the rollout is successful, the weight of
`podinfo-primary` will be set back to 100 and the underlying canary deployment
(`podinfo`) will be scaled down.

### Metrics

As traffic shifts from the primary deployment to the canary one, Linkerd
provides visibility into what is happening to the destination of requests. The
metrics show the backends receiving traffic in real time and measure the success
rate, latencies and throughput. From the CLI, you can watch this by running:

```bash
watch linkerd viz -n test stat deploy --from deploy/load
```

### Browser

Visit again [http://localhost:8080](http://localhost:8080). Refreshing the page
will show toggling between the new version and a different header color.
Alternatively, running `curl http://localhost:8080` will return a JSON response
that looks something like:

```bash
{
  "hostname": "podinfo-primary-74459c7db8-lbtxf",
  "version": "1.7.0",
  "revision": "4fc593f42c7cd2e7319c83f6bfd3743c05523883",
  "color": "blue",
  "message": "greetings from podinfo v1.7.0",
  "goos": "linux",
  "goarch": "amd64",
  "runtime": "go1.11.2",
  "num_goroutine": "6",
  "num_cpu": "8"
}
```

This response will slowly change as the rollout continues.

### Cleanup

To cleanup, remove the Flagger controller from your cluster and delete the
`test` namespace by running:

```bash
kubectl delete -k github.com/fluxcd/flagger/kustomize/linkerd && \
  kubectl delete ns test
```

## Argo Rollouts

[Argo Rollouts](https://argo-rollouts.readthedocs.io) is another tool which can
use Linkerd to perform incremental canary rollouts based on traffic metrics.

### Install Argo Rollouts

Similarly to Flagger, Argo Rollouts will automate the process of creating new
Kubernetes resources, watching metrics and will use Linkerd to incrementally
shift traffic to the new version. To install Argo Rollouts, run:

```bash
kubectl create namespace argo-rollouts && \
  kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
```

To use Argo Rollouts with Linkerd, you will also need to enable the GatewayAPI
routing plugin and grant it the necessary RBAC to ready and modify HTTPRoutes:

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: argo-rollouts-config # must be so name
  namespace: argo-rollouts # must be in this namespace
data:
  trafficRouterPlugins: |-
    - name: "argoproj-labs/gatewayAPI"
      location: "https://github.com/argoproj-labs/rollouts-plugin-trafficrouter-gatewayapi/releases/download/v0.0.0-rc1/gateway-api-plugin-linux-amd64"
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: argo-controller-role
  namespace: argo-rollouts
rules:
  - apiGroups:
      - gateway.networking.k8s.io
    resources:
      - httproutes
    verbs:
      - "*"
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: argo-controller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: argo-controller-role
subjects:
  - namespace: argo-rollouts
    kind: ServiceAccount
    name: argo-rollouts
EOF
```

Finally, we'll also need the Argo Rollouts plugin for Kubectl so that we can
control rollouts from the command line. Install it by following
[these instructions](https://argoproj.github.io/argo-rollouts/installation/#kubectl-plugin-installation).

### Set up the demo

We can use the same demo application that we used to demonstrate Flagger.
Deploy it by running:

```bash
kubectl create ns test && \
  kubectl apply -f https://run.linkerd.io/flagger.yml
```

### Configure the rollout

To set up rollouts for this application, we will create a few resources:
Services for the stable and canary versions, an HTTPRoute to control routing
between these two Services, and a Rollout resource to configure how rollouts
should be performed:

```bash
kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: argo-rollouts-http-route
  namespace: test
spec:
  parentRefs:
    - name: podinfo
      namespace: test
      kind: Service
      group: core
      port: 9898
  rules:
    - backendRefs:
        - name: podinfo-stable
          namespace: test
          port: 9898
        - name: podinfo-canary
          namespace: test
          port: 9898
---
apiVersion: v1
kind: Service
metadata:
  name: podinfo-canary
  namespace: test
spec:
  ports:
    - port: 8989
      targetPort: 8989
      protocol: TCP
      name: http
  selector:
    app: podinfo
---
apiVersion: v1
kind: Service
metadata:
  name: podinfo-stable
  namespace: test
spec:
  ports:
    - port: 8989
      targetPort: 8989
      protocol: TCP
      name: http
  selector:
    app: podinfo
---
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: rollouts-demo
  namespace: test
spec:
  replicas: 1
  strategy:
    canary:
      canaryService: podinfo-canary # our created canary service
      stableService: podinfo-stable # our created stable service
      trafficRouting:
        plugins:
          argoproj-labs/gatewayAPI:
            httpRoute: argo-rollouts-http-route # our created httproute
            namespace: test
      steps:
        - setWeight: 30
        - pause: {}
        - setWeight: 40
        - pause: { duration: 10 }
        - setWeight: 60
        - pause: { duration: 10 }
        - setWeight: 80
        - pause: { duration: 10 }
  revisionHistoryLimit: 2
  selector:
    matchLabels:
      app: podinfo
  template:
    metadata:
      labels:
        app: podinfo
    spec:
      containers:
        - name: podinfod
          image: quay.io/stefanprodan/podinfo:1.7.0
          ports:
            - containerPort: 9898
              protocol: TCP
EOF
```

### Start the rollout

We can trigger a rollout to a new version of podinfo by running:

```bash
kubectl argo rollouts -n test set image rollouts-demo \
  podinfod=quay.io/stefanprodan/podinfo:1.7.1
```

We can watch the rollout progress by running:

```bash
kubectl argo rollouts -n test get rollout rollouts-demo --watch
```

Behind the scenes, Argo Rollouts is splitting traffic between the stable and
canary backends by updating the HTTPRoute resource. To watch how this
configuration changes over the rollout, run:

```bash
kubectl -n test get httproute.gateway.networking.k8s.io podinfo -o yaml
```

We can also use the Linkerd CLI to observe which pods the traffic is being
routed to in real time:

```bash
watch linkerd viz -n test stat po --from deploy/load
```

### Cleanup

To cleanup, remove the Argo Rollouts controller from your cluster and delete the
`test` namespace by running:

```bash
kubectl delete ns argo-rollouts && \
  kubectl delete ns test
```
