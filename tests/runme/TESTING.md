```sh
$ brew install google-cloud-sdk linkerd
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

```sh
$ brew install watch
```

```sh { background=true interactive=true }
$ watch -n 1 kubectl get pods -A
```

## Run the docs tests

```sh
$ git submodule update --init
```

```sh { name= closeTerminalOnSuccess=false interactive=false }
$ npx bats getting-started.bats
```
