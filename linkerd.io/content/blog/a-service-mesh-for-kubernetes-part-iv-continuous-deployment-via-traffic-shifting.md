---
slug: 'a-service-mesh-for-kubernetes-part-iv-continuous-deployment-via-traffic-shifting'
title: 'A Service Mesh for Kubernetes, Part IV: Continuous deployment via traffic shifting'
aliases:
  - /2016/11/04/a-service-mesh-for-kubernetes-part-iv-continuous-deployment-via-traffic-shifting/
author: 'sarah'
date: Fri, 04 Nov 2016 23:02:03 +0000
thumbnail: /uploads/kubernetes4_featured_Twitter_ratio.png
draft: false
featured: false
tags: [Linkerd, linkerd, News, tutorials]
---

**Updated (01-05-2018):** There is a new namerd.yml that now uses the CustomResourceDefinition API that was recently added in Kubernetes 1.8.

Beyond service discovery, top-line metrics, and TLS, Linkerd also has a powerful routing language, called *dtabs*, that can be used to alter the ways that requests—even individual requests—flow through the application topology. In this article, we’ll show you how to use Linkerd as a service mesh to do blue-green deployments of new code as the final step of a CI/CD pipeline.

Note: this post was co-written with [Kevin Lingerfelt](https://twitter.com/klingerf). This is one article in a series of articles about [Linkerd](https://linkerd.io/), [Kubernetes](http://kubernetes.io/), and service meshes. Other installments in this series include:

1. [Top-line service metrics]({{< ref
   "a-service-mesh-for-kubernetes-part-i-top-line-service-metrics" >}})
2. [Pods are great, until they’re not]({{< ref
   "a-service-mesh-for-kubernetes-part-ii-pods-are-great-until-theyre-not" >}})
3. [Encrypting all the things]({{< ref
   "a-service-mesh-for-kubernetes-part-iii-encrypting-all-the-things" >}})
4. [Continuous deployment via traffic shifting]({{< ref "a-service-mesh-for-kubernetes-part-iv-continuous-deployment-via-traffic-shifting" >}}) (this article)
5. [Dogfood environments, ingress, and edge routing]({{< ref "a-service-mesh-for-kubernetes-part-v-dogfood-environments-ingress-and-edge-routing" >}})
6. [Staging microservices without the tears]({{< ref "a-service-mesh-for-kubernetes-part-vi-staging-microservices-without-the-tears" >}})
7. [Distributed tracing made easy]({{< ref
   "a-service-mesh-for-kubernetes-part-vii-distributed-tracing-made-easy" >}})
8. [Linkerd as an ingress controller]({{< ref "a-service-mesh-for-kubernetes-part-viii-linkerd-as-an-ingress-controller" >}})
9. [gRPC for fun and profit]({{< ref
   "a-service-mesh-for-kubernetes-part-ix-grpc-for-fun-and-profit" >}})
10. [The Service Mesh API]({{< ref
    "a-service-mesh-for-kubernetes-part-x-the-service-mesh-api" >}})
11. [Egress]({{< ref "a-service-mesh-for-kubernetes-part-xi-egress" >}})
12. Retry budgets, deadline propagation, and failing gracefully
13. Autoscaling by top-line metrics

In previous installments of this series, we’ve shown you how you can use a service mesh like Linkerd to [capture top-line service metrics][part-i] and [transparently add TLS][part-iii] to your application, without changing application code.

In this article, we’ll show you an example of how to use Linkerd’s routing rules, called [dtabs](https://linkerd.io/in-depth/dtabs/), to automatically alter traffic flow through your application at the end of a CI/CD pipeline to perform a [blue-green deployment](http://martinfowler.com/bliki/BlueGreenDeployment.html) between old and new versions of a service.

Continuous deployment (CD) is an extension of continuous integration (CI), in which code is pushed to production on a continuous basis, tightly coupled to the development process. While it requires powerful automation, minimizing the time between development and deployment allows companies to iterate very rapidly on their product.

For multi-service or microservice architectures, the final step of the CD process, the deployment itself, can be risky because so much runtime behavior is determined by the runtime environment, including the other services that are handling production traffic. In these situations, gradual rollouts such as blue-green deployments become increasingly important.

Coordinating traffic shifting across multiple Linkerds requires a centralized traffic control tool. For this we recommend [namerd](https://linkerd.io/in-depth/namerd), a service with an API that serves routing rules backed by a consistent store. You can read more about how namerd integrates with production systems in our previous blog post covering [routing in linkerd](/2016/05/04/real-world-microservices-when-services-stop-playing-well-and-start-getting-real/#routing-in-linkerd).

We’ll demonstrate a blue-green deployment using an example app from the [linkerd-examples](https://github.com/linkerd/linkerd-examples/tree/master/docker/helloworld) Github repo. The example app is a contrived “hello world” microservice application, consisting a of “hello” service that handles incoming requests and calls a “world” service before returning a response. With Jenkins as our automation server, we’ll deploy a new version of the world service using the [Jenkins Pipeline Plugin](https://github.com/jenkinsci/pipeline-plugin).

## A Service Mesh for Kubernetes

Before we start continuously deploying, we’ll need to initially deploy the hello world app to Kubernetes, routing requests using Linkerd and namerd. We can do this easily by using the [Kubernetes configs](https://github.com/linkerd/linkerd-examples/tree/master/k8s-daemonset/k8s) in the linkerd-examples repo.

## STEP 1: INSTALL NAMERD

We’ll start by installing namerd, which will manage the dtabs that we use to orchestrate our blue-green deployments. Please note that our namerd configuration uses the [CustomResourceDefinition APIs](https://kubernetes.io/docs/tasks/access-kubernetes-api/extend-api-custom-resource-definitions/), which requires a cluster running Kubernetes 1.8+

Note: Prior to Kubernetes 1.8, Linkerd used the ThirdPartyResources API to store dtabs. The API has been deprecated in favor of the new CustomResourceDefinitions API.

To install namerd in the default Kubernetes namespace, run (Kubernetes 1.8+):

```bash
kubectl apply -f https://raw.githubusercontent.com/linkerd/linkerd-examples/master/k8s-daemonset/k8s/namerd.yml
```

If you are using Kubernetes  < 1.7, run

```bash
kubectl apply -f https://raw.githubusercontent.com/linkerd/linkerd-examples/master/k8s-daemonset/k8s/namerd-legacy.yml
```

You can confirm that installation was successful by viewing namerd’s admin page (note that it may take a few minutes for the ingress IP to become available):

```bash
NAMERD_INGRESS_LB=$(kubectl get svc namerd -o jsonpath="{.status.loadBalancer.ingress[0].*}")
open http://$NAMERD_INGRESS_LB:9991 # on OS X
```

Or if external load balancer support is unavailable for the cluster, use hostIP:

```bash
NAMERD_HOST_IP=$(kubectl get po -l app=namerd -o 'jsonpath={.items[0].status.hostIP}')
open http://$NAMERD_HOST_IP:$(kubectl get svc namerd -o 'jsonpath={.spec.ports[2].nodePort}') # on OS X
```

The admin page displays all configured namerd namespaces, and we’ve configured two namespaces—“external” and “internal”. For the sake of continuous deployment, we’re mostly concerned with the “internal” namespace.

In addition to the admin UI, we can also use the [namerctl](https://github.com/linkerd/namerctl) utility to talk directly to namerd. This utility will be used by the deploy script to start sending traffic to newly deployed services. To install it locally, run:

```bash
go get -u github.com/linkerd/namerctl go install github.com/linkerd/namerctl
```

The utility uses the `NAMERCTL_BASE_URL` environment variable to connect to namerd. In order to connect to the version of namerd that we just deployed to Kubernetes, set the variable as follows:

```bash
export NAMERCTL_BASE_URL=http://$NAMERD_INGRESS_LB:4180
```

Or to use hostIP directly:

```bash
export NAMERCTL_BASE_URL=http://$NAMERD_HOST_IP:$(kubectl get svc namerd -o 'jsonpath={.spec.ports[1].nodePort}')
```

And now try using `namerctl` to display the internal dtab:

```bash
$ namerctl dtab get internal
# version MjgzNjk5NzI=
/srv         => /#/io.l5d.k8s/default/http ;
/host        => /srv ;
/tmp         => /srv ;
/svc         => /host ;
/host/world  => /srv/world-v1 ;
```

The last line of the dtab maps the logical name of the `world` service to the currently deployed version of the world service, `world-v1`. In a production system, versions could be shas, dates, or anything else that guarantees name uniqueness. We’ll use this dtab entry to safely introduce new versions of the world service into production.

## STEP 2: INSTALL LINKERD

Next we’ll install Linkerd and configure it to resolve routes using namerd. To install Linkerd as a DaemonSet (i.e., one instance per host) in the default Kubernetes namespace, run:

```bash
kubectl apply -f https://raw.githubusercontent.com/linkerd/linkerd-examples/master/k8s-daemonset/k8s/linkerd-namerd.yml
```

You can confirm that installation was successful by viewing Linkerd’s admin UI (note that it may take a few minutes for the ingress IP to become available):

```bash
L5D_INGRESS_LB=$(kubectl get svc l5d -o jsonpath="{.status.loadBalancer.ingress[0].*}")
open http://$L5D_INGRESS_LB:9990 # on OS X
```

Or if external load balancer support is unavailable for the cluster, use hostIP:

```bash
L5D_HOST_IP=$(kubectl get po -l app=l5d -o 'jsonpath={.items[0].status.hostIP}')
open http://$L5D_HOST_IP:\$(kubectl get svc l5d -o 'jsonpath={.spec.ports[3].nodePort}') # on OS X
```

We’ll use the admin UI to verify steps of the blue-green deploy.

## STEP 3: INSTALL THE SAMPLE APPS

Now we’ll install the hello and world apps in the default namespace. These apps rely on the nodeName supplied by the [Kubernetes downward API](https://kubernetes.io/docs/tasks/inject-data-application/downward-api-volume-expose-pod-information/) to find Linkerd. To check if your cluster supports nodeName, you can run this test job:

```bash
kubectl apply -f https://raw.githubusercontent.com/linkerd/linkerd-examples/master/k8s-daemonset/k8s/node-name-test.yml
```

And then looks at its logs:

```bash
kubectl logs node-name-test
```

If you see an ip, great! Go ahead and deploy the hello world app using:

```bash
kubectl apply -f https://raw.githubusercontent.com/linkerd/linkerd-examples/master/k8s-daemonset/k8s/hello-world.yml
```

If instead you see a "server can't find ..." error, deploy the hello-world legacy version that relies on hostIP instead of nodeName:

```bash
kubectl apply -f https://raw.githubusercontent.com/linkerd/linkerd-examples/master/k8s-daemonset/k8s/hello-world-legacy.yml
```

At this point, we actually have a functioning service mesh and an application that makes use of it. You can see the entire setup in action by sending traffic through linkerd’s external IP:

```bash
curl $L5D_INGRESS_LB Hello (10.196.2.5) world (10.196.2.6)!!
```

Or to use hostIP directly:

<!-- markdownlint-disable MD014 -->
```bash
$ L5D_INGRESS_LB=$L5D_HOST_IP:$(kubectl get svc l5d -o 'jsonpath={.spec.ports[0].nodePort}')
$ curl $L5D_INGRESS_LB
Hello (10.196.2.5) world (10.196.2.6)!!
```
<!-- markdownlint-enable MD014 -->

If everything is working, you’ll see a “Hello world” message similar to that above, with the IPs of the pods that served the request.

## Continuous deployment

We’ll now use Jenkins to perform blue-green deploys of the “world” service that we deployed in the previous step.

### SETUP JENKINS

Let’s start by deploying the [buoyantio/jenkins-plus](https://hub.docker.com/r/buoyantio/jenkins-plus/) Docker image to our Kubernetes cluster. This image provides the base `jenkins` image, along with the `kubectl` and `namerctl` binaries that we need, as well as additional plugins and a pre-configured pipeline job that we can use to run deployments. The pipeline job makes use of the [Jenkins Pipeline Plugin](https://github.com/jenkinsci/pipeline-plugin) and a [custom Groovy script](https://gist.github.com/klingerf/14a78b3408eab0327b0de483dc174fbb) that handles each of the steps in the blue-green deploy for us.

To deploy the Jenkins image to the default Kubernetes namespace, run:

```bash
kubectl apply -f https://raw.githubusercontent.com/linkerd/linkerd-examples/master/k8s-daemonset/k8s/jenkins.yml
```

You can confirm that installation was successful by opening up the Jenkins web UI (note that it may take a few minutes for the ingress IP to become available):

```bash
JENKINS_LB=$(kubectl get svc jenkins -o jsonpath="{.status.loadBalancer.ingress[0].*}")
open http://$JENKINS_LB # on OS X
```

Or if external load balancer support is unavailable for the cluster, use hostIP:

```bash
JENKINS_HOST_IP=$(kubectl get po -l app=jenkins -o 'jsonpath={.items[0].status.hostIP}')
open http://$JENKINS_HOST_IP:$(kubectl get svc jenkins -o 'jsonpath={.spec.ports[0].nodePort}') # on OS X
```

You should see a “hello_world” job in the UI.

### COMMITTING CODE

Now it’s time to make some code changes to the world service, and have the Jenkins job deploy them to production for us. To do this, start by forking the [linkerd-examples](https://github.com/linkerd/linkerd-examples) repo in the Github UI. Once you’ve created a fork, clone your fork locally:

```bash
git clone https://github.com/esbie/linkerd-examples.git cd linkerd-examples
```

For the sake of this example, we’re going to change a text file that controls the output of the world service. By default, the world service outputs the string “world”:

```bash
cat k8s-daemonset/helloworld/world.txt world
```

Let’s spice that up a bit:

```bash
echo "hal, open the pod bay doors" > k8s-daemonset/helloworld/world.txt
```

And commit it:

```bash
git commit -am "Improve the output of the world service" git push origin master
```

Now it’s time to get this critical change into production.

### RUNNING THE JOB

With our change committed and pushed to our fork of the `linkerd-examples` repo, we can kick off the Jenkins “hello_world” pipeline job to safely deploy the change into production. Each of the 6 steps in the pipeline job is controlled by a [custom Groovy script](https://gist.github.com/klingerf/14a78b3408eab0327b0de483dc174fbb) and described below in more detail. The deploy is fully automated, with the exception of three places in the pipeline where it pauses for human-in-the-loop verification of critical metrics before proceeding.

#### BUILD WITH PARAMETERS

To start the deploy, click into the “hello_world” job in the Jenkins UI, and then click “Build with the parameters” in the sidebar. You’ll be taken to a page that lets you customize the deploy, and it will look something like this:

{{< fig
  alt="pipeline hello world"
  title="pipeline hello world"
  src="/uploads/2017/07/buoyant-pipeline-build-parameters.png" >}}

Change the value of the `gitRepo` form field to point to your fork of the `linkerd-examples` repo, and then click the “Build” button. Note that if you pushed your changes to a separate branch in your fork, you should also change the value of the `gitBranch`form field to match your branch name.

#### CLONE

The first step in the pipeline is to clone the git repo using the build parameters specified above. Pretty straightforward.

#### DEPLOY

The second step in the deploy pipeline is to actually deploy the new version of the world service to our cluster, without sending it any traffic. The script determines that the currently deployed version of the world service is `world-v1`, so it creates a new service called `world-v2` and deploys that to our Kubernetes cluster. At this point you will see two different versions of the world service running simultaneously:

```bash
$ kubectl get po | grep world
world-v1-9eaxk                1/1       Running   0          3h
world-v1-kj6gi                1/1       Running   0          3h
world-v1-vchal                1/1       Running   0          3h
world-v2-65y9g                1/1       Running   0          30m
world-v2-d260q                1/1       Running   0          30m
world-v2-z7ngo                1/1       Running   0          30m
```

Even with the `world-v2` version fully deployed, we still have not made any changes to production traffic! Linkerd and namerd are still configured to route all world service traffic to the existing `world-v1` version. Fully deploying a new version of the service before sending it any traffic is key to performing a blue-green deploy.

#### INTEGRATION TESTING

Once the new version of our service is deployed, the script performs a test request to make sure the new version can be reached. If the test request succeeds, it pauses the deploy and waits for us to acknowledge that the newly deployed version looks correct before proceeding.

{{< fig
  alt="Stage View"
  title="Stage View"
  src="/uploads/2017/07/buoyant-pipeline-integration-testing.png" >}}

At this point, we want to make sure that the new pods are running as expected—not just by themselves, but in conjunction with the rest of the production environment. Normally this would involve a deployment to a separate staging cluster, combined with some mechanism for sending or replaying production traffic to that cluster.

Since we’re using Linkerd, we can significantly simplify this operation by taking advantage of Linkerd’s [per-request routing](https://linkerd.io/features/routing/#per-request-routing) to accomplish the same thing without a dedicated staging environment. At ingress, we can tag our request with a special header, `l5d-dtab`, that will instruct Linkerd to route this request through the production cluster, but replace all service calls to `world-v1` with calls to `world-v2` instead *for this request only*.

The Jenkins UI provides the dtab override that we need to route requests to the new version of our service, and using that information we can make our own test request:

```bash
$ curl -H 'l5d-dtab: /host/world => /tmp/world-v2' $L5D_INGRESS_LB
Hello (10.196.2.5) hal, open the pod bay doors (10.196.1.17)!!
```

Success! Our request is being routed to the `world-v2` service, which is returning the new world text that we added on our branch. Even though we can reach the new service, it’s worth noting that we *still* have not changed the behavior of any production traffic, aside from the request that we just made. We can verify that by omitting the `l5d-dtab` header and ensuring that we still get the `world-v1` response:

```bash
$ curl $L5D_INGRESS_LB
Hello (10.196.2.5) world (10.196.2.6)!!
```

If everything looks good, we can proceed to the next step in the pipeline by clicking the “Ok, I’m done with manual testing” button in the Jenkins UI.

#### SHIFT TRAFFIC (10%)

After some manual testing, we’re ready to start the blue-green deployment by sending 10% of production traffic to the newly deployed version of the service. The script makes the change in routing policy and again pauses, asking us to confirm that everything looks OK with 10% traffic before proceeding.

{{< fig
  alt="Stage View"
  title="Stage View"
  src="/uploads/2017/07/buoyant-pipeline-shift-traffic-10.png" >}}

Note that if the user aborts on any pipeline step, the script assumes there was something wrong with the new service, and automatically reverts the routing change, sending all traffic back to the original service. Since we’re not tearing down instances of the old version of the service while shifting traffic, reverting traffic back can happen quickly, minimizing the impact of a bad deploy.

We can verify that our service is taking 10% of requests by sending it 10 requests and hoping that the odds are in our favor:

```bash
$ for i in {1..10}; do curl $L5D_INGRESS_LB; echo ""; done
Hello (10.196.2.5) world (10.196.1.16)!!
Hello (10.196.2.5) world (10.196.1.16)!!
Hello (10.196.2.5) hal, open the pod bay doors (10.196.2.13)!!
Hello (10.196.2.5) world (10.196.2.6)!!
Hello (10.196.1.13) world (10.196.2.6)!!
Hello (10.196.1.13) world (10.196.2.6)!!
Hello (10.196.2.5) world (10.196.1.16)!!
Hello (10.196.2.5) world (10.196.2.6)!!
Hello (10.196.1.14) world (10.196.2.6)!!
Hello (10.196.1.14) world (10.196.1.16)!!
```

Looking good! Now is also a good time to check Linkerd’s admin dashboard, to verify that the new service is healthy. If your application were receiving a small amount of steady traffic, then the dashboard would look like this:

{{< fig
  alt="Dashboard"
  title="Dashboard"
  src="/uploads/2017/07/buoyant-pipeline-admin-large-1024x737.png" >}}

We can see right away that the `world-v2` service is taking roughly 10% of traffic, with 100% success rate. If everything looks good, we can proceed to the next step by clicking the “Ok, success rates look stable” button in the Jenkins UI.

#### SHIFT TRAFFIC (100%)

In this step the script shifts additional traffic to the new version of our service. For a concise example, we’re moving immediately to 100% of traffic, but in a typical deployment you could include additional intermediary percentages as separate steps in the pipeline.

{{< fig
  alt="Stage View"
  title="Stage View"
  src="/uploads/2017/07/buoyant-pipeline-shift-traffic-100.png" >}}

We can verify that the new service is serving traffic by sending it a request without a dtab override header:

```bash
$ curl $L5D_INGRESS_LB
Hello (10.196.2.5) hal, open the pod bay doors (10.196.2.13)!!
```

Once we’re confidant that `world-v2` is successfully handling 100% of production traffic, we can proceed to the final step by clicking the “Ok, everything looks good” button in the Jenkins UI.

#### CLEANUP

In the final step, the script finalizes the deploy by making the routing rules to route traffic to the new version of the service permanent. It also tears down the previous version of the service that was still running in our cluster but not receiving any traffic.

{{< fig
  alt="cleanup"
  title="cleanup"
  src="/uploads/2017/07/buoyant-pipeline-cleanup.png" >}}

The final version of namerd’s dtab is now:

```bash
$ namerctl dtab get internal
# version MTIzMzU0OTE=
/srv         => /#/io.l5d.k8s/default/http ;
/host        => /srv ;
/tmp         => /srv ;
/http/*/*    => /host ;
/host/world  => /srv/world-v2 ;
```

We can verify that the old service has been torn down by looking at the world service pods that are currently deployed to our cluster.

```bash
$ kubectl get po | grep world
world-v2-65y9g                1/1       Running   0          1h
world-v2-d260q                1/1       Running   0          1h
world-v2-z7ngo                1/1       Running   0          1h
```

Everything looks good. Kicking off a subsequent pipeline job will deploy a `world-v3`version of the service, gradually shift traffic over, and then promote it to the current version when the deploy successfully completes.

## Conclusion

In this post, we’ve shown a basic workflow incorporating Linkerd, namerd, and Jenkins to progressively shift traffic from an old version to a new version of a service as the final step of a continuous deployment pipeline. We’ve shown how Linkerd’s ability to do per-request routing actually lets us stage the new version of the service without needing a separate staging cluster, by using the `l5d-dtab` header to stitch the new service into the production topology *just for that request*. Finally, we’ve shown how percentage-based traffic shifting can be combined with a Jenkins `input` step to allow for human-in-the-loop verification of metrics as traffic moves from 0% to 100%.

This was a fairly simple example, but we hope it demonstrates the basic pattern of using service mesh routing for continuous deployment and provides a template for customizing this workflow for your own organization. For help with dtabs or anything else about Linkerd, feel free to stop by the [Linkerd Support Forum](https://linkerd.buoyant.io/), [Linkerd community Slack](http://slack.linkerd.io/), or [contact us directly](https://linkerd.io/overview/help/)!

[part-i]: {{< ref "a-service-mesh-for-kubernetes-part-i-top-line-service-metrics" >}} [part-ii]: {{< ref "a-service-mesh-for-kubernetes-part-ii-pods-are-great-until-theyre-not" >}} [part-iii]: {{< ref "a-service-mesh-for-kubernetes-part-iii-encrypting-all-the-things" >}} [part-iv]: {{< ref "a-service-mesh-for-kubernetes-part-iv-continuous-deployment-via-traffic-shifting" >}} [part-v]: {{< ref "a-service-mesh-for-kubernetes-part-v-dogfood-environments-ingress-and-edge-routing" >}} [part-vi]: {{< ref "a-service-mesh-for-kubernetes-part-vi-staging-microservices-without-the-tears" >}} [part-vii]: {{< ref "a-service-mesh-for-kubernetes-part-vii-distributed-tracing-made-easy" >}} [part-viii]: {{< ref "a-service-mesh-for-kubernetes-part-viii-linkerd-as-an-ingress-controller" >}} [part-ix]: {{< ref "a-service-mesh-for-kubernetes-part-ix-grpc-for-fun-and-profit" >}} [part-x]: {{< ref "a-service-mesh-for-kubernetes-part-x-the-service-mesh-api" >}} [part-xi]: {{< ref "a-service-mesh-for-kubernetes-part-xi-egress" >}}
