+++
title = "Automating Injection"
description = "Automate injection of the Linkerd containers for your service."
+++

[Automatic proxy injection](/2/features/proxy-injection/) is implemented with an
[admission webhook](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/#admission-webhooks).
There are a few things to note about this feature:

- As of versions stable-2.4.0 and edge-19.4.5 this feature is enabled by default.

- Adding the annotation on a namespace will not automatically update all the
  resources. You will need to update the resources in this namespace (e.g.,
  with `kubectl apply`, `kubectl edit`) for them to be injected. This is because
  injection happens at admission and on each specific resource. Kubernetes will
  not call the mutating webhook until it sees an update on each individual
  resource.

- The experimental version of this feature, prior to the stable-2.2 and
  edge-19.2.1 releases, injected all pods in all namespaces, but the current
  version requires that you explicitly annotate your namespaces or pods as
  described below to enable auto-injection.

- To make use of automatic injection, your cluster requires the
`admissionregistration.k8s.io/v1beta1`. To verify, run:

```bash
$ kubectl api-versions | grep admissionregistration
admissionregistration.k8s.io/v1beta1
```

## Installation

(This only applies to versions prior stable-2.4.0 and edge-19.4.5)

Automatic proxy injection is disabled by default when installing the Linkerd
control plane. To enable it, set the `--proxy-auto-inject` flag, as follows:

```bash
# during installation
linkerd install --proxy-auto-inject | kubectl apply -f -

# or during an upgrade
linkerd upgrade --proxy-auto-inject | kubectl apply -f -
```

Take a look at the new `linkerd-proxy-injector` deployment to verify everything
is working correctly:

```bash
kubectl -n linkerd get deploy/linkerd-proxy-injector svc/linkerd-proxy-injector
```

The output will look like:

```bash
NAME                                           DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deployment.extensions/linkerd-proxy-injector   1         1         1            1           3m

NAME                             TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
service/linkerd-proxy-injector   ClusterIP   10.100.40.55   <none>        443/TCP   3m
```

## Configuration

Automatic proxy injection  will only be performed on pods with the
`linkerd.io/inject: enabled` annotation, or on pods in namespaces with the
`linkerd.io/inject: enabled` annotation. If a namespace has been configured to
use auto-injection, it's also possible to disable injection for a given pod in
that namespace using the `linkerd.io/inject: disabled` annotation.

For example, to add automatic proxy injection for all pods in the
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
kubectl -n sample-inject-enabled-ns run helloworld --image=buoyantio/helloworld
```

Verify that the deployment's pod includes a `linkerd-proxy` container by
running:

```bash
kubectl -n sample-inject-enabled-ns get po -l run=helloworld \
  -o jsonpath='{.items[0].spec.containers[*].name}'
```

If everything was successful, you'll see:

```bash
helloworld linkerd-proxy
```

It's also possible to explicitly configure auto-injection for all pods in a
deployment, even if that deployment is running in a namespace that has not been
configured for auto-inject, by adding the `linkerd.io/inject: enabled`
annotation to the deployment's pod spec. This can be done by manually editing
the spec, or by piping the resources into the `linkerd inject` CLI command.

For example, create a new deployment in
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
kubectl get po -l run=helloworld-enabled \
  -o jsonpath='{.items[0].spec.containers[*].name}'
```

If everything worked, you'll see:

```bash
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
kubectl -n sample-inject-enabled-ns get po -l run=helloworld-disabled \
  -o jsonpath='{.items[0].spec.containers[*].name}'
```

There will not be a `linkerd-proxy` container in the output:

```bash
helloworld-disabled
```

## Sidecar Proxy Configuration Overrides

When the proxy injector adds the sidecar proxy container it configures it
according to the configuration set through flags when `linkerd install`
was issued (and eventually changed through `linkerd upgrade`).

You can override that configuration by adding [extra `config.linkerd.io`
annotations](/2/reference/proxy-configuration/) into the deployment's pod
spec, alongside the `linkerd.io/inject` annotation.
