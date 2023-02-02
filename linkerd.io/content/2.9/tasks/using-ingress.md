+++
title = "Ingress traffic"
description = "Linkerd works alongside your ingress controller of choice."
+++

As of Linkerd version 2.9, there are two ways in which the Linkerd proxy
can be run with your Ingress Controller.

## Proxy Modes

The Linkerd proxy offers two modes of operation in order to handle some of the
more subtle behaviors of load balancing in ingress controllers.

Be sure to check the documentation for your ingress controller of choice to
understand how it resolves endpoints for load balancing. If the ingress uses
the cluster IP and port of the Service, you can use the Default Mode described
below. Otherwise, read through the `Proxy Ingress Mode` section to understand
how it works.

### Default Mode

When the ingress controller is injected with the `linkerd.io/inject: enabled`
annotation, the Linkerd proxy will honor load balancing decisions made by the
ingress controller instead of applying [its own EWMA load balancing](../../features/load-balancing/).
This also means that the Linkerd proxy will not use Service Profiles for this
traffic and therefore will not expose per-route metrics or do traffic splitting.

If your Ingress controller is injected with no extra configuration specific to
ingress, the Linkerd proxy runs in the default mode.

{{< note >}}
Some ingresses, either by default or by configuration, can change the way that
they make load balancing decisions.

The nginx ingress controller and Emissary Ingress are two options that offer
this functionality. See the [Nginx]({{< ref "#nginx-proxy-mode-configuration" >}})
and [Emissary]({{< ref "#emissary-proxy-mode">}}) sections below for more info
{{< /note >}}

### Proxy Ingress Mode

If you want Linkerd functionality like Service Profiles, Traffic Splits, etc,
there is additional configuration required to make the Ingress controller's Linkerd
proxy run in `ingress` mode. This causes Linkerd to route requests based on
their `:authority`, `Host`, or `l5d-dst-override` headers instead of their original
destination which allows Linkerd to perform its own load balancing and use
Service Profiles to expose per-route metrics and enable traffic splitting.

The Ingress controller deployment's proxy can be made to run in `ingress` mode by
adding the following annotation i.e `linkerd.io/inject: ingress` in the Ingress
Controller's Pod Spec.

The same can be done by using the `--ingress` flag in the inject command.

```bash
kubectl get deployment <ingress-controller> -n <ingress-namespace> -o yaml | linkerd inject --ingress - | kubectl apply -f -
```

This can be verified by checking if the Ingress controller's pod has the relevant
annotation set.

```bash
kubectl describe pod/<ingress-pod> | grep "linkerd.io/inject: ingress"
```

When it comes to ingress, most controllers do not rewrite the
incoming header (`example.com`) to the internal service name
(`example.default.svc.cluster.local`) by default. In this case, when Linkerd
receives the outgoing request it thinks the request is destined for
`example.com` and not `example.default.svc.cluster.local`. This creates an
infinite loop that can be pretty frustrating!

Luckily, many ingress controllers allow you to either modify the `Host` header
or add a custom header to the outgoing request. Here are some instructions
for common ingress controllers:

- [Nginx]({{< ref "#nginx" >}})
- [Traefik]({{< ref "#traefik" >}})
- [GCE]({{< ref "#gce" >}})
- [Ambassador]({{< ref "#ambassador" >}})
- [Gloo]({{< ref "#gloo" >}})
- [Contour]({{< ref "#contour" >}})
- [Kong]({{< ref "#kong" >}})

{{< note >}}
If your ingress controller is terminating HTTPS, Linkerd will only provide
TCP stats for the incoming requests because all the proxy sees is encrypted
traffic. It will provide complete stats for the outgoing requests from your
controller to the backend services as this is in plain text from the
controller to Linkerd.
{{< /note >}}

{{< note >}}
If requests experience a 2-3 second delay after injecting your ingress
controller, it is likely that this is because the service of `type:
LoadBalancer` is obscuring the client source IP. You can fix this by setting
`externalTrafficPolicy: Local` in the ingress' service definition.
{{< /note >}}

{{< note >}}
While the Kubernetes Ingress API definition allows a `backend`'s `servicePort`
to be a string value, only numeric `servicePort` values can be used with Linkerd.
If a string value is encountered, Linkerd will default to using port 80.
{{< /note >}}

### Nginx

This uses `emojivoto` as an example, take a look at
[getting started](../../getting-started/) for a refresher on how to install it.

The sample ingress definition is:

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: web-ingress
  namespace: emojivoto
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/configuration-snippet: |
      proxy_set_header l5d-dst-override $service_name.$namespace.svc.cluster.local:$service_port;
      grpc_set_header l5d-dst-override $service_name.$namespace.svc.cluster.local:$service_port;

spec:
  rules:
  - host: example.com
    http:
      paths:
      - backend:
          serviceName: web-svc
          servicePort: 80
```

The important annotation here is:

```yaml
    nginx.ingress.kubernetes.io/configuration-snippet: |
      proxy_set_header l5d-dst-override $service_name.$namespace.svc.cluster.local:$service_port;
      grpc_set_header l5d-dst-override $service_name.$namespace.svc.cluster.local:$service_port;
```

Alternatively, instead of adding the `proxy_set_header` directive to each
`Ingress` resource individually, it is possible with Nginx Ingress Controller
to define it globally using the [Custom Headers](https://kubernetes.github.io/ingress-nginx/examples/customization/custom-headers/)
pattern.

For example:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: custom-headers
  namespace: ingress-nginx
data:
  proxy_set_header: "l5d-dst-override $service_name.$namespace.svc.cluster.local:$service_port;"
```

adjust above accordingly and follow the rest of the [instructions](https://kubernetes.github.io/ingress-nginx/examples/customization/custom-headers/)
on how to add this ConfigMap to Nginx Ingress Controller's global configuration.

{{< note >}}
This method doesn't cover `grpc_set_header` which needs to be added to the `Ingress`
that uses a GRPC backend service.
{{< /note >}}

{{< note >}}
If you are using [auth-url](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/#external-authentication)
you'd need to add the following snippet as well.

```yaml
    nginx.ingress.kubernetes.io/auth-snippet: |
      proxy_set_header l5d-dst-override authn-name.authn-namespace.svc.cluster.local:authn-port;
      grpc_set_header l5d-dst-override authn-name.authn-namespace.svc.cluster.local:authn-port;
```

{{< /note >}}

This example combines the two directives that NGINX uses for proxying HTTP
and gRPC traffic. In practice, it is only necessary to set either the
`proxy_set_header` or `grpc_set_header` directive, depending on the protocol
used by the service, however NGINX will ignore any directives that it doesn't
need.

This sample ingress definition uses a single ingress for an application
with multiple endpoints using different ports.

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: web-ingress
  namespace: emojivoto
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/configuration-snippet: |
      proxy_set_header l5d-dst-override $service_name.$namespace.svc.cluster.local:$service_port;
      grpc_set_header l5d-dst-override $service_name.$namespace.svc.cluster.local:$service_port;
spec:
  rules:
  - host: example.com
    http:
      paths:
      - path: /
        backend:
          serviceName: web-svc
          servicePort: 80
      - path: /another-endpoint
        backend:
          serviceName: another-svc
          servicePort: 8080
```

Nginx will add a `l5d-dst-override` header to instruct Linkerd what service
the request is destined for. You'll want to include both the Kubernetes service
FQDN (`web-svc.emojivoto.svc.cluster.local`) *and* the destination
`servicePort`.

To test this, you'll want to get the external IP address for your controller. If
you installed nginx-ingress via helm, you can get that IP address by running:

```bash
kubectl get svc --all-namespaces \
  -l app=nginx-ingress,component=controller \
  -o=custom-columns=EXTERNAL-IP:.status.loadBalancer.ingress[0].ip
```

You can then use this IP with curl:

```bash
curl -H "Host: example.com" http://external-ip
```

{{< note >}}
If you are using a default backend, you will need to create an ingress
definition for that backend to ensure that the `l5d-dst-override` header
is set. For example:

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: default-ingress
  namespace: backends
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/configuration-snippet: |
      proxy_set_header l5d-dst-override $service_name.$namespace.svc.cluster.local:$service_port;
      grpc_set_header l5d-dst-override $service_name.$namespace.svc.cluster.local:$service_port;
spec:
  backend:
    serviceName: default-backend
    servicePort: 80
```

{{< /note >}}

#### Nginx proxy mode configuration

The [nginx ingress controller](https://kubernetes.github.io/ingress-nginx/)
includes the [`nginx.ingress.kubernetes.io/service-upstream`](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/#service-upstream)
annotation. The default `false` value of this annotation adds an entry for each
kubernetes endpoint of a pod to the `upstream` block in the nginx configuration,
thereby informing nginx to load balance requests directly to the endpoints of a
service.

Setting this annotation to `true` configures the ingress controller to add
_only_ the cluster IP and port of the Service resource as the single entry to
the `upstream` block in the nginx configuration. As a result, the load balancing
decisions are offloaded to the Linkerd proxy. With this configuration, the
ServiceProfile and per-route metrics functionality _will_ be available with the
annotation `linkerd.io/inject: enabled`.

### Traefik

This uses `emojivoto` as an example, take a look at
[getting started](../../getting-started/) for a refresher on how to install it.

The simplest way to use Traefik as an ingress for Linkerd is to configure a
Kubernetes `Ingress` resource with the
`ingress.kubernetes.io/custom-request-headers` like this:

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: web-ingress
  namespace: emojivoto
  annotations:
    kubernetes.io/ingress.class: "traefik"
    ingress.kubernetes.io/custom-request-headers: l5d-dst-override:web-svc.emojivoto.svc.cluster.local:80
spec:
  rules:
  - host: example.com
    http:
      paths:
      - backend:
          serviceName: web-svc
          servicePort: 80
```

The important annotation here is:

```yaml
ingress.kubernetes.io/custom-request-headers: l5d-dst-override:web-svc.emojivoto.svc.cluster.local:80
```

Traefik will add a `l5d-dst-override` header to instruct Linkerd what service
the request is destined for. You'll want to include both the Kubernetes service
FQDN (`web-svc.emojivoto.svc.cluster.local`) *and* the destination
`servicePort`. Please see the Traefik website for more information.

To test this, you'll want to get the external IP address for your controller. If
you installed Traefik via helm, you can get that IP address by running:

```bash
kubectl get svc --all-namespaces \
  -l app=traefik \
  -o='custom-columns=EXTERNAL-IP:.status.loadBalancer.ingress[0].ip'
```

You can then use this IP with curl:

```bash
curl -H "Host: example.com" http://external-ip
```

{{< note >}}
This solution won't work if you're using Traefik's service weights as
Linkerd will always send requests to the service name in `l5d-dst-override`. A
workaround is to use `traefik.frontend.passHostHeader: "false"` instead. Be
aware that if you're using TLS, the connection between Traefik and the backend
service will not be encrypted. There is an
[open issue](https://github.com/linkerd/linkerd2/issues/2270) to track the
solution to this problem.
{{< /note >}}

#### Traefik 2.x

Traefik 2.x adds support for path based request routing with a Custom Resource
Definition (CRD) called `IngressRoute`.

If you choose to use [`IngressRoute`](https://docs.traefik.io/providers/kubernetes-crd/)
instead of the default Kubernetes `Ingress`
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
      l5d-dst-override: "web-svc.emojivoto.svc.cluster.local:80"
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
```

### GCE

This example is similar to Traefik, and also uses `emojivoto` as an example.
Take a look at [getting started](../../getting-started/) for a refresher on how to
install it.

In addition to the custom headers found in the Traefik example, it shows how to
use a [Google Cloud Static External IP Address](https://cloud.google.com/compute/docs/ip-addresses/reserve-static-external-ip-address)
and TLS with a [Google-managed certificate](https://cloud.google.com/load-balancing/docs/ssl-certificates#managed-certs).

The sample ingress definition is:

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: web-ingress
  namespace: emojivoto
  annotations:
    kubernetes.io/ingress.class: "gce"
    ingress.kubernetes.io/custom-request-headers: "l5d-dst-override: web-svc.emojivoto.svc.cluster.local:80"
    ingress.gcp.kubernetes.io/pre-shared-cert: "managed-cert-name"
    kubernetes.io/ingress.global-static-ip-name: "static-ip-name"
spec:
  rules:
  - host: example.com
    http:
      paths:
      - backend:
          serviceName: web-svc
          servicePort: 80
```

To use this example definition, substitute `managed-cert-name` and
`static-ip-name` with the short names defined in your project (n.b. use the name
for the IP address, not the address itself).

The managed certificate will take about 30-60 minutes to provision, but the
status of the ingress should be healthy within a few minutes. Once the managed
certificate is provisioned, the ingress should be visible to the Internet.

### Ambassador (aka Emissary) {#ambassador}

This uses `emojivoto` as an example, take a look at
[getting started](../../getting-started/) for a refresher on how to install it.

Emissary does not use `Ingress` resources, instead relying on `Service`. The
sample service definition is:

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

#### Emissary Proxy Mode

By default, Emissary uses Kubernetes DNS and [service-level discovery](https://www.getambassador.io/docs/emissary/latest/topics/running/resolvers/#kubernetes-service-level-discovery).
So, the `linkerd.io/inject` annotation can be set to `enabled` and all the
ServiceProfile, TrafficSplit, and per-route functionality will be available. It
is not necessary to use `ingress` mode, unless the service discovery behavior
of Emissary has been changed from the default.

To test this, you'll want to get the external IP address for your controller. If
you installed Emissary via helm, you can get that IP address by running:

```bash
kubectl get svc --all-namespaces \
  -l "app.kubernetes.io/name=ambassador" \
  -o='custom-columns=EXTERNAL-IP:.status.loadBalancer.ingress[0].ip'
```

{{< note >}}
If you've installed the admin interface, this will return two IPs, one of which
will be `<none>`. Just ignore that one and use the actual IP address.
{{</ note >}}

You can then use this IP with curl:

```bash
curl -H "Host: example.com" http://external-ip
```

{{< note >}}
You can also find a more detailed guide for using Linkerd with Emissary Ingress,
AKA Ambassador, from the folks over at Buoyant [here](https://buoyant.io/2021/05/24/emissary-and-linkerd-the-best-of-both-worlds/).
{{< /note >}}

### Gloo

This uses `books` as an example, take a look at
[Demo: Books](../books/) for instructions on how to run it.

If you installed Gloo using the Gateway method (`gloo install gateway`), then
you'll need a VirtualService to be able to route traffic to your **Books**
application.

To use Gloo with Linkerd, you can choose one of two options.

#### Automatic

As of Gloo v0.13.20, Gloo has native integration with Linkerd, so that the
required Linkerd headers are added automatically.

Assuming you installed gloo to the default location, you can enable the native
integration by running:

```bash
kubectl patch settings -n gloo-system default \
  -p '{"spec":{"linkerd":true}}' --type=merge
```

Gloo will now automatically add the `l5d-dst-override` header to every
kubernetes upstream.

Now simply add a route to the books app upstream:

```bash
glooctl add route --path-prefix=/ --dest-name booksapp-webapp-7000
```

#### Manual

As explained in the beginning of this document, you'll need to instruct Gloo to
add a header which will allow Linkerd to identify where to send traffic to.

```yaml
apiVersion: gateway.solo.io/v1
kind: VirtualService
metadata:
  name: books
  namespace: gloo-system
spec:
  virtualHost:
    domains:
    - '*'
    name: gloo-system.books
    routes:
    - matcher:
        prefix: /
      routeAction:
        single:
          upstream:
            name: booksapp-webapp-7000
            namespace: gloo-system
      routePlugins:
        transformations:
          requestTransformation:
            transformationTemplate:
              headers:
                l5d-dst-override:
                  text: webapp.booksapp.svc.cluster.local:7000
                passthrough: {}

```

The important annotation here is:

```yaml
      routePlugins:
        transformations:
          requestTransformation:
            transformationTemplate:
              headers:
                l5d-dst-override:
                  text: webapp.booksapp.svc.cluster.local:7000
                passthrough: {}
```

Using the content transformation engine built-in in Gloo, you can instruct it to
add the needed `l5d-dst-override` header which in the example above is pointing
to the service's FDQN and port: `webapp.booksapp.svc.cluster.local:7000`

#### Test

To easily test this you can get the URL of the Gloo proxy by running:

```bash
glooctl proxy URL
```

Which will return something similar to:

```bash
$ glooctl proxy url
http://192.168.99.132:30969
```

For the example VirtualService above, which listens to any domain and path,
accessing the proxy URL (`http://192.168.99.132:30969`) in your browser
should open the Books application.

### Contour

Contour doesn't support setting the `l5d-dst-override` header automatically.
The following example uses the
[Contour getting started](https://projectcontour.io/getting-started/) documentation
to demonstrate how to set the required header manually:

First, inject Linkerd into your Contour installation:

```bash
linkerd inject https://projectcontour.io/quickstart/contour.yaml | kubectl apply -f -
```

Envoy will not auto mount the service account token.
To fix this you need to set `automountServiceAccountToken: true`.
Optionally you can create a dedicated service account to avoid using the `default`.

```bash
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
      namespace: default
      port: 80
  virtualhost:
    fqdn: 127.0.0.1.xip.io
```

Notice the `l5d-dst-override` header is explicitly set to the target `service`.

Finally, you can test your working service mesh:

```bash
kubectl port-forward svc/envoy -n projectcontour 3200:80
http://127.0.0.1.xip.io:3200
```

{{< note >}}
If you are using Contour with [flagger](https://github.com/weaveworks/flagger)
the `l5d-dst-override` headers will be set automatically.
{{< /note >}}

### Kong

Kong doesn't support the header `l5d-dst-override` automatically.  
This documentation will use the following elements:

- [Kong](https://github.com/Kong/charts)
- [Emojivoto](../../getting-started/)

Before installing the Emojivoto demo application, install Linkerd and Kong on
your cluster. Remember when injecting the Kong deployment to use the `--ingress`
flag (or annotation) as mentioned
[above](../using-ingress/#proxy-ingress-mode)!

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
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: web-ingress
  namespace: emojivoto
  annotations:
    kubernetes.io/ingress.class: "kong"
    konghq.com/plugins: set-l5d-header
spec:
  rules:
    - http:
        paths:
          - path: /api/vote
            backend:
              serviceName: web-svc
              servicePort: http
          - path: /api/list
            backend:
              serviceName: web-svc
              servicePort: http
```

We are explicitly setting the `l5d-dst-override` in the `KongPlugin`. Using
[templates as
values](https://docs.konghq.com/hub/kong-inc/request-transformer/#template-as-value),
we can use the `host` header from requests and set the `l5d-dst-override` value
based off that.

Finally, lets install Emojivoto so that it's `deploy/vote-bot` targets the
ingress and includes a `host` header value for the `web-svc.emojivoto` service.

Before applying the injected Emojivoto application, make the following changes
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
