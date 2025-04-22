---
title: Multi-cluster Federated Services
description: Using multi-cluster federated services
---

Linkerd's [multicluster extension](../multicluster/) can create federated
services which act as a union of multiple services in different clusters with
the same name and namespace. By sending traffic to the federated service, that
traffic will be load balanced among all endpoints of that service in all linked
clusters. This allows the client to be cluster agnostic, balance traffic across
multiple clusters, and be resiliant to the failure of any individual cluster.

Federated services send traffic directly to the pods of the member services
rather than through a gateway. Therefore, federated services have the same
requirements as *pod-to-pod* multicluster services:

* The clusters must be on a *flat network*. In other words, pods from one
  cluster must be able to address and connect to pods in the other cluster.
* The clusters must have the same trust root.
* Any clients connecting to the federated service must be meshed.

This guide will walk you through creating a federated service to load balance
traffic to a service which exists in multiple clusters. A federated service can
include services from any number of clusters, but in this guide we'll create
a federated service for a service that spans 3 clusters.

## Prerequisites

* Three clusters. We will refer to them as `west`, `east`, and `north` in this
  guide.
* The clusters must be on a *flat network*. In other words, pods from one
  cluster must be able to address and connect to pods in the other cluster.
* Each of these clusters should be configured as `kubectl`
  [contexts](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/).
  We'd recommend you use the names `west`, `east`, and `north` so that you can
  follow along with this guide. It is easy to
  [rename contexts](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#-em-rename-context-em-)
  with `kubectl`, so don't feel like you need to keep them all named this way
  forever.

## Step 1: Installing Linkerd and Linkerd-Viz

First, install Linkerd and Linkerd-Viz into all three clusters, as described in
the [multicluster guide](../multicluster/#install-linkerd-and-linkerd-viz).
Make sure to take care that all clusters share a common trust anchor.

## Step 2: Installing Linkerd-Multicluster

We will install the multicluster extension into all three clusters. We can
install without the gateway because federated services use direct pod-to-pod
communication. Since the services will get mirrored in the `west` cluster, we
create the controllers there:

```console
> linkerd --context west multicluster install --gateway=false \
>   --set controllers[0].link.ref.name=east --set controllers[1].link.ref.name=north |
>   kubectl --context west apply -f -
> linkerd --context west check

> linkerd --context east multicluster install --gateway=false | kubectl --context east apply -f -
> linkerd --context east check

> linkerd --context north multicluster install --gateway=false | kubectl --context north apply -f -
> linkerd --context north check
```

## Step 3: Linking the Clusters

We use the `linkerd multicluster link-gen` command to link the `east` and
`north` cluster to the `west` cluster. This is exactly the same as in the
regular [Multicluster guide](../multicluster/#linking-the-clusters) except that
we pass the `--gateway=false` flag to create a Link which doesn't require a
gateway.

```console
> linkerd --context east multicluster link-gen --cluster-name=east --gateway=false | kubectl --context west apply -f -
> linkerd --context north multicluster link-gen --cluster-name=north --gateway=false | kubectl --context west apply -f -
> linkerd --context west check
```

## Step 4: Deploy a Service

For our guide, we'll deploy the [bb](https://github.com/BuoyantIO/bb) service,
which is a simple server that just returns a static response. We deploy it
into all three clusters but configure each one with a different response string
so that we can tell the responses apart:

```bash
> cat <<EOF | linkerd --context east inject - | kubectl --context east apply -f -
---
apiVersion: v1
kind: Namespace
metadata:
  name: mc-demo
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bb
  namespace: mc-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: bb
  template:
    metadata:
      labels:
        app: bb
    spec:
      containers:
      - name: terminus
        image: buoyantio/bb:v0.0.6
        args:
        - terminus
        - "--h1-server-port=8080"
        - "--response-text=hello from east\n"
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: bb
  namespace: mc-demo
spec:
  ports:
  - name: http
    port: 8080
    targetPort: 8080
  selector:
    app: bb
EOF

> cat <<EOF | linkerd --context north inject - | kubectl --context north apply -f -
---
apiVersion: v1
kind: Namespace
metadata:
  name: mc-demo
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bb
  namespace: mc-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: bb
  template:
    metadata:
      labels:
        app: bb
    spec:
      containers:
      - name: terminus
        image: buoyantio/bb:v0.0.6
        args:
        - terminus
        - "--h1-server-port=8080"
        - "--response-text=hello from north\n"
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: bb
  namespace: mc-demo
spec:
  ports:
  - name: http
    port: 8080
    targetPort: 8080
  selector:
    app: bb
EOF

> cat <<EOF | linkerd --context west inject - | kubectl --context west apply -f -
---
apiVersion: v1
kind: Namespace
metadata:
  name: mc-demo
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bb
  namespace: mc-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: bb
  template:
    metadata:
      labels:
        app: bb
    spec:
      containers:
      - name: terminus
        image: buoyantio/bb:v0.0.6
        args:
        - terminus
        - "--h1-server-port=8080"
        - "--response-text=hello from west\n"
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: bb
  namespace: mc-demo
spec:
  ports:
  - name: http
    port: 8080
    targetPort: 8080
  selector:
    app: bb
EOF
```

## Step 5: Label the services

We now set a label on the services to indicate that they should join a federated
service.

```console
> kubectl --context east -n mc-demo label svc/bb mirror.linkerd.io/federated=member
> kubectl --context north -n mc-demo label svc/bb mirror.linkerd.io/federated=member
> kubectl --context west -n mc-demo label svc/bb mirror.linkerd.io/federated=member
```

You should immediately see a federated service created in the `west` cluster:

```console
> kubectl --context west -n mc-demo get svc
NAME           TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
bb-federated   ClusterIP   10.43.56.245   <none>        8080/TCP   114s
```

We can also check the `status` subresource of each of the Link resources to see
which services have joined federated services or if there are any errors.

```console
> kubectl --context west -n linkerd-multicluster get link/east -ojsonpath='{.status.federatedServices}' | jq .
[
  {
    "conditions": [
      {
        "lastTransitionTime": "2024-11-07T19:53:01Z",
        "localRef": {
          "group": "",
          "kind": "Service",
          "name": "bb-federated",
          "namespace": "mc-demo"
        },
        "message": "",
        "reason": "Mirrored",
        "status": "True",
        "type": "Mirrored"
      }
    ],
    "controllerName": "linkerd.io/service-mirror",
    "remoteRef": {
      "group": "",
      "kind": "Service",
      "name": "bb",
      "namespace": "mc-demo"
    }
  }
]
> kubectl --context west -n linkerd-multicluster get link/north -ojsonpath='{.status.federatedService
s}' | jq .
[
  {
    "conditions": [
      {
        "lastTransitionTime": "2024-11-07T19:53:06Z",
        "localRef": {
          "group": "",
          "kind": "Service",
          "name": "bb-federated",
          "namespace": "mc-demo"
        },
        "message": "",
        "reason": "Mirrored",
        "status": "True",
        "type": "Mirrored"
      }
    ],
    "controllerName": "linkerd.io/service-mirror",
    "remoteRef": {
      "group": "",
      "kind": "Service",
      "name": "bb",
      "namespace": "mc-demo"
    }
  }
]
```

## Step 6: Send some traffic!

We'll create a deployment that uses `curl` to generate traffic to the
`bb-federated` service.

```bash
> cat <<EOF | linkerd --context west inject - | kubectl --context west apply -f -
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: traffic
  namespace: mc-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: traffic
  template:
    metadata:
      labels:
        app: traffic
    spec:
      containers:
      - args:
        - -c
        - |
          while true
          do curl -s http://bb-federated:8080
          echo
          sleep 1
          done
        command:
        - /bin/sh
        image: curlimages/curl
        name: traffic
EOF
```

Looking at the logs from this deployment, we can see that the federated service
is distributing requests across all three clusters:

```bash
> kubectl --context west -n mc-demo logs deploy/traffic -c traffic
{"requestUID":"in:http-sid:terminus-grpc:-1-h1:8080-407945949","payload":"hello from east\n"}
{"requestUID":"in:http-sid:terminus-grpc:-1-h1:8080-420928530","payload":"hello from west\n"}
{"requestUID":"in:http-sid:terminus-grpc:-1-h1:8080-433442439","payload":"hello from north\n"}
{"requestUID":"in:http-sid:terminus-grpc:-1-h1:8080-445418175","payload":"hello from west\n"}
{"requestUID":"in:http-sid:terminus-grpc:-1-h1:8080-457469540","payload":"hello from west\n"}
{"requestUID":"in:http-sid:terminus-grpc:-1-h1:8080-469729132","payload":"hello from west\n"}
{"requestUID":"in:http-sid:terminus-grpc:-1-h1:8080-481971153","payload":"hello from west\n"}
{"requestUID":"in:http-sid:terminus-grpc:-1-h1:8080-496032705","payload":"hello from east\n"}
...
```

## Next Steps

We now have a federated service that balances traffic accross services in three
clusters. Additional clusters can be added simply by:

* Updating the linkerd-multicluster config in `west` to add the required
  controllers.
* Applying the Link CRs and credentials secrets
* Adding the `mirror.linkerd.io/federated=member` label to the services that
you wish to add to the federated service.

Similarly, services can be removed from the federated service at any time by
removing the label.

You may notice that the `bb-federated` federated service exists only in the
`west` cluster and not in the `east` or `north` clusters. This is because Links
are directional and to keep this guide simple, we only linked north and east to
west, and not the other way around. If we were to create links in both
directions between all three clusters, we would get a `bb-federated` service in
all three clusters.

## Troubleshooting

* The first step of troubleshooting should be to run the `linkerd check` command
  in each of the clusters. In particular, look for the `linkerd-multicluster`
  checks and ensure that all linked clusters are listed:

```console
linkerd-multicluster
--------------------
√ Link CRD exists
√ Link resources are valid
        * east
        * north
√ remote cluster access credentials are valid
        * east
        * north
√ clusters share trust anchors
        * east
        * north
√ service mirror controller has required permissions
        * east
        * north
√ service mirror controllers are running
        * east
        * north
√ extension is managing controllers
        * east
        * north
```

* Check the `status` subresource of the Link resource. If any services failed to
  join the federated service, they will appear as an error here.
* If a service that should join a federated service is not present in the Link
  `status`, ensure that the service matches the federated service label selector
  (`mirror.linkerd.io/federated=memeber` by default).
* Use the `linkerd diagnostics endpoints` command to see all of the endpoints
  in a federated service:

```console
> linkerd --context west diagnostics endpoints bb-federated.mc-demo.svc.cluster.local:8080
NAMESPACE   IP            PORT   POD                   SERVICE
mc-demo     10.42.0.108   8080   bb-85f9bbc898-j7fbq   bb.mc-demo
mc-demo     10.23.1.43    8080   bb-7d9f44c6fd-9s848   bb.mc-demo
mc-demo     10.23.0.42    8080   bb-74c6c64948-j5drn   bb.mc-demo
```
