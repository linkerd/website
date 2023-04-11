---
slug: 'a-service-mesh-for-ecs'
title: 'A Service Mesh For ECS'
aliases:
  - /2017/08/08/a-service-mesh-for-ecs/
author: 'andrew'
date: Tue, 08 Aug 2017 15:08:30 +0000
draft: false
thumbnail: /uploads/linkerd_featured.png
featured: false
tags:
  [
    aws,
    ECS,
    Linkerd,
    linkerd,
    service mesh,
    tutorials,
    Tutorials &amp; How-To's,
  ]
---

Linkerd, our open source service mesh for cloud native applications, adds reliability and visibility to microservices by managing all of the internal communication between services. Deployed as a set of transparent layer 5/7 proxies, the Linkerd service mesh provides a consistent, global layer for monitoring and controlling all internal, service-to-service traffic within an application. (For more on the service mesh model, read William’s article, [What's a service mesh? And why do I need one?]({{< relref "whats-a-service-mesh-and-why-do-i-need-one" >}}))

One of Linkerd’s strengths is its ability to integrate with many different environments (and to allow you to bridge environments!). In previous posts, we’ve covered how to use Linkerd with [Kubernetes][part-i] and [DC/OS](https://buoyant.io/2016/04/19/linkerd-dcos-microservices-in-production-made-easy/). In this post, we describe how to use Linkerd with Amazon ECS.

All commands and config files referenced in this post may be found in the [linkerd-examples repo](https://github.com/linkerd/linkerd-examples/tree/master/ecs).

## Overview

This post will show you how to set up Linkerd as a service mesh on ECS, using Consul for service discovery, linkerd-viz for monitoring, and a hello-world sample app, as seen in the diagram below:

{{< fig
  alt="Linkerd: A Service Mesh for ECS"
  title="Linkerd: A Service Mesh for ECS"
  src="/uploads/2018/05/service-mesh-for-ECS@2x.png" >}}

## Initial Setup

This post assumes you have already configured AWS with the proper IAM, key pairs, and VPCs for an ECS cluster. For more information on these topics, have a look at Amazon’s [Setting Up with Amazon ECS guide](http://docs.aws.amazon.com/AmazonECS/latest/developerguide/get-set-up-for-amazon-ecs.html).

Set a key pair you will use to access your instances, or omit the parameter to forego ssh access:

```bash
KEY_PAIR=MY_KEY_PAIR_NAME
```

Next, create a Security Group:

```bash
GROUP_ID=$(aws ec2 create-security-group --group-name l5d-demo-sg --description "Linkerd Demo" | jq -r .GroupId)
aws ec2 authorize-security-group-ingress --group-id $GROUP_ID \
  --ip-permissions \
    FromPort=22,IpProtocol=tcp,ToPort=22,IpRanges=[{CidrIp="0.0.0.0/0"}] \
    FromPort=4140,IpProtocol=tcp,ToPort=4140,IpRanges=[{CidrIp="0.0.0.0/0"}] \
    FromPort=9990,IpProtocol=tcp,ToPort=9990,IpRanges=[{CidrIp="0.0.0.0/0"}] \
    FromPort=3000,IpProtocol=tcp,ToPort=3000,IpRanges=[{CidrIp="0.0.0.0/0"}] \
    FromPort=8500,IpProtocol=tcp,ToPort=8500,IpRanges=[{CidrIp="0.0.0.0/0"}] \
    IpProtocol=-1,UserIdGroupPairs=[{GroupId=$GROUP_ID}]
```

## Set up Consul

For demonstration purposes, we run a single Consul server outside of the ECS cluster:

```bash
aws ec2 run-instances --image-id ami-7d664a1d \
  --instance-type m4.xlarge \
  --user-data file://consul-server-user-data.txt \
  --placement AvailabilityZone=us-west-1a \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=l5d-demo-consul-server}]" \
  --key-name $KEY\_PAIR --security-group-ids $GROUP_ID
```

## Set up ECS

### Create a new cluster

```bash
aws ecs create-cluster --cluster-name l5d-demo
```

### Create a Role Policy

```bash
aws iam put-role-policy --role-name ecsInstanceRole --policy-name l5dDemoPolicy --policy-document file://ecs-role-policy.json
```

### Register Task Definitions

```bash
aws ecs register-task-definition --cli-input-json file://linkerd-task-definition.json
aws ecs register-task-definition --cli-input-json file://linkerd-viz-task-definition.json
aws ecs register-task-definition --cli-input-json file://consul-agent-task-definition.json
aws ecs register-task-definition --cli-input-json file://consul-registrator-task-definition.json
aws ecs register-task-definition --cli-input-json file://hello-world-task-definition.json
```

### Create Launch Configuration

This step defines a Launch Configuration. We configure our ECS cluster to boot Linkerd and consul on each ECS node.

```bash
aws autoscaling create-launch-configuration \
  --launch-configuration-name l5d-demo-lc \
  --image-id ami-7d664a1d \
  --instance-type m4.xlarge \
  --user-data file://ecs-user-data.txt \
  --iam-instance-profile ecsInstanceRole \
  --security-groups $GROUP_ID \
  --key-name $KEY_PAIR
```

Note ecs-user-data.txt dynamically generates config files for each of _Linkerd_, _consul-agent_, and _consul-registrator_, using data specific to the ECS Instance it is running on.

### Create an Auto Scaling Group

This step actually creates the EC2 instances, based on the Launch Configuration defined above. Upon completion, we should have two ECS nodes, each running Linkerd, consul-agent, and consul-registrator.

```bash
aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name l5d-demo-asg \
  --launch-configuration-name l5d-demo-lc \
  --min-size 1 --max-size 3 --desired-capacity 2 \
  --tags ResourceId=l5d-demo-asg,ResourceType=auto-scaling-group,Key=Name,Value=l5d-demo-ecs,PropagateAtLaunch=true \
  --availability-zones us-west-1a
```

We name our instances _l5d-demo-ecs_ so we can programmatically find them later on.

### Deploy the hello-world sample application

Now that all our foundational services are deployed, we can deploy a sample app. The _hello-world_ task is composed of a _hello_ service, a _world_ service, and a _world-v2_ service. To demonstrate inter-service communication, we configure the _hello_ service to call the _world_ service via _Linkerd_.

```bash
aws ecs run-task --cluster l5d-demo --task-definition hello-world --count 2
```

Note that we have deployed two instances of hello-world, which results in two hello containers, two world containers, and two world-v2 containers.

## Did it work?

If everything deployed correctly, we should see 8 tasks running in our [ECS dashboard](https://us-west-1.console.aws.amazon.com/ecs/home?region=us-west-1#/clusters/l5d-demo/tasks):

{{< fig
  alt="ECS Tasks"
  title="ECS Tasks"
  src="/uploads/2018/05/ecs-tasks-1024x589.png" >}}

We select an arbitrary ECS node, via the _l5d-demo-ecs_ name, then curl the _hello_ service via _Linkerd_:

```bash
ECS_NODE=\$( \
  aws ec2 describe-instances \
  --filters Name=instance-state-name,Values=running Name=tag:Name,Values=l5d-demo-ecs \
  --query Reservations[*].Instances[0].PublicDnsName --output text \
)
```

Now test routing:

```bash
$ http_proxy=$ECS_NODE:4140 curl hello
Hello (172.31.20.160) World (172.31.19.35)!!
```

If everything worked correctly, we should get a reply from the _hello_ service, with data from the world service. View Linkerd and Consul UIs:

```bash
# (osx only)
open http://$ECS_NODE:9990
open http://$ECS_NODE:8500
```

## Test dynamic request routing

One of Linkerd's most powerful features is dynamic request routing. Here we'll demonstrate routing a single request to the world-v2 service, rather than the default _world_ service:

```bash
$ http_proxy=$ECS_NODE:4140 curl -H 'l5d-dtab: /svc/world => /svc/world-v2' hello
Hello (172.31.20.160) World-V2 (172.31.19.35)!!
```

The request flow we just tested:

```txt
curl -> linkerd -> hello -> linkerd -> world-v2
```

By setting the _l5d-dtab_ header, we instructed Linkerd to dynamically route all requests destined for _world_ to _world-v2_, even though the request initially transited through the hello service.

{{< fig
  alt="Per-request routing with Linkerd"
  title="Per-request routing with Linkerd"
  src="/uploads/2018/05/per_request_routing@2x.png" >}}

For more information, have a look at [Dynamic Request Routing](https://linkerd.io/features/routing/).

### Monitoring the services

Linkerd instruments all traffic and exposes these metrics, including top-line service metrics like success rates and latencies. By using the Linkerd service mesh, we can automatically collect these valuable metrics without having to modify our application!

Since Linkerd itself is purely distributed, however, we need to aggregate these results. For convenience, we provide a simple open source package, [linkerd-viz](https://github.com/linkerd/linkerd-viz), which can collect and displays metrics for all Linkerd's running in a cluster.

Prior to deploying linkerd-viz, let's put some load through our system:

```bash
while true; do http_proxy=$ECS_NODE:4140 curl -s -o /dev/null hello; done
```

Now deploy a single linkerd-viz instance:

```bash
aws ecs run-task --cluster l5d-demo --task-definition linkerd-viz --count 1
```

Now bring up the _linkerd-viz_ dashboard:

```bash
# find the ECS node running linkerd-viz
TASK_ID=$( \
  aws ecs list-tasks \
    --cluster l5d-demo \
    --family linkerd-viz \
    --desired-status RUNNING \
    --query taskArns[0] \
    --output text)
CONTAINER_INSTANCE=$( \
  aws ecs describe-tasks \
    --cluster l5d-demo \
    --tasks $TASK_ID \
    --query tasks[0].containerInstanceArn \
    --output text)
INSTANCE_ID=$( \
  aws ecs describe-container-instances \
    --cluster l5d-demo \
    --container-instances $CONTAINER_INSTANCE \
    --query containerInstances[0].ec2InstanceId \
    --output text)
ECS_NODE=$( \
  aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query Reservations[*].Instances[0].PublicDnsName \
  --output text)

# view linkerd-viz (osx only)
open http://$ECS_NODE:3000
```

If everything worked correctly, we should see a dashboard like this:

{{< fig
  alt="ECS linkerd-viz"
  title="ECS linkerd-viz"
  src="/uploads/2018/05/ecs-linkerd-viz.png" >}}

## Conclusion

In the above post, we’ve show how to deploy Linkerd on ECS to provide a service mesh: a dedicated layer for managing and monitoring all service-to-service communication. This is only the tip of the iceberg: Linkerd can also be used to merge ECS, Kubernetes, DC/OS, and other environments into a single logical service namespace; to implement complex traffic patterns like hybrid cloud and multi-cloud topologies; and much more.

## Credits

The examples and configurations in this post drew heavily from some excellent blog posts. Have a look at them for other approaches to running ECS:

- [Linkerd: A service mesh for AWS ECS](https://medium.com/attest-engineering/linkerd-a-service-mesh-for-aws-ecs-937f201f847a) by Dario Simonetti
- [Running Linkerd in a docker container on AWS ECS](https://kevinholditch.co.uk/2017/06/28/running-linkerd-in-a-docker-container-on-aws-ecs/) by Kevin Holditch
- [Deploying Consul With ECS](https://blog.unif.io/deploying-consul-with-ecs-2c4ca7ab2981) by Wilson Carey

## Further reading

There’s a lot more that you can do with Linkerd. For more details about this setup, see [Getting Started: Running in ECS](https://linkerd.io/getting-started/ecs/). For all commands and config files referenced in this post, see the [linkerd-examples repo](https://github.com/linkerd/linkerd-examples/tree/master/ecs). For more information about configuring Linkerd, see the [Linkerd Configuration](https://api.linkerd.io/latest/linkerd/index.html) page. Finally, for more information about linkerd-viz, see the [linkerd-viz Github repo](https://github.com/linkerd/linkerd-viz).

We hope this post was useful. We’d love to get your thoughts. Please join us in the [Linkerd Support Forum](https://linkerd.buoyant.io/) and the Linkerd [Slack](https://slack.linkerd.io/) channel!
