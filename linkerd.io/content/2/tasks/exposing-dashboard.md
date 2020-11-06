+++
title = "Exposing the Dashboard"
description = "Make it easy for others to access Linkerd and Grafana dashboards without the CLI."
+++

Instead of using `linkerd dashboard` every time you'd like to see what's going
on, you can expose the dashboard via an ingress. This will also expose Grafana.

{{< pagetoc >}}

## Nginx

### Nginx with basic auth

A sample ingress definition is:

```yaml
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: web-ingress-auth
  namespace: linkerd
data:
  auth: YWRtaW46JGFwcjEkbjdDdTZnSGwkRTQ3b2dmN0NPOE5SWWpFakJPa1dNLgoK
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: web-ingress
  namespace: linkerd
  annotations:
    kubernetes.io/ingress.class: 'nginx'
    nginx.ingress.kubernetes.io/upstream-vhost: $service_name.$namespace.svc.cluster.local:8084
    nginx.ingress.kubernetes.io/configuration-snippet: |
      proxy_set_header Origin "";
      proxy_hide_header l5d-remote-ip;
      proxy_hide_header l5d-server-id;
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: web-ingress-auth
    nginx.ingress.kubernetes.io/auth-realm: 'Authentication Required'
spec:
  rules:
    - host: dashboard.example.com
      http:
        paths:
          - backend:
              serviceName: linkerd-web
              servicePort: 8084
```

This exposes the dashboard at `dashboard.example.com` and protects it with basic
auth using admin/admin. Take a look at the [ingress-nginx][nginx-auth]
documentation for details on how to change the username and password.

### Nginx with oauth2-proxy

A more secure alternative to basic auth is using an authentication proxy, such
as [oauth2-proxy](https://oauth2-proxy.github.io/oauth2-proxy/).

For reference on how to deploy and configure oauth2-proxy in kubernetes, see
this [blog post by Don
Bowman](https://blog.donbowman.ca/2019/02/14/using-single-sign-on-oauth2-across-many-sites-in-kubernetes/).

tl;dr: If you deploy oauth2-proxy via the [helm
chart](https://github.com/helm/charts/tree/master/stable/oauth2-proxy), the
following values are required:

```yaml
config:
  existingSecret: oauth2-proxy
  configFile: |-
    email_domains = [ "example.com" ]
    upstreams = [ "file:///dev/null" ]

ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: nginx
  path: /oauth2
ingress:
  hosts:
    - linkerd.example.com
```

Where the `oauth2-proxy` secret would contain the required [oauth2
config](https://oauth2-proxy.github.io/oauth2-proxy/docs/configuration/oauth_provider)
such as, `client-id` `client-secret` and `cookie-secret`.

Once setup, a sample ingress would be:

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: linkerd-web
  namespace: linkerd
  annotations:
    kubernetes.io/ingress.class: 'nginx'
    nginx.ingress.kubernetes.io/upstream-vhost: $service_name.$namespace.svc.cluster.local:8084
    nginx.ingress.kubernetes.io/configuration-snippet: |
      proxy_set_header Origin "";
      proxy_hide_header l5d-remote-ip;
      proxy_hide_header l5d-server-id;
    nginx.ingress.kubernetes.io/auth-signin: https://$host/oauth2/start?rd=$escaped_request_uri
    nginx.ingress.kubernetes.io/auth-url: https://$host/oauth2/auth
spec:
  rules:
    - host: linkerd.example.com
      http:
        paths:
          - backend:
              serviceName: linkerd-web
              servicePort: 8084
```

## Traefik

A sample ingress definition is:

```yaml
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: web-ingress-auth
  namespace: linkerd
data:
  auth: YWRtaW46JGFwcjEkbjdDdTZnSGwkRTQ3b2dmN0NPOE5SWWpFakJPa1dNLgoK
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: web-ingress
  namespace: linkerd
  annotations:
    kubernetes.io/ingress.class: 'traefik'
    ingress.kubernetes.io/custom-request-headers: l5d-dst-override:linkerd-web.linkerd.svc.cluster.local:8084
    traefik.ingress.kubernetes.io/auth-type: basic
    traefik.ingress.kubernetes.io/auth-secret: web-ingress-auth
spec:
  rules:
    - host: dashboard.example.com
      http:
        paths:
          - backend:
              serviceName: linkerd-web
              servicePort: 8084
```

This exposes the dashboard at `dashboard.example.com` and protects it with basic
auth using admin/admin. Take a look at the [Traefik][traefik-auth] documentation
for details on how to change the username and password.

## Ambassador

Ambassador works by defining a [mapping
](https://www.getambassador.io/docs/latest/topics/using/intro-mappings/) as an
annotation on a service.

The below annotation exposes the dashboard at `dashboard.example.com`.

```yaml
  annotations:
    getambassador.io/config: |-
      ---
      apiVersion: ambassador/v1
      kind: Mapping
      name: linkerd-web-mapping
      host: dashboard.example.com
      prefix: /
      host_rewrite: linkerd-web.linkerd.svc.cluster.local:8084
      service: linkerd-web.linkerd.svc.cluster.local:8084
```

## DNS Rebinding Protection

To prevent [DNS-rebinding](https://en.wikipedia.org/wiki/DNS_rebinding) attacks,
the dashboard rejects any request whose `Host` header is not `localhost`,
`127.0.0.1` or the service name `linkerd-web.linkerd.svc`.

Note that this protection also covers the [Grafana
dashboard](/2/reference/architecture/#grafana).

The ingress-nginx config above uses the
`nginx.ingress.kubernetes.io/upstream-vhost` annotation to properly set the
upstream `Host` header. Traefik on the other hand doesn't offer that option, so
you'll have to manually set the required `Host` as explained below.

### Tweaking Host Requirement

If your HTTP client (Ingress or otherwise) doesn't allow to rewrite the `Host`
header, you can change the validation regexp that the dashboard server uses,
which is fed into the `linkerd-web` deployment via the `enforced-host` container
argument.

If you're managing Linkerd with Helm, then you can set the host using the
`enforcedHostRegexp` value.

Another way of doing that is through Kustomize, as explained in [Customizing
Installation](/2/tasks/customize-install/), using an overlay like this one:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: linkerd-web
spec:
  template:
    spec:
      containers:
        - name: web
          args:
            - -api-addr=linkerd-controller-api.linkerd.svc.cluster.local:8085
            - -grafana-addr=linkerd-grafana.linkerd.svc.cluster.local:3000
            - -controller-namespace=linkerd
            - -log-level=info
            - -enforced-host=^dashboard\.example\.com$
```

If you want to completely disable the `Host` header check, use an empty string
for `-enforced-host`.

[nginx-auth]:
https://github.com/kubernetes/ingress-nginx/blob/master/docs/examples/auth/basic/README.md
[traefik-auth]: https://docs.traefik.io/middlewares/basicauth/
