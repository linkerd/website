+++
title = "Rotating the identity trust root"
description = "Follow this work flow to update your identity trust root"
+++

By default, the trust root that Linkerd uses to issue TLS certificates to the
Linkerd proxies has a default validity period of 365 days. This certificate is
stored in the `linkerd-config` config map. If your Linkerd control plane was
installed using either the `linkerd install`, `linkerd install --ha` or `helm
install` command, this documentation provides information to help you to rotate
the trust root certificate before it expires.

If your control plane is installed with the `linkerd install
--identity-external-issuer` command where your trust root is managed by a 3rd
party certificate management solution like `cert-manager`, then this information
doesn't apply to you.

{{< note >}}
Although Linkerd can auto-generate the trust root during installation, we
recommend using your own trust root for all serious workloads, so that you
have full control over it. See [Generating your own mTLS root certificates](/2/tasks/generate-certificates/#generating-the-certificates-with-step)
on how to do this.
{{< /note >}}

## Prerequisites

We are going to use `step` (0.13.3) and `jq` (1.6). We will also make use of the
`linkerd check` CLI utility which will give us extra assurance that the state of
our mTLS configuration is valid at any point. To begin with, you can run:

```bash
linkerd check --proxy
```

You should see output similar to:

```bash
...

linkerd-mtls
------------
√ certificate config is valid
√ control plane is using supported trust roots
√ identity is using supported issuer certificate
√ all control plane trust roots have valid lifetimes
√ issuer cert has valid lifetime

linkerd-data-plane-mtls
-----------------------
√ data plane is using supported trust roots
√ all data plane trust roots have valid lifetimes
√ control plane issuer certificate can be verified with data plane trust roots

...
```

Running this command at the end of each step and ensuring that all checks pass
should give you sufficient guarantee that your progressing in the right
direction.

{{< note >}}
There is likelihood that this process may incur downtime. Therefore it is
advisable to plan for that happening.
{{< /note >}}

## Generate new trust root and issuer certificates

First generate the root certificate with its private key. The private key needs
to be stored in a secured vault so it can be used to generate a new trust root
in the future.

```bash
step certificate create identity.linkerd.cluster.local ca-new.crt ca-new.key --profile root-ca --no-password --insecure
```

Note that the above command will generate a root certificate. Alternately, you
can use your existing trust root to generate an intermediate certificate for
Linkerd to use as its mTLS trust root. Now generate the intermediate
certificate and key pair:

```bash
step certificate create identity.linkerd.cluster.local issuer-new.crt issuer-new.key --ca ca-new.crt --ca-key ca-new.key --profile intermediate-ca --not-after 8760h --no-password --insecure
```

## Updating the `linkerd-config` configmap to contain both trust roots

As a next step we need to bundle the trust root currently used by Linkerd
together with the new root and configure Linkerd to use the new bundle:

```bash
kubectl -n linkerd get cm linkerd-config -o=jsonpath='{.data.global}' |  \
jq -r .identityContext.trustAnchorsPem > original-trust.crt &&
step certificate bundle ca-new.crt original-trust.crt bundle.crt &&
rm original-trust.crt
```

## Deploying the new bundle to Linkerd

You can resort to using `linkerd upgrade` in order to upgrade Linkerd to work
with the new root bundle:

```bash
bin/linkerd upgrade  --identity-trust-anchors-file=./bundle.crt | kubectl apply -f -
````

This will rotate the proxies of the Linkerd components and they will be
reconfigured with the new root certs. Now it is time rotate the proxy for all
injected workloads in your cluster. Doing that for the `emojivoto` namespace for
example would look like:

```bash
kubectl -n emojivoto get deploy -o yaml | linkerd inject  --manual - | kubectl apply -f -
```

## Updating the identity issuer certificate

Now that all proxies are updated to include the additional trust root, it is
safe to rotate the identity issuer certificate by using the `upgrade` command
again:

```bash
bin/linkerd upgrade   --identity-issuer-certificate-file=./issuer-new.crt --identity-issuer-key-file=./issuer-new.key | kubectl apply -f -
```

At this point the `identity` service should detect the change of the secret and
automatically update its issuer certificates. To ensure this has happened, you
can check for the specific Kubernetes event.

```bash
kubectl get events --field-selector reason=IssuerUpdated -n linkerd

LAST SEEN   TYPE     REASON          OBJECT                        MESSAGE
9s          Normal   IssuerUpdated   deployment/linkerd-identity   Updated identity issuer
```

## Removing the old trust root

At this point, it is safe to remove the old bundle and rotate the proxies once
again. Using the `upgrade` command can do that for the Linkerd components:

```bash
bin/linkerd upgrade  --identity-trust-anchors-file=./ca-new.crt  | kubectl apply -f -
```

Additionally you can use the `inject` command to bring the configuration
of your other injected resources up to date:

```bash
kubectl -n emojivoto get deploy -o yaml | linkerd inject  --manual - | kubectl apply -f -
```
