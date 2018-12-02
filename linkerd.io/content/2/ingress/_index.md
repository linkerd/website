+++
date = "2018-11-19T12:00:00-07:00"
title = "Ingress"
[menu.l5d2docs]
  name = "Ingress"
  weight = 10
+++

While Linkerd does not handle ingress itself, it does work alongside your
ingress controller of choice.

If you're planning on injecting Linkerd into your controller's pods there is a
little bit of extra work required. Linkerd discovers services based on the
`Authority` or `Host` header. This allows Linkerd to understand what service a
request is destined for without being dependent on DNS or IPs.

When it comes to ingress, most controllers do not rewrite the
incoming header (`example.com`) to the internal service name
(`example.default.svc.cluster.local`). This means that when Linkerd receives the
outgoing request it doesn't know where that request is destined.

Luckily, many ingress controllers allow you to do the rewrite internally and
have Linkerd work the way you'd expect it to!

## Nginx

This uses `emojivoto` as an example, take a look at
[getting started](/2/getting-started) for a refresher on how to install it.

The sample ingress definition is:

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: web-ingress
  namespace: emojivoto
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/upstream-vhost: $service_name.$namespace.svc.cluster.local
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
nginx.ingress.kubernetes.io/upstream-vhost: $service_name.$namespace.svc.cluster.local
```

This will rewrite the `Host` header to be the fully qualified service name
inside your Kubernetes cluster.

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

Note: it is not possible to rewrite the header in this way for the default
backend. Because of this, if you inject Linkerd into your Nginx ingress
controller's pod, the default backend will not be usable.
