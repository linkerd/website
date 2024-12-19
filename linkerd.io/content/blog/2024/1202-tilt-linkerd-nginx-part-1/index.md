---
date: 2024-12-02T00:00:00Z
slug: tilt-linkerd-nginx-part-1
title: |-
  Building your Infrastructure with Tilt, Linkerd, and Nginx
description: |-
  What if you could develop your applications alongside the very infrastructure they rely on in production?
keywords: [linkerd, tilt, nginx, orbstack, kubernetes, development]
params:
  author:
    name: Chris Campbell, Linkerd Ambassador
    avatar: chris-campbell.png
    email: campbel@hey.com
  showCover: true
images: [social.png] # Open graph image
---

_This is part one of series by Linkerd Ambassador Chris Campbell exploring how
to bridge the gap between development and production by using Linkerd, Tilt,
and Ingress-Nginx to create a robust environment in which you can develop
using your real production infrastructure._

----

As applications grow more complex and cloud-native architectures become the
norm, developers face a common challenge: the disconnect between local
development environments and production infrastructure. Have you ever deployed
code only to discover it behaves differently in production? Or spent hours
debugging issues that only manifest in staging environments? You're not alone.

The traditional approach of developing applications in isolation from their
supporting infrastructure can lead to unexpected surprises and costly
debugging sessions. Infrastructure components like service meshes, ingress
controllers, and monitoring systems often introduce subtle behaviors that are
difficult to replicate locally. This creates a gap between development and
production environments that can slow down iteration cycles and introduce
bugs.

## Bridging the Gap

What if you could develop your applications alongside the actual
infrastructure they'll run on in production? In this guide, we'll explore how
to create a robust local development environment with [Tilt], combined with
popular cloud-native tools like Linkerd and [Ingress-Nginx]. This setup allows
you to:

* Develop applications while using real infrastructure features, from ingress
  rules to service mesh routing;
* Eliminate surprises by iterating on configuration until it works exactly as
  expected;
* Rapidly experiment with infrastructure changes to build a deeper
  understanding of your tools; and
* Create a development environment that closely mirrors production.

Let's dive into a practical example using a demo repository that showcases these principles in action.

[Tilt]: https://tilt.dev/
[Ingress-Nginx]: https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/

## Walk through the Demo Repo

The demo repository at
[github.com/campbel/tilt-linkerd-demo](https://github.com/campbel/tilt-linkerd-demo)
provides a complete example of this development setup. Let's explore its
structure and key components:

### Repository Structure

The repository is organized into several key directories:

* `/apps`: Contains our sample applications (foo, bar, baz) that demonstrate
  service-to-service communication
* `/infra`: Houses infrastructure components including Linkerd, Linkerd-Viz,
  Grafana, and Nginx Ingress
* `/synthetic`: Contains traffic generation tools for creating realistic load
  patterns
* `/toxic`: Includes chaos engineering components for testing resilience
* `/lib`: Contains shared Tilt configuration logic

## App Setup

Let's examine how individual applications are configured in this environment,
starting with the "foo" application.

### Application Configuration with Tilt

The heart of our application setup is the Tiltfile. Tilt uses these
configuration files to manage the build and deployment process, making local
development smooth and efficient. Here's the Tiltfile for our "foo"
application:

```python
# Imports
load('../../lib/Tiltfile', 'files')

# Build the docker container
docker_build(
    'foo',
    context='.',
    dockerfile='Dockerfile',
)

# Load the k8s yaml
k8s_yaml(files('manifests/*.yaml'))

# A bit of Tilt housekeeping to make sure Tilt knows the parts of the Foo app
k8s_resource(
    'foo',
    labels=['app'],
    objects=[
        'foo:ingress',
        'foo:serviceaccount',
        'foo-root-inbound:httproute',
        'foo:server',
        'foo:serverauthorization',
    ],

    # Automatically enable port forwards to the pod
    port_forwards=['8000:80'],

    # Provide links in the Tilt UI for the app
    links=[
        link('<http://foo.localhost:5050>', 'foo.localhost'),
    ],

    # Tilt resources this app depends on
    resource_deps=['linkerd-control-plane', 'ingress-nginx']
)
```

This Tiltfile does several important things:

* Builds our Docker container automatically when code changes
* Manages Kubernetes manifests for our application
* Sets up port forwarding for local access
* Configures dependencies on infrastructure components
* Provides convenient links in the Tilt UI

### Container Setup

Our application uses a straightforward Dockerfile that builds a Go
application:

```dockerfile
FROM golang:1.22-alpine

COPY . /app
WORKDIR /app

RUN go build -o foo main.go

CMD ["./foo"]
```

## Infrastructure Setup

The infrastructure components form the backbone of our local development
environment. Let's look at how we set these up to mirror production
capabilities while remaining developer-friendly.

### Nginx Ingress Controller

The Nginx Ingress Controller is a crucial component that manages external
access to our services. Here's how we set it up using Helm:

```python
load('ext://helm_resource', 'helm_resource', 'helm_repo')

# Create the ingress-nginx namespace if it doesn't exist
local('kubectl get ns ingress-nginx || kubectl create ns ingress-nginx')

# Add the ingress-nginx chart repository
helm_repo(
    'ingress-nginx',
    '<https://kubernetes.github.io/ingress-nginx>',
    resource_name='ingress-nginx-chart',
    labels=['ingress']
)

# Install the ingress-nginx chart
helm_resource(
    'ingress-nginx',
    'ingress-nginx/ingress-nginx',
    namespace='ingress-nginx',
    resource_deps=['ingress-nginx-chart', 'linkerd-control-plane'],
    release_name='ingress-nginx',
    port_forwards='5050:80',
    labels=['ingress'],
    flags=[
        '--version', '4.7.1',
        '--set', 'controller.allowSnippetAnnotations=true',
        '--set', 'controller.ingressClassResource.name=nginx',
        '--set', "controller.podAnnotations.'linkerd\\\\.io/inject'=enabled"
    ]
)
```

Note the important configuration choices:

* The controller is automatically injected into the Linkerd service mesh with
  the inject annotation.
* Port 5050 is exposed enabling nginx to be accessed at `localhost:5050`.

## Finishing touches

### Local K8s

To run our setup, we need a local Kubernetes cluster. While Tilt supports
remote clusters, we'll focus on local development for this guide.

I’m using [OrbStack] on MacOS for my local setup because I appreciate its
speed and simplicity. Other options include [Docker Desktop] or [Rancher
Desktop], which work for MacOS and Windows. These come with native
Kubernetes clusters you can utilize.

For Linux users, you won’t need a full Docker platform, so you might consider
using [Ctlptl] or [K3d] to run Kubernetes in Docker. Be aware that Tilt
requires a local registry to push images which can be a stumbling point for
new users. See the Tilt docs at
<https://docs.tilt.dev/personal_registry.html> for more details.

Whichever option you choose, make sure you are able to access the cluster with
kubectl and perform basic operations before proceeding.

[OrbStack]: https://orbstack.dev/
[Docker Desktop]: https://www.docker.com/products/docker-desktop/
[Rancher Desktop]: https://rancherdesktop.io/
[Ctlptl]: https://github.com/tilt-dev/ctlptl
[K3d]: https://k3d.io/stable/

### Configuring Local Hostnames

To fully utilize our ingress setup, we'll configure local hostnames using
[`hostctl`](https://guumaster.github.io/hostctl/). This allows us to access
our services using domain names like `foo.localhost` instead of IP addresses.

See the `.etchosts` at the root of the repo. This is where we define our mapping

```text
127.0.0.1   linkerd.localhost
127.0.0.1   foo.localhost
```

Then we can add and remove these records using the `hostctl` CLI.

```bash
sudo hostctl add tilt-linkerd-demo < .etchosts
```

Now when our app is deployed, we can reach it at `http://foo.localhost:5050`.

## Ready to launch

Now that we have all of that in place all we need to do is run Tilt.

```bash
tilt up
```

Tilt provides a powerful browser-based UI at where you can:

* Monitor the status of all your services
* View build and container logs in real-time
* Enable/disable specific services as needed
* Access direct links to your applications

Look for the information in the command output of `tilt up`.

## Next Steps

This setup provides a powerful foundation for local development that closely
mirrors your production environment. With everything running locally, you can:

* Test service mesh configurations in real-time
* Experiment with traffic routing and load balancing;
* Debug issues using actual infrastructure components; and
* Develop with confidence knowing your local environment closely matches production.

In the next section, we'll explore how to leverage these tools to better
understand and work with Linkerd, including advanced features like traffic
splitting and retry policies.
