+++
date = "2018-07-31T12:00:00-07:00"
title = "Adding Your Service"
[menu.l5d2docs]
  name = "Adding Your Service"
  weight = 6
+++

In order for your service to take advantage of Linkerd, it needs to have
Linkerd's data plane proxies installed into the service pods.

There are two ways to do this:

1. Use `linkerd inject` ([reference](../cli/inject)) to update the YAML
   manifest for the service, and pass that output to `kubectl`.
2. Use [automatic proxy injection](../proxy-injection) to do this automatically
   on the cluster itself.

In both cases, the proxy sidecar will be added as a separate container in the
pod, along with an `initContainer` that configures iptables to pass all traffic
through the proxy. Thus, no configuration or modification of the application
itself is necessary.

# Method 1: `linkerd inject`

To add the Linkerd data plane proxies to a service, run:

```bash
linkerd inject deployment.yml \
  | kubectl apply -f -
```

Where `deployment.yml` is the Kubernetes config file containing your
application.

By applying this new manifest via `kubectl`, a rolling update of your
deployment will be triggered replacing each pod with a new one.  Thanks to
Kubernetes's rolling update logic, even if the service is currently running,
the availability of thee application will not be affected. When you add the
proxies to a service, the service will remain up as Kubernetes rolls the pods.

You will know that your service has been successfully added to the service mesh
if it's pods are reported to be meshed in the Meshed column of the Linkerd
dashboard.

{{< fig src="/images/getting-started/stat.png" title="Dashboard" >}}

You can always get to the Linkerd dashboard by running:

```bash
linkerd dashboard
```

# Method 2: Automatic Proxy Injection

**Note**: this feature is *experimental*. As of version {{% latestversion %}}, it
not recommended for production use.

**Note**: Currently, the auto-proxy injection only works with Deployments.
It doesn't work with other workload like StatefulSet, DaemonSet, Pod etc.

An alternative approach to adding the Linkerd data plane proxies to services is
to do it on the cluster, using a Kubernetes feature called [admission
webhooks](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/#admission-webhooks).
This essentially performs the work of `linkerd inject` on the server side,
rather than requiring a client-side pipeline during deploys.

Linkerd's automatic proxy injection works as follows:
* All required permissions are defined in the new
  `linkerd-linkerd-proxy-injector` cluster role, separated from the cluster
  role of the control plane.
* When a new deployment is created, the Linkerd proxy will be automatically injected if:
  * the namespace has the `linkerd.io/auto-inject: enabled` label or
  * the namespace isn't labeled with the `linkerd.io/auto-inject` label.
* Namespaces that are labeled with the `linkerd.io/auto-inject: disabled` are ignored.
* Within "enabled" namespaces, deployments with pods that are labeled with
  `linkerd.io/auto-inject: disabled` or `linkerd.io/auto-inject: completed` are
  ignored.

## Installation
To get started, verify that your Kubernetes version is 1.9 or higher, and that
kube-apiserver has the `admission-control` flag and the admissionregistration
API enabled.

```bash
kubectl api-versions | grep admissionregistration
admissionregistration.k8s.io/v1beta1
```

The proxy auto-injection feature is disabled by default. To enable it, you must
install Linkerd with the `--tls=optional` and `--proxy-auto-inject` flags.
```bash
$ linkerd install --tls=optional --proxy-auto-inject | kubectl apply -f -
```

You should also run `linkerd check` to make sure everything is ready.

If successful, you should see the new `proxy-injector` deployment as part of
the control plane:
```bash
$ kubectl -n linkerd get deploy
NAME             DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
ca               1         1         1            1           4m
controller       1         1         1            1           4m
grafana          1         1         1            1           4m
prometheus       1         1         1            1           4m
proxy-injector   1         1         1            1           4m
web              1         1         1            1           4m

$ kubectl -n linkerd get po
NAME                              READY     STATUS    RESTARTS   AGE
ca-54d574c7b5-gr4kw               2/2       Running   0          4m
controller-5858d6df74-d652q       5/5       Running   0          4m
grafana-757cdf976-wt88x           2/2       Running   0          4m
prometheus-6bc8f55ff8-qgjlc       2/2       Running   0          4m
proxy-injector-55dd8f7bd7-srnps   2/2       Running   1          4m
web-6584749d68-c6nnj              2/2       Running   0          4m
```

## Injection
### Namespace

Namespaces that are labeled `linkerd.io/auto-inject: disabled` are ignored.
```bash
$ kubectl create ns disabled
namespace "disabled" created

$ kubectl label ns disabled linkerd.io/auto-inject=disabled
namespace "disabled" labeled

$ kubectl -n disabled run nginx --image=nginx --port=80
deployment.apps "nginx" created

$ kubectl -n disabled get deploy
NAME      DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
nginx     1         1         1            1           6s

$ kubectl -n disabled get po
NAME                     READY     STATUS    RESTARTS   AGE
nginx-666865b5dd-zcgsc   1/1       Running   0          8s
```

The proxy sidecar container will be auto-injected into namespaces that are either **not** labeled with `linkerd.io/auto-inject` or labeled with `linkerd.io/auto-inject: enabled`.
```bash
$ kubectl create ns enabled
namespace "enabled" created

$ kubectl label ns enabled linkerd.io/auto-inject=enabled
namespace "enabled" labeled

$ kubectl -n enabled run nginx --image=nginx --port=80
deployment.apps "nginx" created

$ kubectl -n enabled get deploy
NAME      DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
nginx     1         1         1            0           6s

$ kubectl -n enabled get po
NAME                     READY     STATUS    RESTARTS   AGE
nginx-7fdb79d8db-n2qjs   2/2       Running   0          7s

$ kubectl -n enabled logs nginx-7fdb79d8db-n2qjs linkerd-proxy
INFO linkerd2_proxy using controller at Some(HostAndPort { host: DnsName(DnsName(DNSName("proxy-api.linkerd.svc.cluster.local"))), port: 8086 })
INFO linkerd2_proxy routing on V4(127.0.0.1:4140)
INFO linkerd2_proxy proxying on V4(0.0.0.0:4143) to None
INFO linkerd2_proxy serving Prometheus metrics on V4(0.0.0.0:4191)
INFO linkerd2_proxy protocol detection disabled for inbound ports {25, 3306}
INFO linkerd2_proxy protocol detection disabled for outbound ports {25, 3306}
INFO admin={bg=tls-config} linkerd2_proxy::transport::tls::config loaded TLS configuration.
INFO admin={bg=resolver} linkerd2_proxy::transport::connect DNS resolved DnsName(DnsName(DNSName("proxy-api.linkerd.svc.cluster.local"))) to 10.96.77.89
INFO admin={bg=tls-config} linkerd2_proxy::transport::tls::config loaded TLS configuration.
INFO admin={bg=tls-config} linkerd2_proxy::transport::tls::config loaded TLS configuration.
INFO admin={bg=resolver} linkerd2_proxy::transport::connect DNS resolved DnsName(DnsName(DNSName("proxy-api.linkerd.svc.cluster.local"))) to 10.96.77.89

$ kubectl create ns unlabeled
namespace "unlabeled" created

$ kubectl -n unlabeled run nginx --image=nginx --port=80
deployment.apps "nginx" created

$ kubectl -n unlabeled get deploy
NAME      DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
nginx     1         1         1            0           13s

$ kubectl -n unlabeled get po
NAME                     READY     STATUS    RESTARTS   AGE
nginx-74cc99c95c-jvhk8   2/2       Running   0          21s

$ kubectl -n unlabeled logs nginx-74cc99c95c-jvhk8 linkerd-proxy
INFO linkerd2_proxy using controller at Some(HostAndPort { host: DnsName(DnsName(DNSName("proxy-api.linkerd.svc.cluster.local"))), port: 8086 })
INFO linkerd2_proxy routing on V4(127.0.0.1:4140)
INFO linkerd2_proxy proxying on V4(0.0.0.0:4143) to None
INFO linkerd2_proxy serving Prometheus metrics on V4(0.0.0.0:4191)
INFO linkerd2_proxy protocol detection disabled for inbound ports {25, 3306}
INFO linkerd2_proxy protocol detection disabled for outbound ports {25, 3306}
INFO admin={bg=tls-config} linkerd2_proxy::transport::tls::config loaded TLS configuration.
INFO admin={bg=resolver} linkerd2_proxy::transport::connect DNS resolved DnsName(DnsName(DNSName("proxy-api.linkerd.svc.cluster.local"))) to 10.96.77.89
INFO admin={bg=tls-config} linkerd2_proxy::transport::tls::config loaded TLS configuration.
INFO admin={bg=tls-config} linkerd2_proxy::transport::tls::config loaded TLS configuration.
INFO admin={bg=resolver} linkerd2_proxy::transport::connect DNS resolved DnsName(DnsName(DNSName("proxy-api.linkerd.svc.cluster.local"))) to 10.96.77.89
INFO admin={bg=tls-config} linkerd2_proxy::transport::tls::config loaded TLS configuration.
INFO admin={bg=tls-config} linkerd2_proxy::transport::tls::config loaded TLS configuration.
INFO admin={bg=resolver} linkerd2_proxy::transport::connect DNS resolved DnsName(DnsName(DNSName("proxy-api.linkerd.svc.cluster.local"))) to 10.96.77.89
```

### Deployment
Deployments with pods that are labeled `linkerd.io/auto-inject: disabled` and `linkerd.io/auto-inject: completed` are ignored. Note that these are the pod template labels i.e. `spec.template.metadata.labels`, not the deployment's labels.

When the webhook receives a request to mutate a pod's specification, it also checks the pod's container specification to ensure no proxy sidecar has already been injected. If a pod already has the proxy sidecar container, it will be ignored.
```bash
$ kubectl -n unlabeled run nginx-disabled --image=nginx --port=80 --labels="linkerd.io/auto-inject=disabled"
deployment.apps "nginx-disabled" created

$ kubectl -n unlabeled run nginx-completed --image=nginx --port=80 --labels="linkerd.io/auto-inject=completed"
deployment.apps "nginx-completed" created

$ kubectl -n unlabeled get deploy
NAME              DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
nginx-completed   1         1         1            1           2m
nginx-disabled    1         1         1            1           3m

$ kubectl -n unlabeled get po -L linkerd.io/auto-inject
NAME                               READY     STATUS    RESTARTS   AGE       AUTO-INJECT
nginx-completed-6cb5f6f6cf-fq5lk   1/1       Running   0          56s       completed
nginx-disabled-776768bbc9-z8dcf    1/1       Running   0          1m        disabled
```

Deployments with pods that are labeled `linkerd.io/auto-inject: enabled` or unlabeled will be auto-injected with the proxy init and sidecar containers.
```bash
$ kubectl -n unlabeled run nginx-enabled --image=nginx --port=80 --labels="linkerd.io/auto-inject=enabled"
deployment.apps "nginx-enabled" created

$ kubectl -n unlabeled run nginx-unlabeled --image=nginx --port=80
deployment.apps "nginx-unlabeled" created

$ kubectl -n unlabeled get deploy
NAME               DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
nginx-enabled      1         1         1            1           15s
nginx-unlabeled    1         1         1            0           11s

$ kubectl -n unlabeled get po -L linkerd.io/auto-inject
NAME                               READY     STATUS    RESTARTS   AGE       AUTO-INJECT
nginx-completed-6cb5f6f6cf-fq5lk   1/1       Running   0          1m        completed
nginx-disabled-776768bbc9-z8dcf    1/1       Running   0          2m        disabled
nginx-enabled-6658556d5c-ljchj     2/2       Running   0          2m        enabled
nginx-unlabeled-79f6ccb579-sss8k   2/2       Running   0          1m
```

## Validation
The TLS secrets of the _enabled_ and _unlabeled_ deployments are created.
```bash
$ kubectl -n unlabeled get secret
NAME                                         TYPE                                  DATA      AGE
default-token-w75rf                          kubernetes.io/service-account-token   3         45m
nginx-enabled-deployment-tls-linkerd-io      Opaque                                2         2m
nginx-unlabeled-deployment-tls-linkerd-io    Opaque                                2         1m
```

Check the proxy's logs of the newly created _enabled_ and _unlabeled_ pods.
```bash
$ kubectl -n unlabeled logs nginx-enabled-6658556d5c-ljchj linkerd-proxy
INFO linkerd2_proxy using controller at Some(HostAndPort { host: DnsName(DnsName(DNSName("proxy-api.linkerd.svc.cluster.local"))), port: 8086 })
INFO linkerd2_proxy routing on V4(127.0.0.1:4140)
INFO linkerd2_proxy proxying on V4(0.0.0.0:4143) to None
INFO linkerd2_proxy serving Prometheus metrics on V4(0.0.0.0:4191)
INFO linkerd2_proxy protocol detection disabled for inbound ports {25, 3306}
INFO linkerd2_proxy protocol detection disabled for outbound ports {25, 3306}
INFO admin={bg=tls-config} linkerd2_proxy::transport::tls::config loaded TLS configuration.
INFO admin={bg=resolver} linkerd2_proxy::transport::connect DNS resolved DnsName(DnsName(DNSName("proxy-api.linkerd.svc.cluster.local"))) to 10.99.83.97
INFO admin={bg=tls-config} linkerd2_proxy::transport::tls::config loaded TLS configuration.
INFO admin={bg=tls-config} linkerd2_proxy::transport::tls::config loaded TLS configuration.
INFO admin={bg=resolver} linkerd2_proxy::transport::connect DNS resolved DnsName(DnsName(DNSName("proxy-api.linkerd.svc.cluster.local"))) to 10.99.83.97
INFO admin={bg=tls-config} linkerd2_proxy::transport::tls::config loaded TLS configuration.
INFO admin={bg=tls-config} linkerd2_proxy::transport::tls::config loaded TLS configuration.
INFO admin={bg=resolver} linkerd2_proxy::transport::connect DNS resolved DnsName(DnsName(DNSName("proxy-api.linkerd.svc.cluster.local"))) to 10.99.83.97

$ kubectl -n unlabeled logs nginx-unlabeled-79f6ccb579-sss8k linkerd-proxy
INFO linkerd2_proxy using controller at Some(HostAndPort { host: DnsName(DnsName(DNSName("proxy-api.linkerd.svc.cluster.local"))), port: 8086 })
INFO linkerd2_proxy routing on V4(127.0.0.1:4140)
INFO linkerd2_proxy proxying on V4(0.0.0.0:4143) to None
INFO linkerd2_proxy serving Prometheus metrics on V4(0.0.0.0:4191)
INFO linkerd2_proxy protocol detection disabled for inbound ports {25, 3306}
INFO linkerd2_proxy protocol detection disabled for outbound ports {25, 3306}
INFO admin={bg=tls-config} linkerd2_proxy::transport::tls::config loaded TLS configuration.
INFO admin={bg=resolver} linkerd2_proxy::transport::connect DNS resolved DnsName(DnsName(DNSName("proxy-api.linkerd.svc.cluster.local"))) to 10.99.83.97
INFO admin={bg=tls-config} linkerd2_proxy::transport::tls::config loaded TLS configuration.
INFO admin={bg=tls-config} linkerd2_proxy::transport::tls::config loaded TLS configuration.
INFO admin={bg=resolver} linkerd2_proxy::transport::connect DNS resolved DnsName(DnsName(DNSName("proxy-api.linkerd.svc.cluster.local"))) to 10.99.83.97
INFO admin={bg=tls-config} linkerd2_proxy::transport::tls::config loaded TLS configuration.
INFO admin={bg=tls-config} linkerd2_proxy::transport::tls::config loaded TLS configuration.
INFO admin={bg=resolver} linkerd2_proxy::transport::connect DNS resolved DnsName(DnsName(DNSName("proxy-api.linkerd.svc.cluster.local"))) to 10.99.83.97
INFO admin={bg=tls-config} linkerd2_proxy::transport::tls::config loaded TLS configuration.
INFO admin={bg=tls-config} linkerd2_proxy::transport::tls::config loaded TLS configuration.
INFO admin={bg=resolver} linkerd2_proxy::transport::connect DNS resolved DnsName(DnsName(DNSName("proxy-api.linkerd.svc.cluster.local"))) to 10.99.83.97
```

Take a look at the stats and try generating some simple traffic.
```bash
$ linkerd stat deployments -n unlabeled
NAME               MESHED   SUCCESS   RPS   LATENCY_P50   LATENCY_P95   LATENCY_P99   TLS
nginx-completed      0/1         -     -             -             -             -     -
nginx-disabled       0/1         -     -             -             -             -     -
nginx-enabled        1/1   100.00%   0.1rps           0ms           0ms           0ms    0%
nginx-unlabeled      1/1   100.00%   0.0rps           1ms           1ms           1ms    0%
```

Further testing...
Delete the _enabled_ pod. The new pod should still have the proxy sidecar.
```bash
$ kubectl -n unlabeled delete po nginx-enabled-6658556d5c-ljchj
pod "nginx-enabled-6658556d5c-ljchj" deleted

$ kubectl -n unlabeled get po
NAME                               READY     STATUS        RESTARTS   AGE
nginx-completed-6cb5f6f6cf-fq5lk   1/1       Running       0          10m
nginx-disabled-776768bbc9-z8dcf    1/1       Running       0          10m
nginx-enabled-6658556d5c-8v6c4     2/2       Running       0          28s
nginx-enabled-6658556d5c-ljchj     0/2       Terminating   0          10m
nginx-unlabeled-79f6ccb579-sss8k   2/2       Running       0          10m
```

Set the image of the _enabled_ deployment to a different version.
```bash
$ kubectl -n unlabeled set image deployment nginx-enabled nginx-enabled=nginx:1.9.1
deployment.apps "nginx" image updated

$ kubectl -n unlabeled describe deploy nginx-enabled
...
   nginx-enabled:
    Image:        nginx:1.9.1
    Port:         80/TCP
    Host Port:    0/TCP
    Environment:  <none>
    Mounts:       <none>

$ kubectl -n unlabeled get po
NAME                               READY     STATUS    RESTARTS   AGE
...
nginx-enabled-65f8d5c4fb-kh5rr     2/2       Running   0          1m
```
The new pod should still have the proxy sidecar.

## Debugging automatic proxy injection.

If the proxy sidecar isn't automatically injected, take a look at the
proxy-injector logs. If the proxy-injector emits a series of `remote error:
tls: bad certificate` errors, then the CA bundle defind in the webhook's
mutating webhook configuration has gone out-of-sync with the CA certificate
generated by the CA controller. The easiest resolution is to delete the
proxy-injector pod and let it recreate its mutating webhook configuration.

Additionally, the proxy-injector container take the `-log-level` argument which
can be set to generate more verbose logs output.

