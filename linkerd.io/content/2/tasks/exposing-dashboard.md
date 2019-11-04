+++
title = "Exposing the Dashboard"
description = "Make it easy for others to access Linkerd and Grafana dashboards without the CLI."
+++

Instead of using `linkerd dashboard` every time you'd like to see what's going
on, you can expose the dashboard via an ingress. This will also expose Grafana.

{{% pagetoc %}}

## Nginx

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
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/configuration-snippet: |
      proxy_set_header l5d-dst-override $service_name.$namespace.svc.cluster.local:8084;
      proxy_set_header Origin "";
      proxy_hide_header l5d-remote-ip;
      proxy_hide_header l5d-server-id;
    nginx.ingress.kubernetes.io/upstream-vhost: $service_name.$namespace.svc.cluster.local:8084
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: web-ingress-auth
    nginx.ingress.kubernetes.io/auth-realm: "Authentication Required"
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
    kubernetes.io/ingress.class: "traefik"
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
auth using admin/admin. Take a look at the [Traefik][traefik-auth]
documentation for details on how to change the username and password.

## DNS Rebinding Protection

To prevent [DNS-rebinding](https://en.wikipedia.org/wiki/DNS_rebinding) attacks,
the dashboard rejects any request whose `Host` header is not `localhost`,
`127.0.0.1` or the full service name `linkerd-web.linkerd.svc.cluster.local`. If
you rely on the latter, and if you used the `--cluster-domain` flag or the
equivalent `ClusterDomain` Helm value when you installed Linkerd, then replace
the `cluster.local` part with the appropriate value.

Note that this protection also covers the [Grafana
dashboard](/2/reference/architecture/#grafana).

The Nginx-Ingress config above uses the
`nginx.ingress.kubernetes.io/upstream-vhost` annotation to properly set the
upstream `Host` header. Traefik on the other hand doesn't offer that option, so
you'll have to manually set the required `Host` as explained below.

### Tweaking Host Requirement

If your HTTP client (Ingress or otherwise) doesn't allow to rewrite the `Host`
header, you can change the validation regexp that the dashboard server uses,
which is fed into the `linkerd-web` deployment via the `enforced-host` container
argument.

One way of doing that is through Kustomize, as explained in [Customizing
Installation](/2/tasks/customize-install/), using an overlay
like this one:

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

[nginx-auth]: https://github.com/kubernetes/ingress-nginx/blob/master/docs/examples/auth/basic/README.md
[traefik-auth]: https://docs.traefik.io/middlewares/basicauth/
