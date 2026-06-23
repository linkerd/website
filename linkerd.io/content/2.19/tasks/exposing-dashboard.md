---
title: Exposing the Dashboard
description:
  Make it easy for others to access Linkerd and Grafana dashboards without the
  CLI.
---

Instead of using `linkerd viz dashboard` every time you'd like to see what's
going on, you can expose the dashboard via an ingress. This will also expose
Grafana, if you have it linked against Linkerd viz through the `grafana.url`
setting.

{{< docs/toc >}}

## Nginx

### Nginx with basic auth

A sample ingress definition is:

```yaml
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: web-ingress-auth
  namespace: linkerd-viz
data:
  auth: YWRtaW46JGFwcjEkbjdDdTZnSGwkRTQ3b2dmN0NPOE5SWWpFakJPa1dNLgoK
---
# apiVersion: networking.k8s.io/v1beta1 # for k8s < v1.19
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress
  namespace: linkerd-viz
  annotations:
    nginx.ingress.kubernetes.io/upstream-vhost: $service_name.$namespace.svc.cluster.local:8084
    nginx.ingress.kubernetes.io/configuration-snippet: |
      proxy_set_header Origin "";
      proxy_hide_header l5d-remote-ip;
      proxy_hide_header l5d-server-id;
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: web-ingress-auth
    nginx.ingress.kubernetes.io/auth-realm: "Authentication Required"
spec:
  ingressClassName: nginx
  rules:
    - host: dashboard.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: web
                port:
                  number: 8084
```

This exposes the dashboard at `dashboard.example.com` and protects it with basic
auth using admin/admin. Take a look at the [ingress-nginx][nginx-auth]
documentation for details on how to change the username and password.

### Nginx with oauth2-proxy

A more secure alternative to basic auth is using an authentication proxy, such
as [oauth2-proxy](https://oauth2-proxy.github.io/oauth2-proxy/).

For reference on how to deploy and configure oauth2-proxy in kubernetes, see
this
[blog post by Don Bowman](https://blog.donbowman.ca/2019/02/14/using-single-sign-on-oauth2-across-many-sites-in-kubernetes/).

tl;dr: If you deploy oauth2-proxy via the
[helm chart](https://github.com/helm/charts/tree/master/stable/oauth2-proxy),
the following values are required:

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

Where the `oauth2-proxy` secret would contain the required
[oauth2 config](https://oauth2-proxy.github.io/oauth2-proxy/docs/configuration/oauth_provider)
such as, `client-id` `client-secret` and `cookie-secret`.

Once setup, a sample ingress would be:

```yaml
# apiVersion: networking.k8s.io/v1beta1 # for k8s < v1.19
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web
  namespace: linkerd-viz
  annotations:
    nginx.ingress.kubernetes.io/upstream-vhost: $service_name.$namespace.svc.cluster.local:8084
    nginx.ingress.kubernetes.io/configuration-snippet: |
      proxy_set_header Origin "";
      proxy_hide_header l5d-remote-ip;
      proxy_hide_header l5d-server-id;
    nginx.ingress.kubernetes.io/auth-signin: https://$host/oauth2/start?rd=$escaped_request_uri
    nginx.ingress.kubernetes.io/auth-url: https://$host/oauth2/auth
spec:
  ingressClassName: nginx
  rules:
    - host: linkerd.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: web
                port:
                  number: 8084
```

## Traefik

A sample ingress definition is:

```yaml
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: web-ingress-auth
  namespace: linkerd-viz
data:
  auth: YWRtaW46JGFwcjEkbjdDdTZnSGwkRTQ3b2dmN0NPOE5SWWpFakJPa1dNLgoK
---
# apiVersion: networking.k8s.io/v1beta1 # for k8s < v1.19
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress
  namespace: linkerd-viz
  annotations:
    ingress.kubernetes.io/custom-request-headers: l5d-dst-override:web.linkerd-viz.svc.cluster.local:8084
    traefik.ingress.kubernetes.io/auth-type: basic
    traefik.ingress.kubernetes.io/auth-secret: web-ingress-auth
spec:
  ingressClassName: traefik
  rules:
    - host: dashboard.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: web
                port:
                  number: 8084
```

This exposes the dashboard at `dashboard.example.com` and protects it with basic
auth using admin/admin. Take a look at the [Traefik][traefik-auth] documentation
for details on how to change the username and password.

## Ambassador

Ambassador works by defining a
[mapping](https://www.getambassador.io/docs/latest/topics/using/intro-mappings/)
as an annotation on a service.

The below annotation exposes the dashboard at `dashboard.example.com`.

```yaml
annotations:
  getambassador.io/config: |-
    ---
    apiVersion: getambassador.io/v2
    kind: Mapping
    name: web-mapping
    host: dashboard.example.com
    prefix: /
    host_rewrite: web.linkerd-viz.svc.cluster.local:8084
    service: web.linkerd-viz.svc.cluster.local:8084
```

## DNS Rebinding Protection

To prevent [DNS-rebinding](https://en.wikipedia.org/wiki/DNS_rebinding) attacks,
the dashboard rejects any request whose `Host` header is not `localhost`,
`127.0.0.1` or the service name `web.linkerd-viz.svc`.

Note that this protection also covers the
[Grafana dashboard](../reference/architecture/#grafana).

The ingress-nginx config above uses the
`nginx.ingress.kubernetes.io/upstream-vhost` annotation to properly set the
upstream `Host` header. Traefik on the other hand doesn't offer that option, so
you'll have to manually set the required `Host` as explained below.

### Tweaking Host Requirement

If your HTTP client (Ingress or otherwise) doesn't allow to rewrite the `Host`
header, you can change the validation regexp that the dashboard server uses,
which is fed into the `web` deployment via the `enforced-host` container
argument.

If you're managing Linkerd with Helm, then you can set the host using the
`enforcedHostRegexp` value.

Another way of doing that is through Kustomize, as explained in
[Customizing Installation](customize-install/), using an overlay like this one:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  template:
    spec:
      containers:
        - name: web
          args:
            - -linkerd-controller-api-addr=linkerd-controller-api.linkerd.svc.cluster.local:8085
            - -linkerd-metrics-api-addr=metrics-api.linkerd-viz.svc.cluster.local:8085
            - -cluster-domain=cluster.local
            - -grafana-addr=grafana.grafana
            - -controller-namespace=linkerd
            - -viz-namespace=linkerd-viz
            - -log-level=info
            - -enforced-host=^dashboard\.example\.com$
```

If you want to completely disable the `Host` header check, simply use a
catch-all regexp `.*` for `-enforced-host`.

[nginx-auth]:
  https://github.com/kubernetes/ingress-nginx/blob/master/docs/examples/auth/basic/README.md
[traefik-auth]: https://docs.traefik.io/middlewares/basicauth/
