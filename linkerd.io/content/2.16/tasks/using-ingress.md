+++
title = "Handling ingress traffic"
description = "Linkerd can work alongside your ingress controller of choice."
+++

Ingress traffic refers to traffic that comes into your cluster from outside the
cluster. For reasons of simplicity and composability, Linkerd itself doesn't
provide a built-in ingress solution for handling traffic coming into the
cluster. Instead, Linkerd is designed to work with the many existing Kubernetes
ingress options.

Combining Linkerd and your ingress solution of choice requires two things:

1. Configuring your ingress to support Linkerd (if necessary).
2. Meshing your ingress pods.

Strictly speaking, meshing your ingress pods is not required to allow traffic
into the cluster. However, it is recommended, as it allows Linkerd to provide
features like L7 metrics and mutual TLS the moment the traffic enters the
cluster.

## Handling external TLS

One common job for ingress controllers is to terminate TLS from the outside
world, e.g. HTTPS calls.

Like all pods, traffic to a meshed ingress has both an inbound and an outbound
component. If your ingress terminates TLS, Linkerd will treat this inbound TLS
traffic as an opaque TCP stream, and will only be able to provide byte-level
metrics for this side of the connection.

Once the ingress controller terminates the TLS connection and issues the
corresponding HTTP or gRPC traffic to internal services, these outbound calls
will have the full set of metrics and mTLS support.

## Ingress mode {#ingress-mode}

Most ingress controllers can be meshed like any other service, i.e. by
applying the `linkerd.io/inject: enabled` annotation at the appropriate level.
(See [Adding your services to Linkerd](../adding-your-service/) for more.)

However, some ingress options need to be meshed in a special "ingress" mode,
using the `linkerd.io/inject: ingress` annotation.

The instructions below will describe, for each ingress, whether it requires this
mode of operation.

If you're using "ingress" mode, we recommend that you set this ingress
annotation at the workload level rather than at the namespace level, so that
other resources in the ingress namespace are be meshed normally.

{{< warning id=open-relay-warning >}}
When an ingress is meshed in ingress mode, you _must_ configure it to remove
the `l5d-dst-override` header to avoid creating an open relay to cluster-local
and external endpoints.
{{< /warning >}}

{{< note >}}
Linkerd versions 2.13.0 through 2.13.4 had a bug whereby the `l5d-dst-override`
header was *required* in ingress mode, or the request would fail. This bug was
fixed in 2.13.5, and was not present prior to 2.13.0.
{{< /note >}}

{{< note >}}
Be sure to not deploy the ingress controller in the `kube-system` or `cert-manager`
namespace, as Linkerd [ignores these namespaces by default for injection](https://linkerd.io/2.16/features/proxy-injection/#exclusions).
{{< /note >}}

For more on ingress mode and why it's necessary, see [Ingress
details](#ingress-details) below.

## Common ingress options for Linkerd

Common ingress options that Linkerd has been used with include:

- [Ambassador (aka Emissary)](#ambassador)
- [Nginx (community version)](#nginx-community-version)
- [Nginx (F5 NGINX version)](#nginx-f5-nginx-version)
- [Traefik](#traefik)
  - [Traefik with normal mode (2.10 and newer versions)](#traefik-normal-mode)
  - [Traefik with ingress mode](#traefik-ingress-mode)
- [GCE](#gce)
- [Gloo](#gloo)
- [Contour](#contour)
- [Kong](#kong)
- [Haproxy](#haproxy)
- [EnRoute](#enroute)
- [ngrok](#ngrok)

For a quick start guide to using a particular ingress, please visit the section
for that ingress below. If your ingress is not on that list, never fear—it
likely works anyways. See [Ingress details](#ingress-details) below.

## Emissary-Ingress (aka Ambassador) {#ambassador}

Emissary-Ingress can be meshed normally: it does not require the [ingress
mode](#ingress-mode) annotation. An example manifest for configuring
Ambassador / Emissary is as follows:

```yaml
apiVersion: getambassador.io/v3alpha1
kind: Mapping
metadata:
  name: web-ambassador-mapping
  namespace: emojivoto
spec:
  hostname: "*"
  prefix: /
  service: http://web-svc.emojivoto.svc.cluster.local:80
```

For a more detailed guide, we recommend reading [Installing the Emissary ingress
with the Linkerd service
mesh](https://buoyant.io/2021/05/24/emissary-and-linkerd-the-best-of-both-worlds/).

## Nginx (community version)

This section refers to the Kubernetes community version
of the Nginx ingress controller
[kubernetes/ingress-nginx](https://github.com/kubernetes/ingress-nginx).

Nginx can be meshed normally: it does not require the [ingress
mode](#ingress-mode) annotation.

The
[`nginx.ingress.kubernetes.io/service-upstream`](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/#service-upstream)
annotation should be set to `"true"`. For example:

```yaml
# apiVersion: networking.k8s.io/v1beta1 # for k8s < v1.19
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: emojivoto-web-ingress
  namespace: emojivoto
  annotations:
    nginx.ingress.kubernetes.io/service-upstream: "true"
spec:
  ingressClassName: nginx
  defaultBackend:
    service:
      name: web-svc
      port:
        number: 80
```

If using [the ingress-nginx Helm
chart](https://artifacthub.io/packages/helm/ingress-nginx/ingress-nginx), note
that the namespace containing the ingress controller should NOT be annotated
with `linkerd.io/inject: enabled`. Instead, you should annotate the `kind:
Deployment` (`.spec.template.metadata.annotations`). For example:

```yaml
controller:
  podAnnotations:
    linkerd.io/inject: enabled
...
```

The reason is because this Helm chart defines (among other things) two
Kubernetes resources:

1) `kind: ValidatingWebhookConfiguration`. This creates a short-lived pod named
 something like `ingress-nginx-admission-create-XXXXX` which quickly terminates.

2) `kind: Deployment`. This creates a long-running pod named something like
`ingress-nginx-controller-XXXX` which contains the Nginx docker
 container.

Setting the injection annotation at the namespace level would mesh the
short-lived pod, which would prevent it from terminating as designed.

## Nginx (F5 NGINX version)

This section refers to the Nginx ingress controller
developed and maintained by F5 NGINX
[nginxinc/kubernetes-ingress](https://github.com/nginxinc/kubernetes-ingress).

This version of Nginx can also be meshed normally
and does not require the [ingress mode](#ingress-mode) annotation.

The [VirtualServer/VirtualServerRoute CRD resource](https://docs.nginx.com/nginx-ingress-controller/configuration/virtualserver-and-virtualserverroute-resources/#virtualserverroute)
should be used in favor of the `ingress` resource (see
[this Github issue](https://github.com/nginxinc/kubernetes-ingress/issues/2529)
for more information).

The `use-cluster-ip` field should be set to `true`. For example:

```yaml
apiVersion: k8s.nginx.org/v1
kind: VirtualServer
metadata:
  name: emojivoto-web-ingress
  namespace: emojivoto
spec:
  ingressClassName: nginx
  upstreams:
    - name: web
      service: web-svc
      port: 80
      use-cluster-ip: true
  routes:
    - path: /
      action:
        pass: web
```

## Traefik

As of version 2.10, Traefik can be meshed normally: it does not require the
[ingress mode](#ingress-mode) annotation. Previous versions needed ingress
mode and custom headers.

### Traefik with normal mode (2.10 and newer versions) {#traefik-normal-mode}

With traefik versions 2.10 and newer "Kubernetes Service Native Load-Balancing"
can be set in the Custom Resource called [`IngressRoute`](
  https://docs.traefik.io/providers/kubernetes-crd/) with the
`services[n].nativeLB` field.

The YAML below exemplifies an IngressRoute for `emojivoto` application.

```yaml
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  creationTimestamp: null
  name: emojivoto-web-ingress-route
  namespace: emojivoto
spec:
  entryPoints: []
  routes:
  - kind: Rule
    match: PathPrefix(`/`)
    priority: 0
    services:
    - kind: Service
      name: web-svc
      port: 80
      nativeLB: true
```

### Traefik with ingress mode {#traefik-ingress-mode}

Versions of Traefik prior to 2.10 must use [ingress mode](#ingress-mode)
i.e. with the `linkerd.io/inject: ingress` annotation rather than
 the default `enabled`. and Traefik's [`Middleware`](https://docs.traefik.io/middlewares/headers/)
Custom Resource to add the `l5d-dst-override` header.

Traefik will add a `l5d-dst-override` header to instruct Linkerd what service
the request is destined for. You'll want to include both the Kubernetes service
FQDN (`web-svc.emojivoto.svc.cluster.local`) *and* the destination
`servicePort`.

The YAML below uses the Traefik custom resources to configure a route and
headers for the `emojivoto` application.

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: l5d-header-middleware
  namespace: traefik
spec:
  headers:
    customRequestHeaders:
      l5d-dst-override: "web-svc.emojivoto.svc.cluster.local:80"
---
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  creationTimestamp: null
  name: emojivoto-web-ingress-route
  namespace: emojivoto
spec:
  entryPoints: []
  routes:
  - kind: Rule
    match: PathPrefix(`/`)
    priority: 0
    middlewares:
    - name: l5d-header-middleware
    services:
    - kind: Service
      name: web-svc
      port: 80
```

{{< note >}}
Linkerd will always send requests to the service name in `l5d-dst-override`.
Traefik's load balancing with weights is not compatible with explicit headers.
{{< /note >}}

## GCE

The GCE ingress should be meshed with with [ingress mode
enabled](#ingress-mode), , i.e. with the `linkerd.io/inject: ingress`
annotation rather than the default `enabled`.

This example shows how to use a [Google Cloud Static External IP
Address](https://cloud.google.com/compute/docs/ip-addresses/reserve-static-external-ip-address)
and TLS with a [Google-managed
certificate](https://cloud.google.com/load-balancing/docs/ssl-certificates#managed-certs).

```yaml
# apiVersion: networking.k8s.io/v1beta1 # for k8s < v1.19
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress
  namespace: emojivoto
  annotations:
    ingress.kubernetes.io/custom-request-headers: "l5d-dst-override: web-svc.emojivoto.svc.cluster.local:80"
    ingress.gcp.kubernetes.io/pre-shared-cert: "managed-cert-name"
    kubernetes.io/ingress.global-static-ip-name: "static-ip-name"
spec:
  ingressClassName: gce
  rules:
  - host: example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-svc
            port:
              number: 80
```

To use this example definition, substitute `managed-cert-name` and
`static-ip-name` with the short names defined in your project (n.b. use the name
for the IP address, not the address itself).

The managed certificate will take about 30-60 minutes to provision, but the
status of the ingress should be healthy within a few minutes. Once the managed
certificate is provisioned, the ingress should be visible to the Internet.

## Gloo

Gloo should be meshed with [ingress mode enabled](#ingress-mode), i.e. with the
`linkerd.io/inject: ingress` annotation rather than the default `enabled`.

As of Gloo v0.13.20, Gloo has native integration with Linkerd, so that the
required Linkerd headers are added automatically. Assuming you installed Gloo
to the default location, you can enable the native integration by running:

```bash
kubectl patch settings -n gloo-system default \
  -p '{"spec":{"linkerd":true}}' --type=merge
```

Gloo will now automatically add the `l5d-dst-override` header to every
Kubernetes upstream.

Now simply add a route to the upstream, e.g.:

```bash
glooctl add route --path-prefix=/ --dest-name booksapp-webapp-7000
```

## Contour

Contour should be meshed with [ingress mode enabled](#ingress-mode), i.e. with
the `linkerd.io/inject: ingress` annotation rather than the default `enabled`.

The following example uses the
[Contour getting started](https://projectcontour.io/getting-started/) documentation
to demonstrate how to set the required header manually.

Contour's Envoy DaemonSet doesn't auto-mount the service account token, which
is required for the Linkerd proxy to do mTLS between pods. So first we need to
install Contour uninjected, patch the DaemonSet with
`automountServiceAccountToken: true`, and then inject it.  Optionally you can
create a dedicated service account to avoid using the `default` one.

```bash
# install Contour
kubectl apply -f https://projectcontour.io/quickstart/contour.yaml

# create a service account (optional)
kubectl apply -f - << EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: envoy
  namespace: projectcontour
EOF

# add service account to envoy (optional)
kubectl patch daemonset envoy -n projectcontour --type json -p='[{"op": "add", "path": "/spec/template/spec/serviceAccount", "value": "envoy"}]'

# auto mount the service account token (required)
kubectl patch daemonset envoy -n projectcontour --type json -p='[{"op": "replace", "path": "/spec/template/spec/automountServiceAccountToken", "value": true}]'

# inject linkerd first into the DaemonSet
kubectl -n projectcontour get daemonset -oyaml | linkerd inject - | kubectl apply -f -

# inject linkerd into the Deployment
kubectl -n projectcontour get deployment -oyaml | linkerd inject - | kubectl apply -f -
```

Verify your Contour and Envoy installation has a running Linkerd sidecar.

Next we'll deploy a demo service:

```bash
linkerd inject https://projectcontour.io/examples/kuard.yaml | kubectl apply -f -
```

To route external traffic to your service you'll need to provide a HTTPProxy:

```yaml
apiVersion: projectcontour.io/v1
kind: HTTPProxy
metadata:
  name: kuard
  namespace: default
spec:
  routes:
  - requestHeadersPolicy:
      set:
      - name: l5d-dst-override
        value: kuard.default.svc.cluster.local:80
    services:
    - name: kuard
      port: 80
  virtualhost:
    fqdn: 127.0.0.1.nip.io
```

Notice the `l5d-dst-override` header is explicitly set to the target `service`.

Finally, you can test your working service mesh:

```bash
kubectl port-forward svc/envoy -n projectcontour 3200:80
http://127.0.0.1.nip.io:3200
```

{{< note >}}
You should annotate the pod spec with `config.linkerd.io/skip-outbound-ports:
8001`. The Envoy pod will try to connect to the Contour pod at port 8001
through TLS, which is not supported under this ingress mode, so you need to
have the proxy skip that outbound port.
{{< /note >}}

{{< note >}}
If you are using Contour with [flagger](https://github.com/weaveworks/flagger)
the `l5d-dst-override` headers will be set automatically.
{{< /note >}}

### Kong

Kong should be meshed with [ingress mode enabled](#ingress-mode), i.e. with the
`linkerd.io/inject: ingress` annotation rather than the default `enabled`.

This example will use the following elements:

- The [Kong chart](https://github.com/Kong/charts)
- The [emojivoto](../../getting-started/) example application

Before installing emojivoto, install Linkerd and Kong on your cluster. When
injecting the Kong deployment, use the `--ingress` flag (or annotation).

We need to declare KongPlugin (a Kong CRD) and Ingress resources as well.

```yaml
apiVersion: configuration.konghq.com/v1
kind: KongPlugin
metadata:
  name: set-l5d-header
  namespace: emojivoto
plugin: request-transformer
config:
  remove:
    headers:
    - l5d-dst-override # Prevents open relay
  add:
    headers:
    - l5d-dst-override:$(headers.host).svc.cluster.local
---
# apiVersion: networking.k8s.io/v1beta1 # for k8s < v1.19
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress
  namespace: emojivoto
  annotations:
    konghq.com/plugins: set-l5d-header
spec:
  ingressClassName: kong
  rules:
  - http:
      paths:
      - path: /api/vote
        pathType: Prefix
        backend:
          service:
            name: web-svc
            port:
              name: http
      - path: /api/list
        pathType: Prefix
        backend:
          service:
            name: web-svc
            port:
              name: http
```

Here we are explicitly setting the `l5d-dst-override` in the `KongPlugin`.
Using [templates as
values](https://docs.konghq.com/hub/kong-inc/request-transformer/#template-as-value),
we can use the `host` header from requests and set the `l5d-dst-override` value
based off that.

Finally, install emojivoto so that it's `deploy/vote-bot` targets the
ingress and includes a `host` header value for the `web-svc.emojivoto` service.

Before applying the injected emojivoto application, make the following changes
to the `vote-bot` Deployment:

```yaml
env:
# Target the Kong ingress instead of the Emojivoto web service
- name: WEB_HOST
  value: kong-proxy.kong:80
# Override the host header on requests so that it can be used to set the l5d-dst-override header
- name: HOST_OVERRIDE
  value: web-svc.emojivoto
```

### Haproxy

{{< note >}}
There are two different haproxy-based ingress controllers.  This example is for
the [kubernetes-ingress controller by
haproxytech](https://www.haproxy.com/documentation/kubernetes/latest/) and not
the [haproxy-ingress controller](https://haproxy-ingress.github.io/).
{{< /note >}}

Haproxy should be meshed with [ingress mode enabled](#ingress-mode), i.e. with
the `linkerd.io/inject: ingress` annotation rather than the default `enabled`.

The simplest way to use Haproxy as an ingress for Linkerd is to configure a
Kubernetes `Ingress` resource with the
`haproxy.org/request-set-header` annotation like this:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress
  namespace: emojivoto
  annotations:
    kubernetes.io/ingress.class: haproxy
    haproxy.org/request-set-header: |
      l5d-dst-override web-svc.emojivoto.svc.cluster.local:80
spec:
  rules:
  - host: example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-svc
            port:
              number: 80
```

Unfortunately, there is currently no support to do this dynamically in
a global config map by using the service name, namespace and port as variable.
This also means, that you can't combine more than one service ingress rule
in an ingress manifest as each one needs their own
`haproxy.org/request-set-header` annotation with hard coded value.

## EnRoute OneStep {#enroute}

Meshing EnRoute with Linkerd involves only setting one flag globally:

```yaml
apiVersion: enroute.saaras.io/v1
kind: GlobalConfig
metadata:
  labels:
    app: web
  name: enable-linkerd
  namespace: default
spec:
  name: linkerd-global-config
  type: globalconfig_globals
  config: |
        {
          "linkerd_enabled": true
        }
```

EnRoute can now be meshed by injecting Linkerd proxy in EnRoute pods.
Using the `linkerd` utility, we can update the EnRoute deployment
to inject Linkerd proxy.

```bash
kubectl get -n enroute-demo deploy -o yaml | linkerd inject - | kubectl apply -f -
```

The `linkerd_enabled` flag automatically sets `l5d-dst-override` header.
The flag also delegates endpoint selection for routing to linkerd.

More details and customization can be found in,
[End to End encryption using EnRoute with
Linkerd](https://getenroute.io/blog/end-to-end-encryption-mtls-linkerd-enroute/)

## ngrok

ngrok can be meshed normally: it does not require the
[ingress mode](#ingress-mode) annotation.

After signing up for a [free ngrok account](https://ngrok.com/signup), and
running through the [installation steps for the ngrok Ingress controller
](https://github.com/ngrok/kubernetes-ingress-controller#installation),
you can add ingress by configuring an ingress object for your service and
applying it with `kubectl apply -f ingress.yaml`.

This is an example for the emojivoto app used in the Linkerd getting started
guide. You will need to replace the `host` value with your
[free static domain](https://dashboard.ngrok.com/cloud-edge/domains) available
in your ngrok account. If you have a paid ngrok account, you can configure this
the same way you would use the [`--domain`
flag](https://ngrok.com/docs/secure-tunnels/ngrok-agent/reference/ngrok/) on
the ngrok agent.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: emojivoto-ingress
  namespace: emojivoto
spec:
  ingressClassName: ngrok
  rules:
  - host: [YOUR STATIC DOMAIN.ngrok-free.app]
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-svc
            port:
              number: 80
```

Your emojivoto app should be available to anyone in the world at your static
domain.

## Ingress details

In this section we cover how Linkerd interacts with ingress controllers in
general.

In order for Linkerd to properly apply L7 features such as route-based metrics
and dynamic traffic routing, Linkerd needs the ingress controller to connect
to the IP/port of the destination Kubernetes Service. However, by default,
many ingresses do their own endpoint selection and connect directly to the
IP/port of the destination Pod, rather than the Service.

Thus, combining an ingress with Linkerd takes one of two forms:

1. Configure the ingress to connect to the IP and port of the Service as the
   destination, i.e. to skip its own endpoint selection. (E.g. see
   [Nginx](#nginx) above.)

2. Alternatively, configure the ingress to pass the Service IP/port in a
   header such as `l5d-dst-override`, `Host`, or `:authority`, and configure
   Linkerd in *ingress* mode. In this mode, it will read from one of those
   headers instead.

The most common approach in form #2 is to use the explicit `l5d-dst-override` header.

{{< note >}}
Some ingress controllers support sticky sessions. For session stickiness, the
ingress controller has to do its own endpoint selection. This means that
Linkerd will not be able to connect to the IP/port of the Kubernetes Service,
and will instead establish a direct connection to a pod. Therefore, sticky
sessions and `ServiceProfiles` are mutually exclusive.
{{< /note >}}

{{< note >}}
If requests experience a 2-3 second delay after injecting your ingress
controller, it is likely that this is because the service of `type:
LoadBalancer` is obscuring the client source IP. You can fix this by setting
`externalTrafficPolicy: Local` in the ingress' service definition.
{{< /note >}}

{{< note >}}
While the Kubernetes Ingress API definition allows a `backend`'s `servicePort`
to be a string value, only numeric `servicePort` values can be used with
Linkerd. If a string value is encountered, Linkerd will default to using port
80.
{{< /note >}}
