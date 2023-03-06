```sh
$ brew install google-cloud-sdk
$ npm install -g bats
```

```sh
$ gcloud components install gke-gcloud-auth-plugin
```

```sh
$ gcloud auth login
```

```sh
$ gcloud config set project runme-ci
```

```sh
$ export YOUR_CLUSTER=Name of your cluster
$ gcloud container clusters get-credentials $YOUR_CLUSTER --zone us-central1-c --project runme-ci
```

```sh { interactive=false }
$ kubectl get pods -A
```

## Run the docs tests

```sh { name= closeTerminalOnSuccess=false interactive=false }
$ export "PATH=$PATH:/home/sourishkrout/.linkerd2/bin"
$ npx bats getting-started.bats
```
