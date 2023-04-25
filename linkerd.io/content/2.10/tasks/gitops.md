+++
title = "Using GitOps with Linkerd with Argo CD"
description = "Use Argo CD to manage Linkerd installation and upgrade lifecycle."
+++

GitOps is an approach to automate the management and delivery of your Kubernetes
infrastructure and applications using Git as a single source of truth. It
usually utilizes some software agents to detect and reconcile any divergence
between version-controlled artifacts in Git with what's running in a cluster.

This guide will show you how to set up
[Argo CD](https://argoproj.github.io/argo-cd/) to manage the installation and
upgrade of Linkerd using a GitOps workflow.

{{< trylpt >}}

Specifically, this guide provides instructions on how to securely generate and
manage Linkerd's mTLS private keys and certificates using
[Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) and
[cert-manager](https://cert-manager.io). It will also show you how to integrate
the [auto proxy injection](../../features/proxy-injection/) feature into your
workflow. Finally, this guide conclude with steps to upgrade Linkerd to a newer
version following a GitOps workflow.

{{< fig alt="Linkerd GitOps workflow"
      title="Linkerd GitOps workflow"
      src="/images/gitops/architecture.png" >}}

The software and tools used in this guide are selected for demonstration
purposes only. Feel free to choose others that are most suited for your
requirements.

You will need to clone this
[example repository](https://github.com/linkerd/linkerd-examples) to your local
machine and replicate it in your Kubernetes cluster following the steps defined
in the next section.

## Set up the repositories

Clone the example repository to your local machine:

```sh
git clone https://github.com/linkerd/linkerd-examples.git
```

This repository will be used to demonstrate Git operations like `add`, `commit`
and `push` later in this guide.

Add a new remote endpoint to the repository to point to the in-cluster Git
server, which will be set up in the next section:

```sh
cd linkerd-examples

git remote add git-server git://localhost/linkerd-examples.git
```

{{< note >}}
To simplify the steps in this guide, we will be interacting with the in-cluster
Git server via port-forwarding. Hence, the remote endpoint that we just created
targets your localhost.
{{< /note >}}

Deploy the Git server to the `scm` namespace in your cluster:

```sh
kubectl apply -f gitops/resources/git-server.yaml
```

Later in this guide, Argo CD will be configured to watch the repositories hosted
by this Git server.

{{< note >}}
This Git server is configured to run as a
[daemon](https://git-scm.com/book/en/v2/Git-on-the-Server-Git-Daemon) over the
`git` protocol, with unauthenticated access to the Git data. This setup is not
recommended for production use.
{{< /note >}}

Confirm that the Git server is healthy:

```sh
kubectl -n scm rollout status deploy/git-server
```

Clone the example repository to your in-cluster Git server:

```sh
git_server=`kubectl -n scm get po -l app=git-server -oname | awk -F/ '{ print $2 }'`

kubectl -n scm exec "${git_server}" -- \
  git clone --bare https://github.com/linkerd/linkerd-examples.git
```

Confirm that the remote repository is successfully cloned:

```sh
kubectl -n scm exec "${git_server}" -- ls -al /git/linkerd-examples.git
```

Confirm that you can push from the local repository to the remote repository
via port-forwarding:

```sh
kubectl -n scm port-forward "${git_server}" 9418  &

git push git-server master
```

## Deploy Argo CD

Install Argo CD:

```sh
kubectl create ns argocd

kubectl -n argocd apply -f \
  https://raw.githubusercontent.com/argoproj/argo-cd/v1.6.1/manifests/install.yaml
```

Confirm that all the pods are ready:

```sh
for deploy in "application-controller" "dex-server" "redis" "repo-server" "server"; \
  do kubectl -n argocd rollout status deploy/argocd-${deploy}; \
done
```

Use port-forward to access the Argo CD dashboard:

```sh
kubectl -n argocd port-forward svc/argocd-server 8080:443  \
  > /dev/null 2>&1 &
```

The Argo CD dashboard is now accessible at
[https://localhost:8080](https://localhost:8080/), using the default `admin`
username and
[password](https://argoproj.github.io/argo-cd/getting_started/#4-login-using-the-cli).

{{< note >}}
The default admin password is the auto-generated name of the Argo CD API server
pod. You can use the `argocd account update-password` command to change it.
{{< /note >}}

Authenticate the Argo CD CLI:

```sh
argocd_server=`kubectl -n argocd get pods -l app.kubernetes.io/name=argocd-server -o name | cut -d'/' -f 2`

argocd login 127.0.0.1:8080 \
  --username=admin \
  --password="${argocd_server}" \
  --insecure
```

## Configure project access and permissions

Set up the `demo`
[project](https://argoproj.github.io/argo-cd/user-guide/projects/) to group our
[applications](https://argoproj.github.io/argo-cd/operator-manual/declarative-setup/#applications):

```sh
kubectl apply -f gitops/project.yaml
```

This project defines the list of permitted resource kinds and target clusters
that our applications can work with.

Confirm that the project is deployed correctly:

```sh
argocd proj get demo
```

On the dashboard:

{{< fig alt="New project in Argo CD dashboard"
      title="New project in Argo CD dashboard"
      src="/images/gitops/dashboard-project.png" >}}

### Deploy the applications

Deploy the `main` application which serves as the "parent" application that of
all the other applications:

```sh
kubectl apply -f gitops/main.yaml
```

{{< note >}}
The "app of apps" pattern is commonly used in Argo CD workflows to bootstrap
applications. See the Argo CD documentation for more
[information](https://argoproj.github.io/argo-cd/operator-manual/cluster-bootstrapping/#app-of-apps-pattern).
{{< /note >}}

Confirm that the `main` application is deployed successfully:

```sh
argocd app get main
```

Sync the `main` application:

```sh
argocd app sync main
```

{{< fig alt="Synchronize the main application"
      title="Synchronize the main application"
      src="/images/gitops/dashboard-applications-main-sync.png" >}}

Notice that only the `main` application is synchronized.

Next, we will synchronize the remaining applications individually.

### Deploy cert-manager

Synchronize the `cert-manager` application:

```sh
argocd app sync cert-manager
```

{{< note >}}
This guide uses cert-manager 0.15.0 due to an issue with cert-manager 0.16.0
and kubectl <1.19 and Helm 3.2, which Argo CD uses. See the upgrade notes
[here](https://cert-manager.io/docs/installation/upgrading/upgrading-0.15-0.16/#helm).
{{< /note >}}

Confirm that cert-manager is running:

```sh
for deploy in "cert-manager" "cert-manager-cainjector" "cert-manager-webhook"; \
  do kubectl -n cert-manager rollout status deploy/${deploy}; \
done
```

{{< fig alt="Synchronize the cert-manager application"
      title="Synchronize the cert-manager application"
      center="true"
      src="/images/gitops/dashboard-cert-manager-sync.png" >}}

### Deploy Sealed Secrets

Synchronize the `sealed-secrets` application:

```sh
argocd app sync sealed-secrets
```

Confirm that sealed-secrets is running:

```sh
kubectl -n kube-system rollout status deploy/sealed-secrets
```

{{< fig alt="Synchronize the sealed-secrets application"
      title="Synchronize the sealed-secrets application"
      center="true"
      src="/images/gitops/dashboard-sealed-secrets-sync.png" >}}

### Create mTLS trust anchor

Before proceeding with deploying Linkerd, we will need to create the mTLS trust
anchor. Then we will also set up the `linkerd-bootstrap` application to manage
the trust anchor certificate.

Create a new mTLS trust anchor private key and certificate:

```sh
step certificate create root.linkerd.cluster.local sample-trust.crt sample-trust.key \
  --profile root-ca \
  --no-password \
  --not-after 43800h \
  --insecure
```

Confirm the details (encryption algorithm, expiry date, SAN etc.) of the new
trust anchor:

```sh
step certificate inspect sample-trust.crt
```

Create a `SealedSecret` resource to store the encrypted trust anchor:

```sh
kubectl -n linkerd create secret tls linkerd-trust-anchor \
  --cert sample-trust.crt \
  --key sample-trust.key \
  --dry-run=client -oyaml | \
kubeseal --controller-name=sealed-secrets -oyaml - | \
kubectl patch -f - \
  -p '{"spec": {"template": {"type":"kubernetes.io/tls", "metadata": {"labels": {"linkerd.io/control-plane-component":"identity", "linkerd.io/control-plane-ns":"linkerd"}, "annotations": {"linkerd.io/created-by":"linkerd/cli stable-2.8.1", "linkerd.io/identity-issuer-expiry":"2021-07-19T20:51:01Z"}}}}}' \
  --dry-run=client \
  --type=merge \
  --local -oyaml > gitops/resources/linkerd/trust-anchor.yaml
```

This will overwrite the existing `SealedSecret` resource in your local
`gitops/resources/linkerd/trust-anchor.yaml` file. We will push this change to
the in-cluster Git server.

Confirm that only the `spec.encryptedData` is changed:

```sh
git diff gitops/resources/linkerd/trust-anchor.yaml
```

Commit and push the new trust anchor secret to your in-cluster Git server:

```sh
git add gitops/resources/linkerd/trust-anchor.yaml

git commit -m "update encrypted trust anchor"

git push git-server master
```

Confirm the commit is successfully pushed:

```sh
kubectl -n scm exec "${git_server}" -- git --git-dir linkerd-examples.git log -1
```

## Deploy linkerd-bootstrap

Synchronize the `linkerd-bootstrap` application:

```sh
argocd app sync linkerd-bootstrap
```

{{< note >}}
If the issuer and certificate resources appear in a degraded state, it's likely
that the SealedSecrets controller failed to decrypt the sealed
`linkerd-trust-anchor` secret. Check the SealedSecrets controller for error logs.

For debugging purposes, the sealed resource can be retrieved using the
`kubectl -n linkerd get sealedsecrets linkerd-trust-anchor -oyaml` command.
Ensure that this resource matches the
`gitops/resources/linkerd/trust-anchor.yaml` file you pushed to the in-cluster
Git server earlier.
{{< /note >}}

{{< fig alt="Synchronize the linkerd-bootstrap application"
      title="Synchronize the linkerd-bootstrap application"
      src="/images/gitops/dashboard-linkerd-bootstrap-sync.png" >}}

SealedSecrets should have created a secret containing the decrypted trust
anchor. Retrieve the decrypted trust anchor from the secret:

```sh
trust_anchor=`kubectl -n linkerd get secret linkerd-trust-anchor -ojsonpath="{.data['tls\.crt']}" | base64 -d -w 0 -`
```

Confirm that it matches the decrypted trust anchor certificate you created
earlier in your local `sample-trust.crt` file:

```sh
diff -b \
  <(echo "${trust_anchor}" | step certificate inspect -) \
  <(step certificate inspect sample-trust.crt)
```

### Deploy Linkerd

Now we are ready to install Linkerd. The decrypted trust anchor we just
retrieved will be passed to the installation process using the
`identityTrustAnchorsPEM` parameter.

Prior to installing Linkerd, note that the `global.identityTrustAnchorsPEM`
parameter is set to an "empty" certificate string:

```sh
argocd app get linkerd -ojson | \
  jq -r '.spec.source.helm.parameters[] | select(.name == "identityTrustAnchorsPEM") | .value'
```

{{< fig alt="Empty default trust anchor"
      title="Empty default trust anchor"
      src="/images/gitops/dashboard-trust-anchor-empty.png" >}}

We will override this parameter in the `linkerd` application with the value of
`${trust_anchor}`.

Locate the `identityTrustAnchorsPEM` variable in your local
`gitops/argo-apps/linkerd.yaml` file, and set its `value` to that of
`${trust_anchor}`.

Ensure that the multi-line string is indented correctly. E.g.,

```yaml
  source:
    chart: linkerd2
    repoURL: https://helm.linkerd.io/stable
    targetRevision: 2.8.0
    helm:
      parameters:
      - name: identityTrustAnchorsPEM
        value: |
          -----BEGIN CERTIFICATE-----
          MIIBlTCCATygAwIBAgIRAKQr9ASqULvXDeyWpY1LJUQwCgYIKoZIzj0EAwIwKTEn
          MCUGA1UEAxMeaWRlbnRpdHkubGlua2VyZC5jbHVzdGVyLmxvY2FsMB4XDTIwMDkx
          ODIwMTAxMFoXDTI1MDkxNzIwMTAxMFowKTEnMCUGA1UEAxMeaWRlbnRpdHkubGlu
          a2VyZC5jbHVzdGVyLmxvY2FsMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE+PUp
          IR74PsU+geheoyseycyquYyes5eeksIb5FDm8ptOXQ2xPcBpvesZkj6uIyS3k4qV
          E0S9VtMmHNeycL7446NFMEMwDgYDVR0PAQH/BAQDAgEGMBIGA1UdEwEB/wQIMAYB
          Af8CAQEwHQYDVR0OBBYEFHypCh7hiSLNxsKhMylQgqD9t7NNMAoGCCqGSM49BAMC
          A0cAMEQCIEWhI86bXWEd4wKTnG07hBfBuVCT0bxopaYnn3wRFx7UAiAwXyh5uaVg
          MwCC5xL+PM+bm3PRqtrmI6TocWH07GbMxg==
          -----END CERTIFICATE-----
```

Confirm that only one `spec.source.helm.parameters.value` field is changed:

```sh
git diff gitops/argo-apps/linkerd.yaml
```

Commit and push the changes to the Git server:

```sh
git add gitops/argo-apps/linkerd.yaml

git commit -m "set identityTrustAnchorsPEM parameter"

git push git-server master
```

Synchronize the `main` application:

```sh
argocd app sync main
```

Confirm that the new trust anchor is picked up by the `linkerd` application:

```sh
argocd app get linkerd -ojson | \
  jq -r '.spec.source.helm.parameters[] | select(.name == "identityTrustAnchorsPEM") | .value'
```

{{< fig alt="Override mTLS trust anchor"
      title="Override mTLS trust anchor"
      src="/images/gitops/dashboard-trust-anchor-override.png" >}}

Synchronize the `linkerd` application:

```sh
argocd app sync linkerd
```

Check that Linkerd is ready:

```sh
linkerd check
```

{{< fig alt="Synchronize Linkerd"
      title="Synchronize Linkerd"
      src="/images/gitops/dashboard-linkerd-sync.png" >}}

### Test with emojivoto

Deploy emojivoto to test auto proxy injection:

```sh
argocd app sync emojivoto
```

Check that the applications are healthy:

```sh
for deploy in "emoji" "vote-bot" "voting" "web" ; \
  do kubectl -n emojivoto rollout status deploy/${deploy}; \
done
```

{{< fig alt="Synchronize emojivoto"
      title="Synchronize emojivoto"
      src="/images/gitops/dashboard-emojivoto-sync.png" >}}

### Upgrade Linkerd to 2.8.1

Use your editor to change the `spec.source.targetRevision` field to `2.8.1` in
the `gitops/argo-apps/linkerd.yaml` file:

Confirm that only the `targetRevision` field is changed:

```sh
git diff gitops/argo-apps/linkerd.yaml
```

Commit and push this change to the Git server:

```sh
git add gitops/argo-apps/linkerd.yaml

git commit -m "upgrade Linkerd to 2.8.1"

git push git-server master
```

Synchronize the `main` application:

```sh
argocd app sync main
```

Synchronize the `linkerd` application:

```sh
argocd app sync linkerd
```

Confirm that the upgrade completed successfully:

```sh
linkerd check
```

Confirm the new version of the control plane:

```sh
linkerd version
```

### Clean up

All the applications can be removed by removing the `main` application:

```sh
argocd app delete main --cascade=true
```
