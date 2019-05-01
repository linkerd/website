+++
title = "Adding Your Service"
description = "Add your service to the mesh by injecting it."
aliases = [
  "/2/adding-your-service/"
]
+++

In order for your service to take advantage of Linkerd, it needs to have the
proxy sidecar added to its resource definition. This is done by using the
Linkerd [CLI](/2/reference/architecture/#cli) to update the definition
and add an annotation that will signal the proxy injector to inject the YAML
for the proxy sidecar when the pod gets created. This can then be passed to
`kubectl`. By using Kubernetes' rolling updates, the availability of your
application will not be affected.

To add Linkerd to your service, run:

```bash
linkerd inject deployment.yml \
  | kubectl apply -f -
```

`deployment.yml` is the Kubernetes config file containing your
application. This will add the annotation that the proxy injector will detect
so it can add the proxy sidecar along with an `initContainer` that
configures iptables to pass all traffic through the proxy. By applying this new
configuration via `kubectl`, a rolling update of your deployment will be
triggered replacing each pod with a new one.

You will know that your service has been successfully added to the service mesh
if it's pods are reported to be meshed in the Meshed column of the Linkerd
dashboard.

{{< fig src="/images/getting-started/stat.png" title="Dashboard" >}}

You can always get to the Linkerd dashboard by running:

```bash
linkerd dashboard
```

## Inject Reference

For more information on how the inject command works and all of the parameters
that can be set, look at the [reference](/2/reference/cli/inject/).
