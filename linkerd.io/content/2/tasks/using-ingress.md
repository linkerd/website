+++
title = "Using Ingress"
description = "Linkerd works alongside your ingress controller of choice."
+++

If you're planning on injecting Linkerd into your ingress controller's pods
there is some configuration required. Linkerd discovers services based on the
`:authority` or `Host` header. This allows Linkerd to understand what service a
request is destined for without being dependent on DNS or IPs.

When it comes to ingress, most controllers do not rewrite the
incoming header (`example.com`) to the internal service name
(`example.default.svc.cluster.local`) by default. In this case, when Linkerd
receives the outgoing request it thinks the request is destined for
`example.com` and not `example.default.svc.cluster.local`. This creates an
infinite loop that can be pretty frustrating!

Luckily, many ingress controllers allow you to either modify the `Host` header
or add a custom header to the outgoing request. Here are some instructions
for common ingress controllers:

{{% pagetoc %}}

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

## Nginx

This uses `emojivoto` as an example, take a look at
[getting started](/2/getting-started/) for a refresher on how to install it.

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
```

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
It is not possible to rewrite the header in this way for the default
backend. Because of this, if you inject Linkerd into your Nginx ingress
controller's pod, the default backend will not be usable.
{{< /note >}}

## Traefik

This uses `emojivoto` as an example, take a look at
[getting started](/2/getting-started/) for a refresher on how to install it.

The sample ingress definition is:

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

## GCE

This example is similar to Traefik, and also uses `emojivoto` as an example.
Take a look at [getting started](/2/getting-started/) for a refresher on how to
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

## Ambassador

This uses `emojivoto` as an example, take a look at
[getting started](/2/getting-started/) for a refresher on how to install it.

Ambassador does not use `Ingress` resources, instead relying on `Service`. The
sample service definition is:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-ambassador
  namespace: emojivoto
  annotations:
    getambassador.io/config: |
      ---
      apiVersion: ambassador/v1
      kind: Mapping
      name: web-ambassador-mapping
      service: http://web-svc.emojivoto.svc.cluster.local:80
      host: example.com
      prefix: /
      add_linkerd_headers: true
spec:
  selector:
    app: web-svc
  ports:
  - name: http
    port: 80
    targetPort: http
```

The important annotation here is:

```yaml
      add_linkerd_headers: true
```

Ambassador will add a `l5d-dst-override` header to instruct Linkerd what service
the request is destined for. This will contain both the Kubernetes service
FQDN (`web-svc.emojivoto.svc.cluster.local`) *and* the destination
`servicePort`.

{{< note >}}
To make this global, add `add_linkerd_headers` to your `Module` configuration.
{{< /note >}}

To test this, you'll want to get the external IP address for your controller. If
you installed Ambassador via helm, you can get that IP address by running:

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

## Gloo

This uses `books` as an example, take a look at
[Demo: Books](/2/tasks/books/) for instructions on how to run it.

If you installed Gloo using the Gateway method (`gloo install gateway`), then
you'll need a VirtualService to be able to route traffic to your **Books**
application.

To use Gloo with Linkerd, you can choose one of two options.

### Automatic

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

### Manual

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

### Test

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
