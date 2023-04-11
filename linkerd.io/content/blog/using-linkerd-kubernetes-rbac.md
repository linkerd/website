---
slug: 'using-linkerd-kubernetes-rbac'
title: 'Using Linkerd with Kubernetes RBAC'
aliases:
  - /2017/07/24/using-linkerd-kubernetes-rbac/
author: 'risha'
date: Mon, 24 Jul 2017 22:09:31 +0000
draft: false
featured: false
thumbnail: /uploads/linkerd_featured.png
tags: [Linkerd, linkerd, News, tutorials]
---

If you're running Kubernetes 1.6 or later, you can optionally make use of Kubernetes' new support for [RBAC (role-based access control)](https://kubernetes.io/blog/2017/04/rbac-support-in-kubernetes/), which allows you to restrict who can [access the Kubernetes API](https://kubernetes.io/docs/admin/accessing-the-api/) on the cluster and what they can do with it. However, when upgrading to an RBAC-enabled cluster you can run into issues, as many Kubernetes examples do not take into account the fact that certain API calls may be restricted.

In this post, we’ll show you how to use [Linkerd](https://linkerd.io), our open source _service mesh_ for cloud-native applications, with RBAC-enabled Kubernetes clusters.

## What is RBAC?

First, it's helpful to understand what RBAC actually does. RBAC works by defining a _role_ that describes a set of permissions, and by then assigning that role to relevant users/service accounts. In Kubernetes RBAC, these roles restrict which Kubernetes verbs can be used (e.g. `get`, `list`, `create`), and which Kubernetes resources they can be applied to (e.g. `pods`, `services`). So, for example, we can create a `Role` (called, for example, “read-only”) that only allows `get` and `watch` on pod resources. And we can then create `RoleBinding`s to assign this “read-only” role to whichever “subjects” need them, e.g. the “qa-bot” service account.

In order for Linkerd to operate in an RBAC-enabled cluster, we need to make sure that the types of access that Linkerd needs to the Kubernetes APIs are allowed. Below, we'll walk through how to do this. If you just want the completed config, you can skip to the bottom—or just use [linkerd-rbac-beta.yml][linkerd-rbac] (stored in our [linkerd-examples][linkerd-example] repo).

We'll be setting up the permission by creating a `ClusterRole` and a `ClusterRoleBinding`, illustrated below.

{{< fig
  alt="RBAC"
  title="Configuration"
  src="/uploads/2018/05/blog_rbac_configuration.png" >}}

## Granting Linkerd access to an RBAC Kubernetes Cluster

When used with a Kubernetes cluster, Linkerd uses its `io.l5d.k8s` “namer” to do service discovery against the Kubernetes API. (Of course, this namer can be used in conjunction with other service discovery mechanisms, allowing Linkerd to bridge Kubernetes and non-Kubernetes systems—but that's a later blog post).

Linkerd only requires read access, and only needs access to access the `services` and `endpoints` Kubernetes resources. We can capture this access via the following Kubernetes config:

```yml
---
# grant linkerd/namerd permissions to enable service discovery
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
 name: linkerd-endpoints-reader
rules:
 - apiGroups: [""] # "" indicates the core API group
 resources: ["endpoints", "services", "pods"] # pod access is required for the *-legacy.yml examples in linkerd-examples
 verbs: ["get", "watch", "list"]
```

For simplicity’s sake, at this point we could just assign this role to the `default` service account (which is the account Kubernetes assigns to you when you [create a pod](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/) if you don’t specify one):

```yml
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
 name: linkerd-role-binding
subjects:
 - kind: ServiceAccount
 name: default # change this to your service account if you’ve specified one
 namespace: default
roleRef:
 kind: ClusterRole
 name: linkerd-endpoints-reader
 apiGroup: rbac.authorization.k8s.io
```

Linkerd now has the access it needs to function in a Kubernetes environment. In production, however, you might want to use a dedicated service account—[see below](#running-linkerd-with-a-specified-service-account).

### Namerd

If you’re using [Namerd](https://github.com/linkerd/linkerd/blob/master/namerd/README.md) as a control plane to dynamically change routing configuration across all Linkerd instances ([see here](https://buoyant.io/2016/11/04/a-service-mesh-for-kubernetes-part-iv-continuous-deployment-via-traffic-shifting/) for why you might want to do this), you’ll need some additional permissions. Namerd needs access to a Kubernetes `ThirdPartyResource` to store its routing rules ("dtabs"). In our example namerd.yml, we’ve added this resource as `d-tab.l5d.io`. We can allow Namerd read and write access to this resource using the following role:

```yml
---
# grant namerd permissions to third party resources for dtab storage
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
 name: namerd-dtab-storage
rules:
 - apiGroups: ["l5d.io"]
 resources: ["dtabs"]
 verbs: ["get", "watch", "list", "update", "create"]
```

Similar to above, we’ll assign the role to the `default` service account with a role binding:

```yml
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
 name: namerd-role-binding
subjects:
 - kind: ServiceAccount
 name: default
 namespace: default
roleRef:
 kind: ClusterRole
 name: namerd-dtab-storage
 apiGroup: rbac.authorization.k8s.io
```

### Running Linkerd with a specified Service Account

In the previous sections, we used the default service account to run Linkerd. For some use cases, however, you may want to create a dedicated service account and assign the permissions to that account. You’ll also want to consider whether you want roles to be cluster-scoped (`ClusterRoleBinding`) or namespace-scoped (`RoleBinding`). Let’s go through how to configure permissions for a specific service account, `linkerd-svc-account`, starting from the [linkerd.yml][daemonset] config in linkerd-examples. We’ll add a `ServiceAccount` config, and assign that service account to the pod. Here’s part of the file, with `linkerd-svc-account` added:

```yml
---
apiVersion: extensions/v1beta1
kind: DaemonSet
metadata:
  labels:
    app: l5d
  name: l5d
spec:
  template:
    metadata:
      labels:
        app: l5d
    spec:
      volumes:
        - name: l5d-config
          configMap:
            name: 'l5d-config'
            serviceAccount: linkerd-svc-account
      containers:
        - name: l5d
          image: buoyantio/linkerd:1.1.2
          env:
            - name: POD_IP
              valueFrom:
                fieldRef:
                  fieldPath: status.podIP
          args:
            - /io.buoyant/linkerd/config/config.yaml
          ports:
            - name: outgoing
              containerPort: 4140
              hostPort: 4140
            - name: incoming
              containerPort: 4141
            - name: admin
              containerPort: 9990
          volumeMounts:
            - name: 'l5d-config'
              mountPath: '/io.buoyant/linkerd/config'
              readOnly: true

        - name: kubectl
          image: buoyantio/kubectl:v1.4.0
          args:
            - 'proxy'
            - '-p'
            - '8001'
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: linkerd-svc-account
```

Then we’ll change the subject in your linkerd-rbac-beta.yml to reference this new service account:

```yml
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: linkerd-role-binding
subjects:
  - kind: ServiceAccount
    name: linkerd-svc-account
    namespace: default
roleRef:
  kind: ClusterRole
  name: linkerd-endpoints-reader
  apiGroup: rbac.authorization.k8s.io
```

And that’s it! The Linkerd pods now use the `linkerd-svc-account` and have the right permissions.

## Putting it all together

For a complete Kubernetes config file that uses all of the above, just use this file: [linkerd-rbac.yml][linkerd-rbac]. This config will allow Linkerd and Namerd to have all the access needed to the Kubernetes API with the default service account. If you'd like to set this up using a dedicated service account, you'll need to modify linkerd-rbac-beta.yml, as described in the previous section. We hope this post was useful. We’d love to get your thoughts. Please join us in the [Linkerd Support Forum](https://linkerd.buoyant.io/) and the Linkerd [Slack](https://slack.linkerd.io/) channel! And for more walkthroughs of how to use [Linkerd’s various features](https://linkerd.io/features/index.html) on Kubernetes, see our [Service Mesh For Kubernetes]({{< ref
"a-service-mesh-for-kubernetes-part-i-top-line-service-metrics" >}}) blog series.

[daemonset]: https://raw.githubusercontent.com/linkerd/linkerd-examples/master/k8s-daemonset/k8s/linkerd.yml
[linkerd-rbac]: https://github.com/linkerd/linkerd-examples/blob/master/k8s-daemonset/k8s/linkerd-rbac.yml
[linkerd-example]: https://github.com/linkerd/linkerd-examples/tree/master/k8s-daemonset
