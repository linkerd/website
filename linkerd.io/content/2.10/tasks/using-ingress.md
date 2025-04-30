---
title: Ingress traffic
description: Linkerd works alongside your ingress controller of choice.
---

For reasons of simplicity and composability, Linkerd doesn't provide a built-in
ingress. Instead, Linkerd is designed to work with existing Kubernetes ingress
solutions.

Combining Linkerd and your ingress solution requires two things:

1. Configuring your ingress to support Linkerd.
2. Meshing your ingress pods so that they have the Linkerd proxy installed.

Meshing your ingress pods will allow Linkerd to provide features like L7 metrics
and mTLS the moment the traffic is inside the cluster. (See
[Adding your service](adding-your-service/) for instructions on how to mesh
your ingress.)

Note that some ingress options need to be meshed in "ingress" mode. See details
below.

Common ingress options that Linkerd has been used with include:

- [Ambassador / Emissary-ingress](#ambassador)
- [Contour](#contour)
- [GCE](#gce)
- [Gloo](#gloo)
- [Haproxy](#haproxy)
- [Kong](#kong)
- [Nginx](#nginx)
- [Traefik](#traefik)

For a quick start guide to using a particular ingress, please visit the section
for that ingress. If your ingress is not on that list, never fear—it likely
works anyways. See [Ingress details](#ingress-details) below.

{{< note >}} If your ingress terminates TLS, this TLS traffic (e.g. HTTPS calls
from outside the cluster) will pass through Linkerd as an opaque TCP stream and
Linkerd will only be able to provide byte-level metrics for this side of the
connection. The resulting HTTP or gRPC traffic to internal services, of course,
will have the full set of metrics and mTLS support. {{< /note >}}

## Ambassador (aka Emissary) {#ambassador}

Ambassador can be meshed normally. An example manifest for configuring the
Ambassador / Emissary is as follows:

```yaml
apiVersion: getambassador.io/v3alpha1
kind: Mapping
metadata:
  name: web-ambassador-mapping
  namespace: emojivoto
spec:
  hostname: '*'
  prefix: /
  service: http://web-svc.emojivoto.svc.cluster.local:80
```

For a more detailed guide, we recommend reading
[Installing the Emissary ingress with the Linkerd service mesh](https://buoyant.io/2021/05/24/emissary-and-linkerd-the-best-of-both-worlds/).

## Nginx

Nginx can be meshed normally, but the
[`nginx.ingress.kubernetes.io/service-upstream`](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/#service-upstream)
annotation should be set to `"true"`. No further configuration is required.

```yaml
# apiVersion: networking.k8s.io/v1beta1 # for k8s < v1.19
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: emojivoto-web-ingress
  namespace: emojivoto
  annotations:
    nginx.ingress.kubernetes.io/service-upstream: 'true'
spec:
  ingressClassName: nginx
  defaultBackend:
    service:
      name: web-svc
      port:
        number: 80
```

## Traefik

Traefik should be meshed with ingress mode enabled, i.e. with the
`linkerd.io/inject: ingress` annotation rather than the default `enabled`.

Instructions differ for 1.x and 2.x versions of Traefik.

### Traefik 1.x

The simplest way to use Traefik 1.x as an ingress for Linkerd is to configure a
Kubernetes `Ingress` resource with the
`ingress.kubernetes.io/custom-request-headers` like this:

```yaml
# apiVersion: networking.k8s.io/v1beta1 # for k8s < v1.19
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress
  namespace: emojivoto
  annotations:
    ingress.kubernetes.io/custom-request-headers: l5d-dst-override:web-svc.emojivoto.svc.cluster.local:80
spec:
  ingressClassName: traefik
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

The important annotation here is:

```yaml
ingress.kubernetes.io/custom-request-headers: l5d-dst-override:web-svc.emojivoto.svc.cluster.local:80
```

Traefik will add a `l5d-dst-override` header to instruct Linkerd what service
the request is destined for. You'll want to include both the Kubernetes service
FQDN (`web-svc.emojivoto.svc.cluster.local`) _and_ the destination
`servicePort`.

To test this, you'll want to get the external IP address for your controller. If
you installed Traefik via Helm, you can get that IP address by running:

```bash
kubectl get svc --all-namespaces \
  -l app=traefik \
  -o='custom-columns=EXTERNAL-IP:.status.loadBalancer.ingress[0].ip'
```

You can then use this IP with curl:

```bash
curl -H "Host: example.com" http://external-ip
```

{{< note >}} This solution won't work if you're using Traefik's service weights
as Linkerd will always send requests to the service name in `l5d-dst-override`.
A workaround is to use `traefik.frontend.passHostHeader: "false"` instead.
{{< /note >}}

### Traefik 2.x

Traefik 2.x adds support for path based request routing with a Custom Resource
Definition (CRD) called
[`IngressRoute`](https://docs.traefik.io/providers/kubernetes-crd/).

If you choose to use `IngressRoute` instead of the default Kubernetes `Ingress`
resource, then you'll also need to use the Traefik's
[`Middleware`](https://docs.traefik.io/middlewares/headers/) Custom Resource
Definition to add the `l5d-dst-override` header.

The YAML below uses the Traefik CRDs to produce the same results for the
`emojivoto` application, as described above.

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: l5d-header-middleware
  namespace: traefik
spec:
  headers:
    customRequestHeaders:
      l5d-dst-override: 'web-svc.emojivoto.svc.cluster.local:80'
---
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  annotations:
    kubernetes.io/ingress.class: traefik
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
          nativeLB: true
```

## GCE

The GCE ingress should be meshed with ingress mode enabled, i.e. with the
`linkerd.io/inject: ingress` annotation rather than the default `enabled`.

This example shows how to use a
[Google Cloud Static External IP Address](https://cloud.google.com/compute/docs/ip-addresses/reserve-static-external-ip-address)
and TLS with a
[Google-managed certificate](https://cloud.google.com/load-balancing/docs/ssl-certificates#managed-certs).

```yaml
# apiVersion: networking.k8s.io/v1beta1 # for k8s < v1.19
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress
  namespace: emojivoto
  annotations:
    ingress.kubernetes.io/custom-request-headers:
      'l5d-dst-override: web-svc.emojivoto.svc.cluster.local:80'
    ingress.gcp.kubernetes.io/pre-shared-cert: 'managed-cert-name'
    kubernetes.io/ingress.global-static-ip-name: 'static-ip-name'
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

Gloo should be meshed with ingress mode enabled, i.e. with the
`linkerd.io/inject: ingress` annotation rather than the default `enabled`.

As of Gloo v0.13.20, Gloo has native integration with Linkerd, so that the
required Linkerd headers are added automatically. Assuming you installed Gloo to
the default location, you can enable the native integration by running:

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

Contour should be meshed with ingress mode enabled, i.e. with the
`linkerd.io/inject: ingress` annotation rather than the default `enabled`.

The following example uses the
[Contour getting started](https://projectcontour.io/getting-started/)
documentation to demonstrate how to set the required header manually.

Contour's Envoy DaemonSet doesn't auto-mount the service account token, which is
required for the Linkerd proxy to do mTLS between pods. So first we need to
install Contour uninjected, patch the DaemonSet with
`automountServiceAccountToken: true`, and then inject it. Optionally you can
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

{{< note >}} You should annotate the pod spec with
`config.linkerd.io/skip-outbound-ports: 8001`. The Envoy pod will try to connect
to the Contour pod at port 8001 through TLS, which is not supported under this
ingress mode, so you need to have the proxy skip that outbound port.
{{< /note >}}

{{< note >}} If you are using Contour with
[flagger](https://github.com/weaveworks/flagger) the `l5d-dst-override` headers
will be set automatically. {{< /note >}}

### Kong

Kong should be meshed with ingress mode enabled, i.e. with the
`linkerd.io/inject: ingress` annotation rather than the default `enabled`.

This example will use the following elements:

- The [Kong chart](https://github.com/Kong/charts)
- The [emojivoto] example application(../../getting-started/)

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
                  number: http
          - path: /api/list
            pathType: Prefix
            backend:
              service:
                name: web-svc
                port:
                  name: http
```

Here we are explicitly setting the `l5d-dst-override` in the `KongPlugin`. Using
[templates as values](https://docs.konghq.com/hub/kong-inc/request-transformer/#template-as-value),
we can use the `host` header from requests and set the `l5d-dst-override` value
based off that.

Finally, install emojivoto so that it's `deploy/vote-bot` targets the ingress
and includes a `host` header value for the `web-svc.emojivoto` service.

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

{{< note >}} There are two different haproxy-based ingress controllers. This
example is for the
[kubernetes-ingress controller by haproxytech](https://www.haproxy.com/documentation/kubernetes/latest/)
and not the [haproxy-ingress controller](https://haproxy-ingress.github.io/).
{{< /note >}}

Haproxy should be meshed with ingress mode enabled, i.e. with the
`linkerd.io/inject: ingress` annotation rather than the default `enabled`.

The simplest way to use Haproxy as an ingress for Linkerd is to configure a
Kubernetes `Ingress` resource with the `haproxy.org/request-set-header`
annotation like this:

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

## Ingress details

In this section we cover how Linkerd interacts with ingress controllers in
general.

In general, Linkerd can be used with any ingress controller. In order for
Linkerd to properly apply features such as route-based metrics and traffic
splitting, Linkerd needs the IP/port of the Kubernetes Service. However, by
default, many ingresses do their own endpoint selection and pass the IP/port of
the destination Pod, rather than the Service as a whole.

Thus, combining an ingress with Linkerd takes one of two forms:

1. Configure the ingress to pass the IP and port of the Service as the
   destination, i.e. to skip its own endpoint selection. (E.g. see
   [Nginx](#nginx) above.)

2. If this is not possible, then configure the ingress to pass the Service
   IP/port in a header such as `l5d-dst-override`, `Host`, or `:authority`, and
   configure Linkerd in _ingress_ mode. In this mode, it will read from one of
   those headers instead.

The most common approach in form #2 is to use the explicit `l5d-dst-override`
header.

{{< note >}} Some ingress controllers support sticky sessions. For session
stickiness, the ingress controller has to do its own endpoint selection. This
means that Linkerd will not be able to connect to the IP/port of the Kubernetes
Service, and will instead establish a direct connection to a pod. Therefore,
sticky sessions and `ServiceProfiles` are mutually exclusive. {{< /note >}}

{{< note >}} If requests experience a 2-3 second delay after injecting your
ingress controller, it is likely that this is because the service of
`type: LoadBalancer` is obscuring the client source IP. You can fix this by
setting `externalTrafficPolicy: Local` in the ingress' service definition.
{{< /note >}}

{{< note >}} While the Kubernetes Ingress API definition allows a `backend`'s
`servicePort` to be a string value, only numeric `servicePort` values can be
used with Linkerd. If a string value is encountered, Linkerd will default to
using port 80. {{< /note >}}
