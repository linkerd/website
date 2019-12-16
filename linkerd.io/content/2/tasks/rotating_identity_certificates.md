+++
title = "Rotating your identity certificates"
description = "Follow this work flow to update your identity certificates"
+++

By default, the issuer certificate and trust root that Linkerd uses are valid
for 365 days. If either of these certificates expires, Linkerd will no longer
be able to proxy traffic. Therefore, it is critical that you replace these
certificates with new ones before they expire - a process called certificate
rotation.

If your control plane is installed with the
`linkerd install --identity-external-issuer` command where your trust root is
managed by a 3rd party certificate management solution like `cert-manager`,
then this information doesn't apply to you, because it is the responsibility
of your certificate manager to rotate the certificates before they expire.

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
linkerd-identity
----------------
√ certificate config is valid
√ trust roots are using supported crypto algorithm
√ trust roots are within their validity period
√ trust roots are valid for at least 60 days
√ issuer cert is using supported crypto algorithm
√ issuer cert is within its validity period
√ issuer cert is valid for at least 60 days
√ issuer cert is issued by the trust root

linkerd-identity-data-plane
---------------------------
√ data plane proxies certificate match CA
```

## Generate new trust root and issuer certificates

If you have installed Linkerd with a manually supplied trust root that is not
expiring and you have its key, then you can simply use it to generate a new
issuer certificate. If this is the case, skip this step and go directly to
[Updating the identity issuer certificate](/2/tasks/rotating_identity_certificates/#updating-the-identity-issuer-certificate)

First generate the root certificate with its private key. The private key needs
to be stored in a secured vault so it can be used to generate a new trust root
in the future.

```bash
step certificate create identity.linkerd.cluster.local ca-new.crt ca-new.key --profile root-ca --no-password --insecure
```

{{< note >}}
Note we use `--no-password --insecure` for both the roots and issuer
certificates to avoid encrypting those files with a passphrase.
{{< /note >}}

## Bundling your original trust root with the new one

As a next step we need to bundle the trust root currently used by Linkerd
together with the new root and configure Linkerd to use the bundle. The
following command uses `kubectl` to fetch the Linkerd config as a `json`
object, extracts the current roots from the config with the help of  `jq` and
finally uses `step` to combine it with the newly generated roots and save the
result in the `bundle.crt` file.

```bash
kubectl -n linkerd get cm linkerd-config -o=jsonpath='{.data.global}' |  \
jq -r .identityContext.trustAnchorsPem > original-trust.crt &&
step certificate bundle ca-new.crt original-trust.crt bundle.crt &&
rm original-trust.crt
```

## Deploying the new bundle to Linkerd

You can use `linkerd upgrade` in order to upgrade Linkerd to work with the new
root bundle:

```bash
linkerd upgrade  --identity-trust-anchors-file=./bundle.crt | kubectl apply -f -
````

This will restart the proxies of the Linkerd components and they will be
reconfigured with the new root certs. Now it is time restart the proxy for all
injected workloads in your cluster. Doing that for the `emojivoto` namespace for
example would look like:

```bash
kubectl -n emojivoto rollout restart deploy
```

Now you can run the `check` command to ensure that everything is ok:

```bash
linkerd check --proxy
```

You might have to wait a few moments until all the pods have been restarted and
are configured with the correct roots. Meanwhile you might observe warnings:

```bash
linkerd-identity-data-plane
---------------------------
‼ data plane proxies certificate match CA
    Some pods do not have the current trust bundle and must be restarted:
        * emojivoto/emoji-d8d7d9c6b-8qwfx
        * emojivoto/vote-bot-588499c9f6-zpwz6
        * emojivoto/voting-8599548fdc-6v64k
        * emojivoto/web-67c7599f6d-xx98n
        * linkerd/linkerd-sp-validator-75f9d96dc-rch4x
        * linkerd/linkerd-tap-68d8bbf64-mpzgb
        * linkerd/linkerd-web-849f74b7c6-qlhwc
    see https://linkerd.io/checks/#l5d-data-plane-proxies-certificate-match-ca for hints
```

When the rollout completes your `check` command should stop outputting warning:

```bash
linkerd-identity
----------------
√ certificate config is valid
√ trust roots are using supported crypto algorithm
√ trust roots are within their validity period
√ trust roots are valid for at least 60 days
√ issuer cert is using supported crypto algorithm
√ issuer cert is within its validity period
√ issuer cert is valid for at least 60 days
√ issuer cert is issued by the trust root

linkerd-identity-data-plane
---------------------------
√ data plane proxies certificate match CA
```

## Updating the identity issuer certificate

Now, using your trust root, generate the intermediate certificate and key pair:

```bash
step certificate create identity.linkerd.cluster.local issuer-new.crt issuer-new.key --ca ca-new.crt --ca-key ca-new.key --profile intermediate-ca --not-after 8760h --no-password --insecure
```

Provided that all proxies are updated to include a working trust root, it is
safe to rotate the identity issuer certificate by using the `upgrade` command
again:

```bash
linkerd upgrade  --identity-issuer-certificate-file=./issuer-new.crt --identity-issuer-key-file=./issuer-new.key | kubectl apply -f -
```

At this point the `identity` service should detect the change of the secret and
automatically update its issuer certificates. To ensure this has happened, you
can check for the specific Kubernetes event.

```bash
kubectl get events --field-selector reason=IssuerUpdated -n linkerd

LAST SEEN   TYPE     REASON          OBJECT                        MESSAGE
9s          Normal   IssuerUpdated   deployment/linkerd-identity   Updated identity issuer
```

Run the `check` command to make sure that everything is going as expected:

```bash
linkerd check --proxy
```

You should see output without any certificate expiration warnings:

```bash
linkerd-identity
----------------
√ certificate config is valid
√ trust roots are using supported crypto algorithm
√ trust roots are within their validity period
√ trust roots are valid for at least 60 days
√ issuer cert is using supported crypto algorithm
√ issuer cert is within its validity period
√ issuer cert is valid for at least 60 days
√ issuer cert is issued by the trust root

linkerd-identity-data-plane
---------------------------
√ data plane proxies certificate match CA
```

## Removing the old trust root

At this point the cert rotation process is complete. However as you do not need
the old roots, you can simply get rid of them. The `upgrade` command can do
that for the Linkerd components:

```bash
linkerd upgrade  --identity-trust-anchors-file=./ca-new.crt  | kubectl apply -f -
```

Additionally you can use the `rollout restart` command to bring the configuration
of your other injected resources up to date:

```bash
kubectl -n emojivoto rollout restart deploy
linkerd check --proxy
```

Finally the output of the `check` command should not produce any warnings or
errors:

```bash
linkerd-identity
----------------
√ certificate config is valid
√ trust roots are using supported crypto algorithm
√ trust roots are within their validity period
√ trust roots are valid for at least 60 days
√ issuer cert is using supported crypto algorithm
√ issuer cert is within its validity period
√ issuer cert is valid for at least 60 days
√ issuer cert is issued by the trust root

linkerd-identity-data-plane
---------------------------
√ data plane proxies certificate match CA
```
