+++
title = "Rotating the identity trust root"
description = "Follow this work flow to update your identity trust root"
+++

As already detailed in the
[Automatic mTLS](/2/features/automatic-mtls/#how-does-it-work) section, Linkerd
stores the trust root certificate in its config map. Proxies validate the
connection to `identity` by using the trust root, which is part of the proxy
container’s specification as an environment variable. The value of this
variable is fetched from the `linkerd-config` config map and set upon injection.

Starting from stable-2.7 the `identity` service is capable of dynamically
updating its issuer certificate whenever the contents of
`linkerd-identity-issuer` secret are modified. This allows for much easier
management of issuer certificates and integration with external certificate
management solutions such as [Cert Manager](/2/tasks/use_external_certs/).
All of this works with the assumption that the trust root stays the same.
It is possible however that at some point you need to rotate the trust root
without causing any downtime in your cluster. This is a more involved and manual
operation. In the following lines we outline the steps that you might take to
perform it. It is important for the steps to happen in this particular order.

## Prerequisites

You need to have a working Linkerd installation. You can follow the
[Getting Started](/2/getting-started/)
guide to setup Linkerd. Whether you have provided your own
certificates during installation or you are using the automatically generated
ones does not make any difference to the process outlined bellow.

## Generate new trust root and issuer certificates

First generate the root certificate with its private key:

```bash
step certificate create identity.linkerd.cluster.local ca-new.crt ca-new.key --profile root-ca --no-password --insecure
```

Then generate the intermediate certificate and key pair:

```bash
step certificate create identity.linkerd.cluster.local issuer-new.crt issuer-new.key --ca ca-new.crt --ca-key ca-new.key --profile intermediate-ca --not-after 8760h --no-password --insecure
```

## Updating the `linkerd-config` configmap to contain both trust roots

Now that you have a new trust root you need to add it to the bundle in the
Linkerd config. This will allow the proxies, when re-injected to be configured
with both roots at the same time. In order to do that, first encode your trust
root as a single line:

```bash
awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}'  ca-new.crt
```

Now you can use `kubectl edit` to modify the config map in place:

```bash
kubectl edit configmap linkerd-config -n linkerd
```

This will open an editor. You need to append the formatted trust root data to
the old trust root defined in the `trustAnchorsPem` field, changing it to be in
the form:

```json
"trustAnchorsPem":"<old-trust-root><new-trust-root>"
```

## Reinjecting the proxies with the new trust anchors

Now its time to re-inject the proxies so their
`LINKERD2_PROXY_IDENTITY_TRUST_ANCHORS` contains both roots. You can do that
for the Linkerd components by using the inject command

```bash
kubectl -n linkerd get deploy -o yaml | linkerd inject  --manual - | kubectl apply -f -
```

You need to do that for all injected resources. Now you can fetch the configuration
and the injected Linkerd deployments to perform some manual checks.

```bash
kubectl get configmap linkerd-config -o yaml -n linkerd
kubectl -n linkerd get deploy -o yaml
```

Make sure that the `LINKERD2_PROXY_IDENTITY_TRUST_ANCHORS` of all deployments
match the ones defined in the config map.

## Updating the identity issuer certificate

Now that all proxies are updated to include the additional trust root, it is
safe to rotate the identity issuer certificate. Open an editor that allows you
to modify the secret.

```bash
kubectl edit secret linkerd-identity-issuer -n linkerd
```

Replace the `crt.pem` and `key.pem` with the base64 encoded values from
`issuer-new.crt` and `issuer-new.key` respectively. At this point the
`identity` service should detect the change of the secret and automatically
update its issuer certificates. To ensure this has happened, you can check for
the specific Kubernetes event.

```bash
kubectl get events --field-selector reason=IssuerUpdated -n linkerd

LAST SEEN   TYPE     REASON          OBJECT                        MESSAGE
9s          Normal   IssuerUpdated   deployment/linkerd-identity   Updated identity issuer
```

{{< note >}}
In case you have installed Linkerd with `--identity-external-issuer` flag,
your secret format should be different. The keys that it contains are `ca.crt`,
where the new roots need to be, `tls.crt`, where the issuer certificate is
and `tls.key` where the issuer certificate key should be placed.
{{< /note >}}

## Removing the old trust root

Use `kubectl edit configmap linkerd-config -n linkerd` and remove the first
certificate from `trustAnchorsPem`, bringing it to the following form:

```json
"trustAnchorsPem":"<new-trust-root>"
```

It is safe to reconfigure the proxies to include only the new trust roots. You
can do that by re-injecting the proxies:

```bash
kubectl -n linkerd get deploy -o yaml | linkerd inject  --manual - | kubectl apply -f -
```
