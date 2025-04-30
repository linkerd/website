---
date: 2023-05-26T00:00:00Z
title: Migrating from OpenServiceMesh to Linkerd
keywords: [linkerd, OpenServiceMesh]
params:
  author: flynn
  showCover: true
---

You've read the Open Service Mesh team's announcement that
[OSM will be archived and no further OSM releases will be published](https://openservicemesh.io/blog/osm-project-update/),
and you've seen that Linkerd is
[welcoming OSM adopters to Linkerd with open arms](0505-welcome-osm)...
now what? What does it look like to migrate from OSM to Linkerd?

Any time you look at migrating meshes, there are two main challenges:

1. Obviously, you configure different meshes in different ways. When going from
   OSM to Linkerd, you need to translate the SMI resources used for OSM's
   configuration to the Linkerd (or Gateway API) resources that Linkerd wants.
   This is straightforward for some resources, and less straightforward for
   others.

2. Additionally, since OSM and Linkerd are both sidecar meshes, you can't have a
   single workload be in both at the same time: both sidecars want to intercept
   network traffic, and only one of them gets to win. This means that the
   overall strategy for the migration can be a bit more complex than we'd like.

Let's take these one at a time.

## Configuration

OpenServiceMesh is configured with SMI resources. If you're running any
nontrivial OSM configuration, you'll need to translate resources -- here are
some of the high points to think about.

### Mesh Basics

Like Linkerd, OSM uses a mutating admission webhook to handle actually injecting
its sidecar into workloads, and has no separate CRD describing workloads to mesh
-- conveniently, this means there's little work to do here as far as
configuration is concerned.

_Unlike_ Linkerd, OSM uses its MeshConfig resource to configure a lot of details
about the mesh itself.

- Some of these details are handled differently in Linkerd. - The sidecar log
  level and init container strategy, for example, are set with workload
  annotations or environment variables in Linkerd, rather than globally. -
  Tracing is handled by the `linkerd-jaeger` extension, rather than being
  configured globally.

- Some details simply don't apply directly to Linkerd. - OSM's ingress and
  egress settings are likely best handled with Kubernetes NetworkPolicy
  resources in Linkerd. - Linkerd and OSM handle workload certificates rather
  differently, so OSM's certificate validity settings don't correspond directly
  to any Linkerd setting.

### Ingress

OSM uses its IngressBackend resource to specifically describe which traffic will
be allowed to flow from an ingress controller to workloads within the mesh.
Linkerd, instead, prefers to handle the ingress controller by having the ingress
controller participate fully in the mesh: you should inject the ingress
controller into the mesh, then use Linkerd's normal mechanisms to control
access.

### SMI Traffic Handling

Beyond the basics of getting workloads participating in the mesh, another common
function of OSM is traffic handling. OSM uses SMI resources for this, notably
the TrafficSplit and TrafficTarget resources.

#### TrafficSplit

Linkerd supports the TrafficSplit resource via the `linkerd-smi` extension. Once
this is installed, you should find that TrafficSplit resources function
basically the same between the two meshes, generally permitting easy migration
for this function.

As of Linkerd 2.13, you can also use HTTPRoute resources for traffic splitting.
This will be a better option for the long run, although it will (of course)
require rewriting your TrafficSplit resources using HTTPRoutes with weights.

#### TrafficTarget and HTTPRouteGroup

The TrafficTarget resource works with HTTPRouteGroup resources to allow you to
define access policies and traffic permissions for specific workloads. In
Linkerd, this is best expressed using Server, HTTPRoute, and AuthorizationPolicy
resources (note that this requires at least Linkerd 2.12).

In SMI, TrafficTargets use associated HTTPRouteGroup resources to define
traffic-matching rules. As an example, consider the following OSM configuration:

```yaml
# This is an OSM configuration allowing a workload using the "website"
# ServiceAccount to access APIs on the "user" workload behind the `/users`
# Path prefix.
#
# Start by defining an HTTPRouteGroup for the path prefix.
---
kind: HTTPRouteGroup
metadata:
  name: user-routes
spec:
  matches:
    - name: users-match
      pathRegex: /users
      methods: ["*"]

# Then define a TrafficTarget that uses it.
---
kind: TrafficTarget
metadata:
  name: user-target
  namespace: default
spec:
  destination:
    kind: ServiceAccount
    name: users
    namespace: default
    port: 8080
  rules:
    - kind: HTTPRouteGroup
      name: user-routes
      matches:
        - users-match
  sources:
    - kind: ServiceAccount
      name: website-service
      namespace: default
```

The HTTPRouteGroup defines one or more sets of HTTP matches (we're just using
one here). The TrafficTarget defines:

- `sources`, which in this example define which ServiceAccounts may originate
  traffic through this TrafficTarget;
- `rules`, which select the HTTPRouteGroup matching rules that must match for
  traffic to be allowed through thisthis TrafficTarget; and
- a `destination`, which selects the ServiceAccount of the workload(s) to which
  this TrafficTarget may pass traffic.

In Linkerd, we use a Server to define the destination, HTTPRoutes to describe
the rules, and an AuthorizationPolicy with MeshTLSAuthentications to describe
the sources:

```yaml
# This is an Linkerd configuration allowing a workload using the "website"
# ServiceAccount to access APIs on the "user" workload behind the `/users`
# Path prefix.
#
# We start by defining a Server that matches the Pods and ports for our
# destination workload. This Server covers all Pods with the
# `app: user-workload` label, on the HTTP port.
---
apiVersion: policy.linkerd.io/v1beta1
kind: Server
metadata:
  name: user-server
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: user-workload
  port: http

# Next, we define an HTTPRoute to describe which paths we'll allow through.
---
kind: HTTPRoute
metadata:
  name: user-routes
  namespace: default
spec:
  parentRefs:
    - name: user-server
      kind: Server
      group: policy.linkerd.io
  rules:
    - matches:
        - path:
          value: /users

# Finally, we use a MeshTLSAuthentication and an AuthorizationPolicy to
# define what workload identity is allowed to use the HTTPRoute.
---
apiVersion: policy.linkerd.io/v1alpha1
kind: MeshTLSAuthentication
metadata:
  name: website-authn
  namespace: default
spec:
  identities:
    - "website.default.serviceaccount.identity.linkerd.cluster.local"
---
apiVersion: policy.linkerd.io/v1alpha1
kind: AuthorizationPolicy
metadata:
  name: users-policy
  namespace: default
spec:
  targetRef:
    group: policy.linkerd.io
    kind: HTTPRoute
    name: users-routes
  requiredAuthenticationRefs:
    - name: website-authn
      kind: MeshTLSAuthentication
      group: policy.linkerd.io
```

While Linkerd does require more CRDs, it's also more likely that you'll be able
to reuse some resources across multiple routes or AuthorizationPolicies (for
example, a single AuthorizationPolicy can allow access from multiple
MeshTLSAuthentications, and multiple HTTPRoutes can be associated with multiple
Servers).

#### Other Resources

Of course, some OSM resources currently have no direct equivalent in Linkerd.
For example, since Linkerd focuses on layer 7 traffic, it has no equivalent for
OSM's TCPRoute. Likewise, OSM's Egress resource has no direct Linkerd equivalent
(though, again, Kubernetes NetworkPolicy resources may help here).

## Migration Strategies

Given this context on configuration translation, let's look at migration
strategies.

### 1. Forklift Migration

The simplest strategy is definitely the so-called forklift migration: rip out
OSM, install Linkerd, and rebuild whatever parts of your configuration are
important to you. This is a strategy that everyone is quick to dismiss, but if
you primarily use OSM for mTLS, and if you can schedule downtime, this might
actually be all you need.

- Schedule downtime.
- Uninstall OSM.
- Install Linkerd.
- Wherever you have the `openservicemesh.io/sidecar-injection: enabled`
  annotation, add the `linkerd.io/inject: enable` annotation and restart the
  relevant deployments.
- Test!
- Release downtime.

Obviously, taking downtime for a migration isn't ideal, but this strategy can be
far and away the simplest way to handle everything.

### 2. Workload by Workload

While a given workload can't be part of both meshes at the same time, it _is_
possible to install Linkerd in the same cluster with OSM, then move workloads
from OSM to Linkerd one at a time. This approach can allow for a straightforward
zero-downtime migration:

- Create any Linkerd configuration needed to allow the workload being migrated
  to work with Linkerd
- Replace the `openservicemesh.io/sidecar-injection: enabled` annotation on the
  Deployment of the workload being migrated with the `linkerd.io/inject: enable`
  annotation
- Restart the workload's Pods

This method preserves uptime by allowing workloads to continue communicating
with each other throughout the whole process, and by taking advantage of
Kubernetes' ability to restart a workload without downtime as long as the
workload has multiple replicas.

With this method, it's important to realize that in situations where a workload
running under OSM needs to communicate with a workload running under Linkerd (in
either direction), **this communication will be cleartext** rather than using
mTLS. This implies that OSM needs to be operating in permissive mode, and that
Linkerd can't fully lock down communications until after the migration is
finished. If your application can work with this constraint, though, the
workload-by-workload method can be a simple way to migrate without downtime.

### 3. Separate Clusters

Finally, the _safest_ migration strategy is to use a completely separate cluster
to bring up your application with Linkerd. This removes any possibility of your
Linkerd installation confusing OSM (or vice versa), and can also permit
zero-downtime migration.

- Bring up a separate cluster.
- Install Linkerd into the new cluster.
- Install your application into the new cluster, including configuring Linkerd
  as needed.
- Test your application in the new cluster.
- Use a canary or A/B model to shift traffic to the new cluster.
- Decommission the old cluster.

On the face of it, canarying entire clusters can seem daunting: however, it can
be easier than it may seem.

- One option is to use the old cluster's ingress controller: match a path prefix
  of `/` to redirect some fraction of traffic across the network to the new
  cluster's ingress controller. When you're satisfied that all is working, swing
  the DNS from the old ingress controller to the new.

  This method is very simple and can work very well with many ingress
  controllers. It obviously incurs some latency and extra network traffic; it's
  important to use an HTTP `Redirect` rather than simply routing to reduce these
  effects.

- If your application is already using a CDN, your CDN may be able to assist
  here.

- If all else fails, you can use DNS round-robin routing for a form of canary
  rollout: use an A record with multiple IP addresses, and change the number of
  replicas of each IP address.

  For example, if you start with 10 copies of the IP address of the old ingress
  controller, then change one at a time to the IP address of the new ingress
  controller, you can shift traffic 10% at a time. It's not perfect, but it's an
  option.

## Going Forward

Obviously, a single blog post can't capture all the nuances of migrating from
one service mesh to another: our goal here is primarily to give some advice and
point out some things to be aware of. Fully understanding your OSM
configuration, and thinking up front about your migration strategy - including
how to test as you go! - will be critical.

You needn't go this alone, either! The folks on
[the Linkerd OSS Slack](https://slack.linkerd.io/) are always around to help,
and you can also check out the [Linkerd forum](https://linkerd.buoyant.io) for
more information. Additionally, there's a hands-on
[enterprise migration for OSM existing OSM adopters](https://buoyant.io/blog/announcing-enterprise-migration-for-open-service-mesh-customers)
offered by Buoyant, the creators of Linkerd; other commercial Linkerd providers
may offer something similar. Whatever route you take for migration, we look
forward to hearing from you -- welcome!
