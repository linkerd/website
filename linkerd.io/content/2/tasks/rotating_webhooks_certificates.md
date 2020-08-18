+++
title = "Rotating webhooks certificates"
description = "Follow these steps to rotate your Linkerd webhooks certificates"
+++

Linkerd uses the
[Kubernetes admission webhooks](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/#admission-webhooks)
and
[extension API server](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/apiserver-aggregation/)
to implement some of its core features like
[automatic proxy injection](/2/features/proxy-injection),
[service profiles validation](/2/features/service-profiles/) and `tap`.

To secure the connections between the Kubernetes API server and the
webhooks, all the webhooks are TLS-enabled. The x509 certificates used by these
webhooks are issued by the self-signed CA certificates embedded in the webhooks
configuration.

By default, these certificates have a validity period of 365 days. They are
stored in the following secrets, in the `linkerd` namespace:
`linkerd-proxy-injector-tls`, `linkerd-sp-validator-tls`, `linkerd-tap-tls`.

The rest of this documentation provides instructions on how to renew these
certificates.

## Renewing the webhook certificates

To check the validity of all the TLS secrets
(using [`step`](https://smallstep.com/cli/)):

```bash
for secret in "linkerd-proxy-injector-tls" "linkerd-sp-validator-tls" "linkerd-tap-tls"; do \
  kubectl -n linkerd get secret "${secret}" -ojsonpath='{.data.crt\.pem}' | \
    base64 -d - | \
    step certificate inspect - | \
    grep -iA2 validity; \
done
```

Manually delete these secrets and use `linkerd upgrade` to recreate them:

```bash
for secret in "linkerd-proxy-injector-tls" "linkerd-sp-validator-tls" "linkerd-tap-tls"; do \
  kubectl -n linkerd delete secret "${secret}"; \
done

linkerd upgrade | kubectl apply -f -
```

The above command will recreate the secrets without restarting Linkerd.

{{< note >}}
For Helm users, use the `helm upgrade` command to recreate the deleted secrets.
{{< /note >}}


Confirm that the secrets are recreated with new certificates:

```bash
for secret in "linkerd-proxy-injector-tls" "linkerd-sp-validator-tls" "linkerd-tap-tls"; do \
  kubectl -n linkerd get secret "${secret}" -ojsonpath='{.data.crt\.pem}' | \
    base64 -d - | \
    step certificate inspect - | \
    grep -iA2 validity; \
done
```

Ensure that Linkerd remains healthy:

```bash
linkerd check
```

{{< note >}}
Restarting the Linkerd control plane is usually not necessary. But if the
webhooks continue to log certificate expiry errors, restart their pods using the
`kubectl -n linkerd rollout restart` command.
{{< /note >}}
