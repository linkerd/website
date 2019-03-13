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
    nginx.ingress.kubernetes.io/upstream-vhost: $service_name.$namespace.svc.cluster.local
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: web-ingress-auth
    nginx.ingress.kubernetes.io/auth-realm: "Authentication Required"
    nginx.ingress.kubernetes.io/configuration-snippet: |
      proxy_set_header Origin "";
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
    ingress.kubernetes.io/custom-request-headers:     l5d-dst-override:linkerd-web.linkerd.svc.cluster.local
    traefik.ingress.kubernetes.io/auth-type: "basic"
    traefik.ingress.kubernetes.io/auth-secret: "web-ingress-auth"
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

[nginx-auth]: https://github.com/kubernetes/ingress-nginx/blob/master/docs/examples/auth/basic/README.md
[traefik-auth]: https://docs.traefik.io/user-guide/kubernetes/#basic-authentication
