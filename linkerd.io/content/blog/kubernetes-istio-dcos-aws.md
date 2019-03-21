---
title: 'Istio on Kubernetes on Mesos on AWS: it''s turtles all the way down'
author: 'andrew'
date: Tue, 19 Sep 2017 18:45:38 +0000
draft: true
tags: [aws, dcos, istio, kubernetes, Linkerd, News, tutorials]
---

Our friends at Mesosphere recently announced [Kubernetes support for DC/OS](https://mesosphere.com/blog/kubernetes-dcos/). As big fans of Kubernetes, Mesos, and Istio, the natural question in our minds was: does this mean we can run Istio on Mesos already? As in, today? This isn't just a thought exercise. A big part of Buoyant's mission is to bring service mesh infrastructure to companies around the world, not just those running Kubernetes. We recently announced [Linkerd Istio support](https://buoyant.io/2017/07/11/linkerd-istio/), and are heavily invested in bringing the service mesh to everyone. The tl;dr is: yes, you can run Istio on Mesos this way. Though it would be pretty silly to call this a full-fledged "Istio for Mesos" solution, in an upcoming blog post we'll show how you can use Linkerd to bridge DC/OS and Kubernetes and make this a bit more realistic of a scenario.

## Let's get going!

As an introductory step, this post will guide you through the process of spinning up a fresh DC/OS cluster in AWS. We will then deploy Kubernetes on top and use it to set up the Istio service mesh. The following steps assume you have the AWS CLI installed. For more information consult the [AWS CLI documentation](https://aws.amazon.com/cli/).

## Deploy DC/OS

First we need to set up DC/OS on AWS. To do this, deploy the default configuration with a single master. For full details on deploying DC/OS, have a look at the [DC/OS installation documentation](https://dcos.io/install/). Download the official DC/OS CloudFormation template:

curl -s -o /tmp/single-master.cloudformation.json \
 https://s3-us-west-2.amazonaws.com/downloads.dcos.io/dcos/stable/commit/e38ab2aa282077c8eb7bf103c6fff7b0f08db1a4/cloudformation/single-master.cloudformation.json

Set your AWS Keypair, and deploy the CloudFormation template. We set SlaveInstanceCount to 7 because Kubernetes needs more resources than the standard 5 instance configuration. Alternatively you could deploy DC/OS on instances larger than the default m3.xlarge.

AWS_KEYPAIR=

aws cloudformation deploy \
 --template-file /tmp/single-master.cloudformation.json \
 --stack-name istio-k8s-dcos-aws \
 --parameter-overrides KeyName=\$AWS_KEYPAIR SlaveInstanceCount=7 \
 --capabilities CAPABILITY_IAM

Once fully deployed, retrieve the hostname for the DC/OS master, and use that to configure your DC/OS CLI.

DCOS_URL=$(aws cloudformation describe-stacks --stack-name istio-k8s-dcos-aws | jq -r '.Stacks\[0\].Outputs\[\] | select(.OutputKey=="DnsAddress") | .OutputValue')
open https://$DCOS_URL # osx only \# select 'Install CLI' from the DC/OS web ui

## Deploy Kubernetes

Next, setup Kubernetes on your new DC/OS cluster. For more information on running Kubernetes on DC/OS have a look at the [Quickstart guide for Kubernetes on DC/OS](https://github.com/mesosphere/dcos-kubernetes-quickstart). Start by installing the beta-kubernetes package from the DC/OS catalog.

dcos package install --yes beta-kubernetes

You can then see all the Kubernetes deploy tasks running in DC/OS. ![](https://buoyant.io/wp-content/uploads/2017/09/Screen-Shot-2017-09-14-at-11.20.47-AM.png) Once the Kubernetes deployment is complete, you'll need to configure `kubectl` to connect to it. Since the Kubernetes package installs onto private DC/OS nodes, we need to tunnel through our DC/OS master to reach it. First, get the Public IP of your DC/OS master.

LB_NAME=$(aws elb describe-load-balancers | jq -r ".LoadBalancerDescriptions\[\] | select(.DNSName==\\"$DCOS_URL\\") | .LoadBalancerName") INSTANCE_ID=$(aws elb describe-instance-health --load-balancer-name $LB_NAME | jq -r .InstanceStates\[0\].InstanceId) PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID | jq -r .Reservations\[0\].Instances\[0\].PublicIpAddress)

Now, start a tunnel on localhost:9000 through the DC/OS master to the Kubernetes API server, and then configure `kubectl`.

ssh -N -L 9000:apiserver-insecure.kubernetes.l4lb.thisdcos.directory:9000 core@\$PUBLIC_IP

\# configure kubectl kubectl config set-cluster dcos-k8s --server=http://localhost:9000 kubectl config set-context dcos-k8s --cluster=dcos-k8s --namespace=default kubectl config use-context dcos-k8s

Confirm the cluster is operational.

\$ kubectl get nodes NAME STATUS AGE VERSION kube-node-0-kubelet.kubernetes.mesos Ready 17m v1.7.5 kube-node-1-kubelet.kubernetes.mesos Ready 17m v1.7.5 kube-node-2-kubelet.kubernetes.mesos Ready 17m v1.7.5

\$ kubectl --all-namespaces=true get all NAMESPACE NAME CLUSTER-IP EXTERNAL-IP PORT(S) AGE default svc/kubernetes 10.100.0.1 443/TCP 19m

The beta-kubernetes package in DC/OS does not include kube-dns or the kubernetes-dashboard.  Add those now.

\# install kube-dns kubectl create -f https://raw.githubusercontent.com/mesosphere/dcos-kubernetes-quickstart/master/add-ons/dns/kubedns-cm.yaml kubectl create -f https://raw.githubusercontent.com/mesosphere/dcos-kubernetes-quickstart/master/add-ons/dns/kubedns-svc.yaml kubectl create -f https://raw.githubusercontent.com/mesosphere/dcos-kubernetes-quickstart/master/add-ons/dns/kubedns-deployment.yaml

\# install kubernetes-dashboard kubectl create -f https://raw.githubusercontent.com/mesosphere/dcos-kubernetes-quickstart/master/add-ons/dashboard/kubernetes-dashboard.yaml open http://localhost:9000/ui # osx only

You now have a fully functional Kubernetes deployment on your DC/OS cluster. ![](https://buoyant.io/wp-content/uploads/2017/09/Screen-Shot-2017-09-14-at-11.32.14-AM.png)

## Deploy Istio

With a fully functional Kubernetes cluster, you can now setup Istio. You will need to make some modifications to Istio that are specific to DC/OS. There's currently a known issue with the beta-kubernentes DC/OS package not supporting service accounts. By default, the Istio components use service accounts to find and connect to the Kubernetes API Server. As a workaround, you need to provide modified versions of Istio and Kubernetes (sample) app configs that include a `kubeconfig` file containing instructions for how our components connect to Kubernetes.

### kubeconfig file, defined in our istio ConfigMap object

kubeconfig: |- apiVersion: v1 kind: Config preferences: {} current-context: dcos-k8s

clusters: \- cluster: server: http://apiserver-insecure.kubernetes.l4lb.thisdcos.directory:9000 name: dcos-k8s

contexts: \- context: cluster: dcos-k8s namespace: default user: "" name: dcos-k8s

### Modified Kubernetes config to load a kubeconfig file

spec: containers: \- name: proxy image: docker.io/istio/proxy_debug:0.1.6 args: \["proxy", "egress", "-v", "2", "--kubeconfig", "/etc/istio/config/kubeconfig"\] volumeMounts: \- name: "istio" mountPath: "/etc/istio/config" readOnly: true volumes: \- name: istio configMap: name: istio

These instructions are based on the [Istio installation instructions](https://istio.io/docs/tasks/installing-istio.html). First, download the Istio install files.

curl -L https://git.io/getIstio | sh - cd istio-0.1.6

Now deploy Istio, metrics collection, and a sample app onto your Kubernetes cluster.

\# set up istio service account permissions kubectl apply -f install/kubernetes/istio-rbac-beta.yaml

\# deploy istio, with modified kubeconfig file kubectl apply -f https://raw.githubusercontent.com/linkerd/linkerd-examples/master/dcos/istio/istio.yaml

\# deploy metrics collection kubectl apply -f install/kubernetes/addons/prometheus.yaml kubectl apply -f install/kubernetes/addons/grafana.yaml kubectl apply -f install/kubernetes/addons/servicegraph.yaml

\# deploy books sample app

\# Note that the Istio instructions use \`istioctl kube-inject\` to insert init- \# container annotations and proxy containers into this sample config file. \# Because we need to insert our own kubeconfig file, we provide an already- \# injected sample app config, and then apply our additional kubeconfig \# modifications: kubectl apply -f https://raw.githubusercontent.com/linkerd/linkerd-examples/master/dcos/istio/bookinfo.yaml

You should now be able to see the sample app.

\# view books app kubectl port-forward \$(kubectl get pod -l istio=ingress -o jsonpath='{.items\[0\].metadata.name}') 3001:80 open http://localhost:3001/productpage # osx only

![](https://buoyant.io/wp-content/uploads/2017/09/Screen-Shot-2017-09-14-at-1.19.22-PM.png) To confirm metrics collection is working, add some load to the sample app and verify traffic via the Grafana dashboard.

while true; do curl -o /dev/null -s -w "%{http_code}\\n" http://localhost:3001/productpage; done

\# forward port 3000 to grafana kubectl port-forward \$(kubectl get pod -l app=grafana -o jsonpath='{.items\[0\].metadata.name}') 3000:3000

open http://localhost:3000/dashboard/db/istio-dashboard # osx only

![](https://buoyant.io/wp-content/uploads/2017/09/Screen-Shot-2017-09-14-at-1.20.14-PM.png) Congratulations! You now have an application running on Kubernetes with DC/OS in AWS backed by the Istio service mesh.

## Conclusion

This was a fun exercise in stacking technologies together, and an interesting demonstration of how various infrastructure layers can compose. In the future, we'll show how Linkerd running on both Kubernetes and DC/OS can merge service namespaces and allow operators to migrate services between them, which is a more realistic of a use case for a cross-orchestrator service mesh. In the meantime, stay tuned and please feel free to stop by the [Linkerd discussion forums](https://discourse.linkerd.io/?__hstc=9342122.c92fc981c6470cd6772d8b1ef9b5a3f6.1486507172850.1505856918584.1505871311602.261&__hssc=9342122.15.1505871311602&__hsfp=1837952701), the [Linkerd community Slack](http://slack.linkerd.io/?__hstc=9342122.c92fc981c6470cd6772d8b1ef9b5a3f6.1486507172850.1505856918584.1505871311602.261&__hssc=9342122.15.1505871311602&__hsfp=1837952701), or just [contact us directly](https://linkerd.io/overview/help/?__hstc=9342122.c92fc981c6470cd6772d8b1ef9b5a3f6.1486507172850.1505856918584.1505871311602.261&__hssc=9342122.15.1505871311602&__hsfp=1837952701)!
