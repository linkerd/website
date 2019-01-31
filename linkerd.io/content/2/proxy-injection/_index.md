+++
date = "2018-09-10T12:00:00-07:00"
title = "Experimental: Automatic Proxy Injection"
[menu.l5d2docs]
  name = "Experimental: Automatic Proxy Injection"
  weight = 13
+++

Linkerd can be configured to automatically inject the data plane proxy into your
service. This is an alternative to needing to run the
[`linkerd inject`](../cli/inject/) command.

This feature is **experimental**, since it only supports Deployment-type
workloads. It will be removed from experimental once all workloads are supported
([tracked here](https://github.com/linkerd/linkerd2/issues/1751)).

## Installation

Automatic proxy injection is implemented with an
[admission webhook](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/#admission-webhooks),
which requires your cluster to have the `admissionregistration.k8s.io/v1beta1`
API enabled. To verify, run:

```bash
$ kubectl api-versions | grep admissionregistration
admissionregistration.k8s.io/v1beta1
```

Automatic proxy injection is disabled by default when installing the Linkerd
control plane. To enable it, set the `--proxy-auto-inject` flag, as follows:

```bash
$ linkerd install --proxy-auto-inject | kubectl apply -f -
```

This will add a new `linkerd-proxy-injector` service and deployment to the
control plane, to serve the admission webhook.

```bash
$ kubectl -n linkerd get deploy/linkerd-proxy-injector svc/linkerd-proxy-injector
NAME                                           DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deployment.extensions/linkerd-proxy-injector   1         1         1            1           3m

NAME                             TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
service/linkerd-proxy-injector   ClusterIP   10.100.40.55   <none>        443/TCP   3m
```

## Configuration

Automatic proxy injection  will only be performed on pods with the
`linkerd.io/inject: enabled` annotation, or on pods in namespaces with the
`linkerd.io/inject: enabled` annotation. If a namespace has been configured to
use auto-injection, it's also possible to disabled injection for a given pod in
that namespace using the `linkerd.io/inject: disabled` annotation.

For example, to add automatic proxy injection for all all pods in the
`sample-inject-enabled-ns` namespace, setup the namespace to include the
`linkerd.io/inject: enabled` annotation, as follows:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: sample-inject-enabled-ns
  annotations:
    linkerd.io/inject: enabled
```

After applying that namespace configuration to your cluster, you can test automatic
proxy injection by creating a new deployment in that namespace, by running:

```bash
$ kubectl -n sample-inject-enabled-ns run helloworld --image=buoyantio/helloworld
deployment.apps "helloworld" created
```

Verify that the deployment's pod includes a `linkerd-proxy` container:

```bash
$ kubectl -n sample-inject-enabled-ns get po -l run=helloworld \
  -o jsonpath='{.items[0].spec.containers[*].name}'
helloworld linkerd-proxy
```

It's also possible to explicitly configure auto-injection for all pods in a
deployment, even if that deployment is running in a namespace that has not been
configured for auto-inject. To do this, add the `linkerd.io/inject: enabled`
annotation to the deployment's pod spec. For example, create a new deployment in
the `default` namespace, as follows:

```yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: helloworld-enabled
  labels:
    run: helloworld-enabled
spec:
  replicas: 1
  selector:
    matchLabels:
      run: helloworld-enabled
  template:
    metadata:
      annotations:
        linkerd.io/inject: enabled
      labels:
        run: helloworld-enabled
    spec:
      containers:
      - name: helloworld-enabled
        image: buoyantio/helloworld
```

If you apply that configuration to your cluster, you can verify that the
deployment's pod is injected with a `linkerd-proxy` container:

```bash
$ kubectl get po -l run=helloworld-enabled \
  -o jsonpath='{.items[0].spec.containers[*].name}'
helloworld-enabled linkerd-proxy
```

Additionally, it's possible to disable auto-injection for all pods in a
deployment, even if that deployment is running in a namespace that has been
configured for auto-inject. To do this, add the `linkerd.io/inject: disabled`
annotation to the deployment's pod spec. For example, create a new deployment in
the `sample-inject-enabled-ns` namespace that you created above, as follows:

```yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: helloworld-disabled
  namespace: sample-inject-enabled-ns
  labels:
    run: helloworld-disabled
spec:
  replicas: 1
  selector:
    matchLabels:
      run: helloworld-disabled
  template:
    metadata:
      annotations:
        linkerd.io/inject: disabled
      labels:
        run: helloworld-disabled
    spec:
      containers:
      - name: helloworld-disabled
        image: buoyantio/helloworld
```

If you apply that configuration to your cluster, you can verify that the
deployment's pod is not injected with a `linkerd-proxy` container, as follows:

```bash
$ kubectl -n sample-inject-enabled-ns get po -l run=helloworld-disabled \
  -o jsonpath='{.items[0].spec.containers[*].name}'
helloworld-disabled
```

Note that no `linkerd-proxy` container is present.
