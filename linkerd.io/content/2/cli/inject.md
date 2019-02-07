+++
date = "2018-08-28T08:00:00-07:00"
title = "Inject"
description = "The inject command makes it easy to add Linkerd to your service. It consumes Kubernetes resources in YAML format and adds the proxy sidecar. The output is in a format that can be immediately applied to the cluster via kubectl."
weight = 2
aliases = [
  "/2/inject-reference/"
]
[menu.l5d2docs]
  name = "inject"
  parent = "cli"
+++

The `linkerd inject` command allows for a quick and reliable setup of the
Linkerd Proxy in a Kubernetes Deployment. This page is useful as a reference to
help you understand what `linkerd inject` is doing under the hood, as well as
provide a reference for the flags that can be passed at the command line.

If you run the command `linkerd inject -h` it will provide you with the same
information as the table below:

{{< flags "inject" >}}

## What `linkerd inject` Is Doing

`linkerd inject` is modifying the Kubernetes Deployment manifest that is being passed to it
either as a file or as a stream to its stdin. It is adding two things:

1. An Init Container (supported as of Kubernetes version 1.6 or greater)

1. A Linkerd Proxy sidecar container into each Pod belonging to your Deployment

The Init Container is responsible for pulling configuration (such as
certificates) from the Kubernetes API/Linkerd Controller, as well as providing
configuration to the Linkerd Proxy container for its runtime.

## Example Deployment

Let's say for example you have the following deployment saved as `deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: example-deployment
  namespace: default
spec:
  replicas: 3
  selector:
    matchLabels:
      app: example-deployment
      env: default
  template:
    metadata:
      labels:
        app: example-deployment
        env: default
    spec:
      containers:
      - name: app
        image: quay.io/ygrene/hello-docker
        ports:
        - containerPort: 3000
```

Now, we can run the `linkerd inject` command as follows:

```bash
linkerd inject \
  --proxy-log-level="debug" \
  --skip-outbound-ports=3306 \
  deployment.yaml > deployment_with_linkerd.yaml
```

The output of that file should look like the following:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  name: example-deployment
  namespace: default
spec:
  replicas: 3
  selector:
    matchLabels:
      app: example-deployment
      env: default
  strategy: {}
  template:
    metadata:
      annotations:
        linkerd.io/created-by: linkerd/cli v18.8.2
        linkerd.io/proxy-version: v18.8.2
      creationTimestamp: null
      labels:
        app: example-deployment
        env: default
        linkerd.io/control-plane-ns: linkerd
        linkerd.io/proxy-deployment: example-deployment
    spec:
      containers:
      - image: quay.io/ygrene/hello-docker
        name: app
        ports:
        - containerPort: 3000
        resources: {}
      - env:
        - name: LINKERD2_PROXY_LOG
          value: debug
        - name: LINKERD2_PROXY_BIND_TIMEOUT
          value: 10s
        - name: LINKERD2_PROXY_CONTROL_URL
          value: tcp://proxy-api.linkerd.svc.cluster.local:8086
        - name: LINKERD2_PROXY_CONTROL_LISTENER
          value: tcp://0.0.0.0:4190
        - name: LINKERD2_PROXY_METRICS_LISTENER
          value: tcp://0.0.0.0:4191
        - name: LINKERD2_PROXY_PRIVATE_LISTENER
          value: tcp://127.0.0.1:4140
        - name: LINKERD2_PROXY_PUBLIC_LISTENER
          value: tcp://0.0.0.0:4143
        - name: LINKERD2_PROXY_POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        image: gcr.io/linkerd-io/proxy:v18.8.2
        imagePullPolicy: IfNotPresent
        name: linkerd-proxy
        ports:
        - containerPort: 4143
          name: linkerd-proxy
        - containerPort: 4191
          name: linkerd-metrics
        resources: {}
        securityContext:
          runAsUser: 2102
        terminationMessagePolicy: FallbackToLogsOnError
      initContainers:
      - args:
        - --incoming-proxy-port
        - "4143"
        - --outgoing-proxy-port
        - "4140"
        - --proxy-uid
        - "2102"
        - --inbound-ports-to-ignore
        - 4190,4191
        - --outbound-ports-to-ignore
        - "3306"
        image: gcr.io/linkerd-io/proxy-init:v18.8.2
        imagePullPolicy: IfNotPresent
        name: linkerd-init
        resources: {}
        securityContext:
          capabilities:
            add:
            - NET_ADMIN
          privileged: false
        terminationMessagePolicy: FallbackToLogsOnError
status: {}
---
```

Note here how the `initContainer` and `linkerd-proxy` sidecar are added to the
manifest with configuration we passed as command line flags.
