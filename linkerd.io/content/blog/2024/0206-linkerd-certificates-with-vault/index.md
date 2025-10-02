---
date: 2024-02-06T00:00:00Z
slug: linkerd-certificates-with-vault
title: |-
  Workshop Recap: Linkerd Certificate Management with Vault
keywords: [linkerd, "2.14", features, vault]
params:
  author: flynn
  showCover: true
---

_This blog post is based on a workshop that I delivered way back in September
2023(!) at Buoyant’s
[Service Mesh Academy](https://buoyant.io/service-mesh-academy). If this seems
interesting, check out the
[full recording](https://buoyant.io/service-mesh-academy/linkerd-with-external-cas-using-vault)!_

## Linkerd Certificate Management with Vault

Linkerd's ability to automatically secure communications using mTLS has always
been one of its headline features. Of course, mTLS requires certificates, and
managing certificates can be very tricky: you need to generate them, rotate
them, and distribute them to all the places that need them... while still being
careful to avoid exposing any private keys.

For many of the demos we do, we sidestep all this by letting `linkerd install`
silently generate the certificates we need, then ignoring them beyond that. This
is vaguely OK for a demo, but it's totally unacceptable for the real world. In
the real world:

- The secret key for Linkerd's trust anchor should never be stored on the
  cluster at all.

- However, you'll need access to the secret key to rotate the identity issuer
  certificate, which should happen frequently.

- Finally, your organization may require that the trust anchor certificate must
  be issued by a corporate certifying authority (CA), rather than being some
  self-signed monstrosity. (They might require that of the identity issuer
  certificate too: in many situations, the corporate security folks don't like
  delegating issuing authority, for various reasons.)

Ultimately, the way to tackle all of these issues is to use an _external CA_ to
issue at least the trust anchor certificate. There are several ways to set that
up: in this article, we'll walk through a fairly real-world scenario:

- We'll install Linkerd without generating any certificates by hand, and without
  having Linkerd generate the certificates itself;

- We'll have Vault running _outside_ the cluster to store keys and generate
  certificates; and

- We'll have cert-manager running _inside_ the cluster to get the things Linkerd
  needs from Vault, and store them where Linkerd needs to find them.

Note that our goal is **not** to teach you how to use Vault, in particular: it's
to show a practical, relatively low-effort way to actually use external PKI with
Linkerd to bootstrap a zero-trust environment in Kubernetes. Many companies have
existing external PKI already set up (whether with Vault or something else);
being able to make use of it without too much work is a huge win

## The Setup

In order to demo all this simply, we'll be running Kubernetes in a `k3d`
cluster. We'll run Vault in Docker to make things easy to demo, but we will
_not_ be running Docker in Kubernetes: Vault will run as a separate Docker
container that happens to be connected to the same Docker network as our `k3d`
cluster.

The big win of this setup is that you can run it completely on a laptop with no
external dependencies. If you want to replicate this with a cluster in the
cloud, that's no problem: just figure out a reasonable place outside the cluster
to run your Vault instance, and make sure that both your Kubernetes cluster and
your local machine have IP connectivity to your Vault instance. Everything else
should be pretty much the same.

The way all the pieces fit together here is more complex than normal:

- We'll start by creating our `k3d` cluster. This will be named `pki-cluster`,
  and we'll tell `k3d` to connect it to a network named `pki-network`.

- We'll then fire up Vault in a Docker container that's also connected to
  `pki-network`. (And yes, we'll use Vault in dev mode to make life easier, but
  that's the only way we'll cheat in this setup.)

- We'll then use the `vault` CLI _running on our local machine_ to configure
  Vault in Docker.

Taken together, this implies that we'll have to make sure that we can talk to
the Vault instance both from inside the Docker network and from our host
machine. This mirrors many real-world setups where your Kubernetes cluster is on
one network, but you do administration from a different network.

### Tools of the trade

You'll need several CLI tools for this:

- `linkerd`, from `/2/getting-started/`;
- `kubectl`, from `https://kubernetes.io/docs/tasks/tools/`;
- `helm`, from `https://helm.sh/docs/intro/quickstart/`;
- `jq`, from `https://jqlang.github.io/jq/download/`;
- `vault`, from `https://developer.hashicorp.com/vault/docs/install`; and
- `step`, from `https://smallstep.com/docs/step-cli/installation`.

Of course you'll also need Docker. You can get that from
`https://docs.docker.com/engine/install/`, or you can try Colima from
`https://github.com/abiosoft/colima` instead.

### Starting our `k3d` cluster

Creating the `k3d` cluster looks horrible, but isn't that bad:

```bash
k3d cluster create pki-cluster \
    -p "80:80@loadbalancer" -p "443:443@loadbalancer" \
    --network=pki-network \
    --k3s-arg '--disable=local-storage,traefik,metrics-server@server:*;agents:*'
```

(If you already have a cluster named `pki-cluster`, you'll need to delete it, or
change the name above.)

This command looks complex, but it's actually less terrible than you might think
-- most of it is just turning off things we don't need (traefik, local-storage,
and metrics-server), and we also expose ports 80 and 443 to our local system to
make it easy to try services out.

At this point, you should be able to run things like `kubectl get ns` or
`kubectl cluster-info` to verify that you can talk to your cluster. If not,
you'll need to figure out what's wrong and fix it.

### Starting Vault

We have a running `k3d` cluster, so now let's get Vault going. This is another
complex-looking command:

```bash
docker run \
       --detach \
       --rm --name vault \
       -p 8200:8200 \
       --network=pki-network \
       --cap-add=IPC_LOCK \
       hashicorp/vault \
       server \
       -dev -dev-listen-address 0.0.0.0:8200 \
       -dev-root-token-id my-token
```

Breaking this down, we start with `docker run` since we want to start a
container running, and then provide a lot of parameters:

- `--detach`: basically, run the container in the background;

- `--rm --name vault`: remove the container when it dies, and name it "vault" so
  we can find it easily later;

- `-p 8200:8200`: expose Vault's API port to our local system;

- `--network=pki-network`: connect to the same network as our `k3d` cluster; and

- `--cap-add=IPC_LOCK`: give the container the `IPC_LOCK` capability, which
  Vault needs.

Next is the image name (`hashicorp/vault`), and then comes the command line for
Vault itself:

- `server` is the (creatively named) command to run;

- `-dev`: run Vault in developer mode;

- `-dev-listen-address 0.0.0.0:8200`: bind on port 8200 on all interfaces rather
  than just `localhost`; and

- `-dev-root-token-id my-token`: set the dev-mode root "password" to `my-token`,
  which we will use to trivially log in later.

Once you run that, you'll have Vault running in a Docker container, hooked up to
the same network as the `pki-cluster` we started a moment ago. (Again, if you
already have a container named `vault` you'll either need to kill it or change
the name above.)

Next up, we'll want to use the `vault` CLI on the local host to configure Vault.
We'll start by setting the `VAULT_ADDR` environment variable, so that we don't
have to include it in every command. Remember, we'll be running the `vault` CLI
on our local system, so we can just do this all using our local shell.

```bash
export VAULT_ADDR=http://0.0.0.0:8200/
```

At this point you should be able to run `vault status` to make sure that all is
well.

### Setting up Vault

While this isn't a blog about how to operate Vault, we still need to configure
Vault to work the way Linkerd needs it to. We're not going to dive too deep into
the details here, but we'll talk a bit about it as we go.

First up, we'll authenticate our `vault` CLI to the Vault server, using the
`dev-root-token-id` that we passed to the server when we started it running.

```bash
vault login my-token
```

Next up, we need to enable the Vault PKI engine, so that we can work with X.509
certificates at all, and configure its maximum allowed expiry time for
certificates. Here we're using 90 days (2160 hours).

```bash
vault secrets enable pki
vault secrets tune -max-lease-ttl=2160h pki
```

After that, we need to tell Vault to enable the URLs that cert-manager expects
to use when talking to Vault.

```bash
vault write pki/config/urls \
   issuing_certificates="http://127.0.0.1:8200/v1/pki/ca" \
   crl_distribution_points="http://127.0.0.1:8200/v1/pki/crl"
```

Finally, cert-manager will need to present Vault with a token before Vault will
actually do things that cert-manager needs. Vault associates tokens with
_policies_, which are kind of like roles in other systems, so we'll start by
creating a policy that allows us to do anything...

```bash
cat <<EOF | vault policy write pki_policy -
path "pki*" {
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
EOF
```

...and then we'll get a token for that policy. Later, we'll feed this token to
cert-manager.

```bash
VAULT_TOKEN=$(vault write -field=token /auth/token/create \
                          policies="pki_policy" \
                          no_parent=true no_default_policy=true \
                          renewable=true ttl=767h num_uses=0)
```

## Creating the Trust Anchor

After all that, we can tell Vault to actually create our Linkerd trust anchor.
Note that:

- this certificate only exists within Vault;

- we explicitly give it the common name of `root.linkerd.cluster.local`;

- we set its TTL to our maximum of 2160 hours; and

- we tell Vault to generate it using elliptic-curve crypto (`key_type=ec`).

We tell `vault write` to only output the certificate, which we save so that we
can inspect it. Note that the certificate contains no private information, so
this is entirely safe.

```bash
CERT=$(vault write -field=certificate pki/root/generate/internal \
      common_name=root.linkerd.cluster.local \
      ttl=2160h key_type=ec)
echo "$CERT" | step certificate inspect -
```

You should see something like this:

```text {class=disable-copy}
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: 362108562520865298482690188008268341812601922978 (0x3f6d827011b333be6e509a3b13377282ed25a5a2)
    Signature Algorithm: ECDSA-SHA256
        Issuer: CN=root.linkerd.cluster.local
        Validity
            Not Before: Feb 7 23:09:21 2024 UTC
            Not After : May 7 23:09:51 2024 UTC
        Subject: CN=root.linkerd.cluster.local
        Subject Public Key Info:
            Public Key Algorithm: ECDSA
                Public-Key: (256 bit)
                X:
                    1f:ae:48:c9:29:0f:ce:58:43:9d:9a:1a:ba:a9:71:
                    4f:24:e3:31:fc:df:ae:da:ad:b9:04:b6:40:27:29:
                    e8:3e
                Y:
                    f6:01:86:cf:54:57:b0:d7:84:ee:e5:7d:64:6b:28:
                    21:99:7e:5a:bc:a3:92:17:01:51:0e:05:ba:69:97:
                    4f:57
                Curve: P-256
        X509v3 extensions:
            X509v3 Key Usage: critical
                Certificate Sign, CRL Sign
            X509v3 Basic Constraints: critical
                CA:TRUE
            X509v3 Subject Key Identifier:
                84:9A:D1:67:5F:24:53:22:A2:1D:A5:8A:D9:B1:F9:C8:2D:3F:59:12
            X509v3 Authority Key Identifier:
                keyid:84:9A:D1:67:5F:24:53:22:A2:1D:A5:8A:D9:B1:F9:C8:2D:3F:59:12
            Authority Information Access:
                CA Issuers - URI:http://127.0.0.1:8200/v1/pki/ca
            X509v3 Subject Alternative Name:
                DNS:root.linkerd.cluster.local
            X509v3 CRL Distribution Points:
                Full Name:
                  URI:http://127.0.0.1:8200/v1/pki/crl
    Signature Algorithm: ECDSA-SHA256
         30:44:02:20:46:35:54:a2:48:1e:56:04:7a:26:11:38:95:b3:
         72:e7:b2:08:f8:62:a0:46:3a:cc:5c:dd:ff:66:99:26:4e:84:
         02:20:22:2e:b8:78:7a:47:96:94:b7:db:cc:c7:57:22:d2:c2:
         89:55:bf:42:5e:23:ee:2e:c1:a8:b9:cf:cf:c5:50:a0
```

Look specifically at the `Subject` and `Issuer`, which should both be
`CN=root.linkerd.cluster.local`. Likewise, the `X509v3 Subject Key Identifier`
and `X509v3 Authority Key Identifier` should have the same key ID.

That's actually all we need there! Now it's on to get cert-manager installed.

## Installing cert-manager

We'll start by using Helm to install both cert-manager and trust-manager.

```bash
helm repo add --force-update jetstack https://charts.jetstack.io
helm repo update
```

When we install cert-manager, we'll have it create the `cert-manager` namespace,
and install the cert-manager CRDs too.

```bash
helm install cert-manager jetstack/cert-manager \
             -n cert-manager --create-namespace \
             --set installCRDs=true --wait
```

trust-manager will be installed in the `cert-manager` namespace, but we'll
explicitly tell it to use the `linkerd` namespace as its "trust namespace". The
trust namespace is the single namespace from which trust-manager is allowed to
read information, and we're going to need it to read the Linkerd identity
issuer.

We don't need to create the `cert-manager` namespace here (it already exists),
but we _do_ need to create the `linkerd` namespace manually so that we can use
it as the trust namespace.

```bash
kubectl create namespace linkerd
helm install trust-manager jetstack/trust-manager \
             -n cert-manager \
             --set app.trust.namespace=linkerd \
             --wait
```

At this point, if you run `kubectl get pods -n cert-manager`, you should see
both cert-manager and trust-manager running:

```bash {class=disable-copy}
NAME                                      READY   STATUS    RESTARTS   AGE
cert-manager-cainjector-768dc45f6-6zkvn   1/1     Running   0          47s
cert-manager-845bf45b88-g94ls             1/1     Running   0          47s
cert-manager-webhook-7d9dddbf74-tkrht     1/1     Running   0          47s
trust-manager-76fc8cbb64-szwch            1/1     Running   0          25s
```

## Configuring cert-manager: the access-token secret

OK, cert-manager is running! Next step, we need to configure it to produce the
certificates we need. This starts with saving the Vault token we got awhile back
for cert-manager to use.

```bash
kubectl create secret generic \
               my-secret-token \
               --namespace=cert-manager \
               --from-literal=token="$VAULT_TOKEN"
```

We don't want to actually look into that secret, but we can describe it to make
sure that there's some data in it, at least.
`kubectl describe secret -n cert-manager my-secret-token` should show a key
called `token` with some data in it:

```text {class=disable-copy}
Name:         my-secret-token
Namespace:    cert-manager
Labels:       <none>
Annotations:  <none>

Type:  Opaque

Data
====
token:  95 bytes
```

## Configuring cert-manager: the Vault issuer

Recall that Linkerd needs two certificates:

- the _trust anchor_ is the root of the heirarchy for Linkerd; and
- the _identity issuer_ is an intermediate CA cert that must be signed by the
  trust anchor.

We've already told Vault to create the trust anchor for us: next up, we need to
configure cert-manager to create the identity issuer certificate. To do this,
cert-manager will produce a _certificate signing request_ (CSR), which it will
then hand to Vault. Vault will use the CSR to produce a signed identity issuer
for cert-manager.

To make all this happen, we use a cert-manager ClusterIssuer resource to tell
cert-manager how to talk to Vault. This ClusterIssuer needs three critical bits
of information:

1. The access token, which we just saved in a Secret.
2. The address of the Vault server.
3. The URL path to use to ask Vault for a new certificate. For Vault, this is
   `pki/root/sign-intermediate`.

So the address of the Vault server is the missing bit at the moment: we can't
use `0.0.0.0` as we've been doing from our local host, because cert-manager
needs to talk to Vault from inside the Docker network. That means we need to
figure out the address of the `vault` container within that network.

Fortunately, that's not that hard: `docker inspect pki-network` will show us all
the details of everything attached to the `pki-network`, as JSON, so we can use
`jq` to extract the single bit that we need: the `IPv4Address` contained in the
block that also has a `Name` of `vault`:

```bash
VAULT_DOCKER_ADDRESS=$(
  docker inspect pki-network \
     | jq -r '.[0].Containers | .[] | select(.Name == "vault") | .IPv4Address' \
     | cut -d/ -f1
  )
```

Given the right address for Vault, we can assemble the correct YAML:

```bash
sed -e "s/%VAULT_DOCKER_ADDRESS%/${VAULT_DOCKER_ADDRESS}/g" \
    <<EOF > /tmp/vault-issuer.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: vault-issuer
  namespace: cert-manager
spec:
  vault:
    path: pki/root/sign-intermediate
    server: http://%VAULT_DOCKER_ADDRESS%:8200
    auth:
      tokenSecretRef:
         name: my-secret-token
         key: token
EOF
```

(If you look at `/tmp/vault-issuer.yaml`, you'll see that the `server` element
has the correct IP address in it.) Let's go ahead and apply that, then check to
make sure it's happy.

```bash
kubectl apply -f /tmp/vault-issuer.yaml
kubectl get clusterissuers -o wide
```

You should see the `vault-issuer` show with `READY` true and `STATUS` "Vault
verified", telling us that cert-manager was able to talk to Vault.

```text {class=disable-copy}
NAME           READY   STATUS           AGE
vault-issuer   True    Vault verified   6s
```

Now that cert-manager can sign our certificates, let's go ahead and tell
cert-manager how to set things up for Linkerd. First, we'll use a Certificate
resource to tell cert-manager how to use the Vault issuer to issue our identity
issuer certificate:

```bash
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: linkerd-identity-issuer
  namespace: linkerd
spec:
  secretName: linkerd-identity-issuer
  duration: 48h
  renewBefore: 25h
  issuerRef:
    name: vault-issuer
    kind: ClusterIssuer
  commonName: identity.linkerd.cluster.local
  dnsNames:
  - identity.linkerd.cluster.local
  isCA: true
  privateKey:
    algorithm: ECDSA
  usages:
  - cert sign
  - crl sign
  - server auth
  - client auth
EOF
```

**NOTE** that this Certificate goes in the `linkerd` namespace, **not** the
`cert-manager` namespace! This is because Linkerd actually needs access to the
identity issuer, so we have cert-manager create it where it will need to be
used.

Running `kubectl get certificate -n linkerd` at this point should show our
Certificate with `READY` true:

```text {class=disable-copy}
NAME                      READY   SECRET                    AGE
linkerd-identity-issuer   True    linkerd-identity-issuer   11s
```

and if we `kubectl describe secret -n linkerd linkerd-identity-issuer` we should
see a `kubernetes.io/tls` Secret with keys of `ca.crt`, `tls.crt`, and
`tls.key`:

```text {class=disable-copy}
Name:         linkerd-identity-issuer
Namespace:    linkerd
Labels:       controller.cert-manager.io/fao=true
Annotations:  cert-manager.io/alt-names: identity.linkerd.cluster.local
              cert-manager.io/certificate-name: linkerd-identity-issuer
              cert-manager.io/common-name: identity.linkerd.cluster.local
              cert-manager.io/ip-sans:
              cert-manager.io/issuer-group:
              cert-manager.io/issuer-kind: ClusterIssuer
              cert-manager.io/issuer-name: vault-issuer
              cert-manager.io/uri-sans:

Type:  kubernetes.io/tls

Data
====
ca.crt:   851 bytes
tls.crt:  863 bytes
tls.key:  227 bytes
```

Finally, we'll use a Bundle resource to tell trust-manager to copy only the
public half of the trust anchor into a ConfigMap for Linkerd to use. Note that
Bundles are always cluster-scoped -- but also note that the reason we don't have
to specify namespaces for the source and destination is that trust-manager can
only read from its trust namespace, in this case `linkerd`, and it defaults to
writing there too.

```bash
kubectl apply -f - <<EOF
apiVersion: trust.cert-manager.io/v1alpha1
kind: Bundle
metadata:
  name: linkerd-identity-trust-roots
spec:
  sources:
  - secret:
      name: "linkerd-identity-issuer"
      key: "ca.crt"
  target:
    configMap:
      key: "ca-bundle.crt"
EOF
```

At this point, `kubectl get bundle` (remember, it's cluster-scoped!) should show
us a Bundle named `linkerd-identity-trust-roots` with `SYNCED` true:

```text {class=disable-copy}
NAME                           TARGET   SYNCED   REASON   AGE
linkerd-identity-trust-roots            True     Synced   4s
```

## Installing Linkerd

**Finally** we're ready to deploy Linkerd! We may as well use Helm for this,
too. Start by setting up Helm repos:

```bash
helm repo add --force-update linkerd https://helm.linkerd.io/stable
helm repo update
```

...then install the Linkerd CRDs.

```bash
helm install linkerd-crds -n linkerd linkerd/linkerd-crds
```

After that we can actually install Linkerd! Pay attention to these `--set`
parameters we pass here:

- `identity.issuer.scheme=kubernetes.io/tls` tells Helm that it should expect
  the identity issuer to already exist, so don't try to create one, and
- `identity.externalCA=true` tells Helm that it should expect the trust bundle
  to already exist, too.

These things, of course, are being handled by cert-manager and trust-manager.

```bash
helm install linkerd-control-plane linkerd/linkerd-control-plane \
     -n linkerd \
     --set identity.issuer.scheme=kubernetes.io/tls \
     --set identity.externalCA=true
```

Once that's done, we can use `linkerd check` to validate that everything worked:

```bash
linkerd check
```

Note that we see a warning for the identity issuer certificate not being valid
for at least 60 days. That's expected, since we created that with a 48-hour
lifespan!

## Summary

After all that, we have Vault generating all our certificates, cert-manager and
trust-manager handling rotating and distributing them as needed, and Linkerd
consuming them for mTLS everywhere.

Critically, Vault is _not running in our cluster_, and if you look back over
this whole process, the private key for the trust anchor has never been revealed
outside of Vault. Using an external CA to isolate key generation lets us
dramatically increase security of the overall system.

Vault, of course, isn't the only external CA we can use: cert-manager supports a
lot of different issuers, including ACME, Vault, Venafi, and many others issuers
(see the
[cert-manager documentation](https://cert-manager.io/docs/configuration/external/)
for more about this). We used Vault for this workshop because it's free to use
and relatively easy to set up in Docker, but you're encouraged to try other
kinds of external CAs -- ultimately, the critical bit isn't which one you use,
it's that you're keeping your secret keys secret.

---

_If you found this interesting, check out the Service Mesh Academy workshop on
[Linkerd with external CAs using Vault](https://buoyant.io/service-mesh-academy/linkerd-with-external-cas-using-vault),
where you can see the hands-on demo of everything I've talked about here! And,
as always, feedback is always welcome -- you can find me as `@flynn` on the
[Linkerd Slack](https://slack.linkerd.io)._
