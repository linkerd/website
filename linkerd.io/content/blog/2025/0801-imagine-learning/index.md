---
date: 2025-08-01T00:00:00Z
slug: imagine-learning-linkerd
aliases:
  - /2025/08/01/linkerd-edge-release-roundup
title: |-
  Innovating with a Rock-Solid Foundation While Saving 40% on Networking Costs: Imagine Learning's Journey with Linkerd
description: |-
  How Imagine Learning uses Linkerd to deliver reliable, secure, and scalable educational solutions while reducing networking costs by 40%.
keywords: [linkerd, HAZL, buoyant, imagine learning, service mesh, cloud-native]
params:
  author:
    name: Blake Romano, Senior Software Engineer, Imagine Learning
    avatar: blake-romano.jpg
    email: blake@imaginelearning.com
  showCover: true
images: [social.jpg] # Open graph image
---

At [Imagine Learning](https://www.imaginelearning.com/), we strive to empower
educators and inspire breakthrough moments for over 18 million students across
the United States. As a digital-first education solutions provider, our mission
is to deliver robust, reliable, and secure experiences to support the boundless
potential of K-12 learners. Achieving this at scale—spanning hundreds of
thousands of daily users—requires a technical foundation as innovative as our
products.

To meet these demands, our engineering team has embraced modern cloud-native
technologies. The cornerstone of our infrastructure is
[Linkerd](https://linkerd.io/), supported by [Buoyant](https://www.buoyant.io/),
running on Amazon's Elastic Kubernetes Service (EKS). Linkerd gives us the
critical capabilities that we need to scale effortlessly while maintaining the
performance and reliability that our users depend on.

## Delivering Reliability and Security at Scale

Our users—students and educators—depend on fast, reliable, and secure access to
our digital tools. Dropped traffic, slow load times, or security issues in the
face of ever-evolving threats would disturb the user experience, potentially
leading to customer churn. For that reason, reliability and security are a top
priority for Imagine Learning. As our platform grew to include hundreds of
microservices deployed across several Kubernetes clusters on AWS EKS, managing
communications at scale to avoid these problems became extremely challenging. We
needed a solution that would:

- Encrypt traffic seamlessly.
- Simplify service-to-service communication.
- Provide deep observability into application-layer (L7) networking.

In short, we needed a service mesh.

## Linkerd: Opting for Simplicity, Performance, and Security

After evaluating multiple service mesh options, Linkerd stood out due to its
simplicity, performance, and security. Unlike other solutions, Linkerd uses a
tiny
[Rust-based sidecar microproxy](/2020/07/23/under-the-hood-of-linkerds-state-of-the-art-rust-proxy-linkerd2-proxy/),
offering a small compute footprint, significantly reduced CVEs, and enhanced
overall security. Linkerd’s ease of configuration allowed us to deploy it
reliably and scale it within hours, enabling our team to focus on delivering
value to our customers.

Additionally,
[Buoyant Cloud](https://docs.buoyant.io/buoyant-cloud/getting-started/what-data-does-buoyant-cloud-collect/)
has amplified Linkerd’s capabilities by providing real-time metrics and
intuitive alerting. This ensures that our operations team can swiftly diagnose
and resolve issues, maintaining an exceptional user experience.

## Building a Scalable and Observable Platform

Our engineering team integrated Linkerd with several other CNCF tools to create
a robust platform:

- **Argo CD:** Enables GitOps workflows, ensuring consistent deployment of
  Linkerd across all clusters.
- **Argo Rollouts:** Enable us to roll out to customers progressively using
  Linkerd’s Gateway API Integration informed by metrics.

![Linkerd Architecture](Linkerd%20Architecture.jpg)

We started the implementation by adopting the
[GitOps](https://glossary.cncf.io/gitops/) mindset: our Kubernetes manifests are
stored in Git, and we use [Argo](https://argoproj.github.io/) CD to deploy
resources into our Kubernetes clusters. Argo CD manages Linkerd, Argo Rollouts,
the microservices our application teams build, and the other components needed
for our platform. Additionally,
[Buoyant Enterprise for Linkerd](https://www.buoyant.io/linkerd-enterprise)
provides a simple Helm chart to deploy its lifecycle Operator, which makes it
easy to manage our Linkerd deployments with a single custom resource. Once
deployed, all meshed pods were automatically mTLSed!

Next, we started leveraging the [Gateway API](https://gateway-api.sigs.k8s.io/)
in our environment to use Argo Rollouts with their Gateway API plugin. We now
use Argo Rollouts for canary deployments, enabling controlled rollout of new
application versions to our customers: Linkerd seamlessly changes the amount of
traffic going to the new version based on Argo Rollouts’ instructions, and Argo
Rollouts uses Linkerd’s HTTP metrics to understand whether a rollout is going
successfully. This allows us to minimize the impact customers could experience
due to a release deficiency.

Together, these tools in this architecture allow us to maintain a highly
observable and manageable Kubernetes environment. With Linkerd,
service-to-service communication is secure and reliable, while Buoyant Cloud’s
metrics enable proactive performance management.

## Transformational Gains

The adoption of Linkerd has yielded significant technological and business
benefits:

- **Reduced Operational Overhead by 20%:** By streamlining service mesh
  management, we’ve cut the time spent on operational tasks by a substantial
  margin.
- **Enhanced Efficiency:** Linkerd’s lightweight design reduced the compute
  requirements of our service mesh by over 80% compared to our previous service
  mesh implementation.
- **Reduce Costs:** Buoyant Enterprise for Linkerd’s High Availability Zone Load
  Balancing with Linkerd is on track to reduce our regional data transfer
  networking costs by at least 40%.
- **Improved Reliability:** Real-time observability ensures rapid issue
  resolution, translating to better user experiences and fewer disruptions.
- **Improved Security:** Linkerd has reduced the amount of service mesh-related
  CVEs we have been exposed to by 97% in 2024.

On a personal level, these improvements mean fewer fire drills for our
engineers, allowing them to focus on innovation.

## Looking Ahead

As we continue to scale, Imagine Learning remains committed to leveraging
cloud-native technologies like Linkerd to deliver exceptional educational
experiences. With a solid foundation on AWS EKS, powered by the reliability and
support of Buoyant and Linkerd, we are poised to inspire breakthrough moments
for millions of students every day.
