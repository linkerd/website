+++
title = "Manually Rotating Control Plane TLS Credentials"
description = "You can manually update Linkerd's control plane TLS credentials"
aliases = [ "rotating_identity_certificates" ]
+++

For simplicity, by default, Linkerd's control plane TLS credentials are
generated once at install time and are not rotated. Furthermore, these
credentials are valid for only 365 days, and if they expire, Linkerd will no
longer be able to proxy traffic.

Thus, for long-term operation, you must either:

1. Set up [automatic credential
rotation](/2/tasks/automatically-rotating-control-plane-tls-credentials/); or
2. Periodically manually rotate these credentials (this doc).

## Prerequisites

These instructions use the [step](https://smallstep.com/cli/) and
[jq](https://stedolan.github.io/jq/) CLI tools.

## Understanding the current state of your system

Begin by running:

```bash
linkerd check --proxy
```

If your configuration is valid and your credentials are not expiring soon, you
should see output similar to:

```text
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

However, if you see a message warning you that your trust anchor ("trust root")
or issuer certificates are expiring soon it means that you must perform
credential rotation.

For example, if your issuer certificate is expired, you will see a message
similar to:

```text
linkerd-identity
----------------
√ certificate config is valid
√ trust roots are using supported crypto algorithm
√ trust roots are within their validity period
√ trust roots are valid for at least 60 days
√ issuer cert is using supported crypto algorithm
× issuer cert is within its validity period
issuer certificate is not valid anymore. Expired on 2019-12-19T09:02:01Z
see https://linkerd.io/checks/#l5d-identity-issuer-cert-is-time-valid for hints
```

If your trust anchor has expired, you will see a message similar to:

```text
linkerd-identity
----------------
√ certificate config is valid
√ trust roots are using supported crypto algorithm
× trust roots are within their validity period
Invalid roots:
* 79461543992952791393769540277800684467 identity.linkerd.cluster.local not valid anymore. Expired on 2019-12-19T09:11:30Z
see https://linkerd.io/checks/#l5d-identity-roots-are-time-valid  for hints
```

If encounter any of these errors, it means your cluster's TLS configuration is
	currently in an invalid state. To address this problem, please follow the
[Replacing Expired Certificates](/2/tasks/replacing_expired_certificates/)
	Guide instead.

## Generate a new trust anchor and issuer certificate

If you've installed Linkerd from its default manifest, the first step is to
replace the trust anchor and issuer certificate. (If you installed Linkerd with a
manually-supplied trust anchor that has not expired, however, then this step is
unnecessary&mdash;go directly to the [Updating the identity issuer
certificate](#updating-the-identity-issuer-certificate) step.)

First, generate the trust anchor certificate and its private key:

```bash
step certificate create identity.linkerd.cluster.local ca-new.crt ca-new.key --profile root-ca --no-password --insecure
```

Note that we use `--no-password --insecure` to avoid encrypting these files
with a passphrase. Store the private key somewhere secure so that it can be
used to generate a new trust anchor in the future.

## Bundle your original trust anchor with the new one

Next, we need to bundle the trust anchor currently used by Linkerd together with
the new anchor. The following command uses `kubectl` to fetch the Linkerd config,
`jq to extract the current trust anchor, and `step` to combine it with the newly
generated trust anchor:

```bash
kubectl -n linkerd get cm linkerd-config -o=jsonpath='{.data.global}' |  \
jq -r .identityContext.trustAnchorsPem > original-trust.crt
step certificate bundle ca-new.crt original-trust.crt bundle.crt
rm original-trust.crt
```

## Deploying the new bundle to Linkerd

Finally, you can use the `linkerd upgrade` command to instruct Linkerd to work
with the new trust bundle:

```bash
linkerd upgrade  --identity-trust-anchors-file=./bundle.crt | kubectl apply -f -
```

This will restart the proxies in the Linkerd control plane, and they will be
reconfigured with the new trust anchor.

Finally, you must restart the proxy for all injected workloads in your cluster.
Doing that for the `emojivoto` namespace for example would look like:

```bash
kubectl -n emojivoto rollout restart deploy
```

Now you can run the `check` command to ensure that everything is ok:

```bash
linkerd check --proxy
```

You might have to wait a few moments until all the pods have been restarted and
are configured with the correct trust anchor. Meanwhile you might observe warnings:

```text
linkerd-identity
----------------
√ certificate config is valid
√ trust roots are using supported crypto algorithm
√ trust roots are within their validity period
√ trust roots are valid for at least 60 days
√ issuer cert is using supported crypto algorithm
√ issuer cert is within its validity period
‼ issuer cert is valid for at least 60 days
    issuer certificate will expire on 2019-12-19T09:51:19Z
    see https://linkerd.io/checks/#l5d-identity-issuer-cert-not-expiring-soon for hints
√ issuer cert is issued by the trust root

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
    see https://linkerd.io/checks/#l5d-identity-data-plane-proxies-certs-match-ca for hints
```

When the rollout completes, your `check` command should stop warning you that
pods need to be restarted. It will still warn you, however, that your issuer
certificate is about to expire soon:

```text
linkerd-identity
----------------
√ certificate config is valid
√ trust roots are using supported crypto algorithm
√ trust roots are within their validity period
√ trust roots are valid for at least 60 days
√ issuer cert is using supported crypto algorithm
√ issuer cert is within its validity period
‼ issuer cert is valid for at least 60 days
    issuer certificate will expire on 2019-12-19T09:51:19Z
    see https://linkerd.io/checks/#l5d-identity-issuer-cert-not-expiring-soon for hints
√ issuer cert is issued by the trust root

linkerd-identity-data-plane
---------------------------
√ data plane proxies certificate match CA
```

## Updating the identity issuer certificate

Now, using your trust anchor, generate the issuer certificate and key pair:

```bash
step certificate create identity.linkerd.cluster.local issuer-new.crt issuer-new.key --ca ca-new.crt --ca-key ca-new.key --profile intermediate-ca --not-after 8760h --no-password --insecure
```

Provided that all proxies are updated to include a working trust anchor, it is
safe to rotate the identity issuer certificate by using the `upgrade` command
again:

```bash
linkerd upgrade  --identity-issuer-certificate-file=./issuer-new.crt --identity-issuer-key-file=./issuer-new.key | kubectl apply -f -
```

At this point Linkerd's `identity` control plane service should detect the
change of the secret and automatically update its issuer certificates. To
ensure this has happened, you can check for the specific Kubernetes event.

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

```text
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

## Removing the old trust anchor

We can now remove the old trust anchor from the trust bundle we created earlier.
The `upgrade` command can do that for the Linkerd components:

```bash
linkerd upgrade  --identity-trust-anchors-file=./ca-new.crt  | kubectl apply -f -
```

Note that the ./ca-new.crt file is the same trust anchor you created at the start
of this process. Additionally, you can use the `rollout restart` command to
bring the configuration of your other injected resources up to date:

```bash
kubectl -n emojivoto rollout restart deploy
linkerd check --proxy
```

Finally the output of the `check` command should not produce any warnings or
errors:

```text
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
