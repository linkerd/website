+++
date = "2017-07-24T17:12:17-07:00"
title = "Running in ECS"
description = "How to run Linkerd in ECS, using Consul for Service Discovery and linkerd-viz for monitoring."
weight = 6
aliases = [
  "/getting-started/ecs"
]
[menu.docs]
  parent = "getting-started"
+++

[Amazon ECS](https://aws.amazon.com/ecs/) is a container management service.
This guide will demonstrate routing and monitoring your services using Linkerd
in ECS.

All commands and config files referenced in this guide may be found in the
[linkerd-examples repo](https://github.com/linkerd/linkerd-examples/tree/master/ecs).

## Overview

This guide will demonstrate setting up Linkerd as a service mesh, Consul for
service discovery, a hello-world sample app, and linkerd-viz for monitoring, all
on a fresh ECS cluster.

The following components make up the system:

* `ECS`: Docker container management. Every ECS instance runs the following
  Docker containers:
  * `linkerd`: proxies requests to `hello-world`
  * `consul-agent`: local service discovery agent
  * [`consul-registrator`](https://github.com/gliderlabs/registrator): bridge
  between Docker and Consul, automatically registers services with consul
* `hello-world`: example ECS task deployed separately from foundational
  `ECS`+`linkerd`+`consul-agent` configuration, composed of `hello`, `world`,
  and `world-v2` services
* [`linkerd-viz`](https://github.com/linkerd/linkerd-viz): ECS task deployed
  separately from foundational `ECS`+`linkerd`+`consul-agent` configuration,
  provides a monitoring dashboard for all service traffic
* `consul-server`: service discovery back-end, runs on a single EC2 instance

{{< fig src="/images/ecs-linkerd-diagram.png" title="Linkerd in ECS" >}}

Note that `linkerd`, `consul-agent`, and `consul-registrator` run on every ECS
node. As of the writing of this guide, the ECS scheduler does not explicitly
support this. Instead, we use an AWS Launch Configuration to bootstrap every ECS
node with these three foundational services. We still boot these foundational
services via an `aws ecs start-task` command, so they will be visible as running
ECS containers.

## Initial Setup

This guide assumes you have already configured AWS with the proper
IAM, key pairs, and VPCs for an ECS cluster. For more information start here:
http://docs.aws.amazon.com/AmazonECS/latest/developerguide/get-set-up-for-amazon-ecs.html

Set a key pair you will use to access your instances, or omit the parameter to
forego ssh access.

```bash
KEY_PAIR=<MY KEY PAIR NAME>
```

Create a Security Group that allows outside access to the following:

- ssh: 22
- `linkerd` routing: 4140
- `linkerd` admin UI: 9990
- `linkerd-viz`: 3000
- `consul-agent` and `consul-server` UI: 8500

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

The Security Group also opens every port between nodes. For a comprehensive list
of all ports required for intra-node communication, reference the ECS Task
Definition files, found in the
[linkerd-examples repo](https://github.com/linkerd/linkerd-examples/tree/master/ecs)

## Consul Server

For demonstration purposes, we run a single Consul Server outside of the ECS
cluster.

```bash
aws ec2 run-instances --image-id ami-7d664a1d \
  --instance-type m4.xlarge \
  --user-data file://consul-server-user-data.txt \
  --placement AvailabilityZone=us-west-1a \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=l5d-demo-consul-server}]" \
  --key-name $KEY_PAIR --security-group-ids $GROUP_ID
```

We tag this instance with `l5d-demo-consul-server`. We will then reference this
tag in the `consul-agent` config running on each ECS node. This enables the
`consul-agent`'s to find `consul-server`.

## ECS Cluster

Create a new ECS cluster named `l5d-demo`

```bash
aws ecs create-cluster --cluster-name l5d-demo
```

We reference `l5d-demo` when bootstrapping our ECS nodes, to instruct them
to join this ECS cluster we have just created.

### Role Policy

Create a Role Policy to allow ECS instances to start tasks and describe
instances.

```bash
aws iam put-role-policy --role-name ecsInstanceRole --policy-name l5dDemoPolicy --policy-document file://ecs-role-policy.json
```

We require the `ecs:StartTask` ability because our Launch Configuration will
start our three foundational tasks on each ECS node. We require the
`ec2:DescribeInstances` ability because `consul-agent` will need to find
`consul-server` via the `l5d-demo-consul-server` instance tag.

### Register Task Definitions

These Task Definitions describe how we configure and boot all five applications.
Note that `hello-world` describes three separate Docker containers, `hello`,
`world`, and `world-v2`.

```bash
aws ecs register-task-definition --cli-input-json file://linkerd-task-definition.json
aws ecs register-task-definition --cli-input-json file://linkerd-viz-task-definition.json
aws ecs register-task-definition --cli-input-json file://consul-agent-task-definition.json
aws ecs register-task-definition --cli-input-json file://consul-registrator-task-definition.json
aws ecs register-task-definition --cli-input-json file://hello-world-task-definition.json
```

### Create Launch Configuration

This step defines a Launch Configuration. The
[ecs-user-data.txt](https://github.com/linkerd/linkerd-examples/blob/master/ecs/ecs-user-data.txt)
file instructs the Launch Configuration to configure and boot `linkerd`,
`consul-agent`, and `consul-registrator` on each ECS node.

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

Note the
[ecs-user-data.txt](https://github.com/linkerd/linkerd-examples/blob/master/ecs/ecs-user-data.txt)
file dynamically generated config files for each of `linkerd`, `consul-agent`,
and `consul-registrator`, using data specific to the ECS Instance it is running
on.

### Create Auto Scaling Group

This step actually creates the EC2 instances, based on the Launch Configuration
defined above. Upon completion, we should have two ECS nodes, each running
`linkerd`, `consul-agent`, and `consul-registrator`.

```bash
aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name l5d-demo-asg \
  --launch-configuration-name l5d-demo-lc \
  --min-size 1 --max-size 3 --desired-capacity 2 \
  --tags ResourceId=l5d-demo-asg,ResourceType=auto-scaling-group,Key=Name,Value=l5d-demo-ecs,PropagateAtLaunch=true \
  --availability-zones us-west-1a
```

We name our instances `l5d-demo-ecs` so we can programmatically find them later
on.

### Deploy hello-world

Now that all our foundational services are deployed, we can deploy a sample app.
The `hello-world` task is composed of a `hello` service, a `world` service, and
a `world-v2` service. To demonstrate inter-service communication, we configure
the `hello` service to call the `world` service, via `linkerd`.

```bash
aws ecs run-task --cluster l5d-demo --task-definition hello-world --count 2
```

Note that we have deployed two instances of `hello-world`, which results in two
`hello` containers, two `world` containers, and two `world-v2` containers.

## Test everything worked

We select an arbitrary ECS node, via the `l5d-demo-ecs` name, then curl the
`hello` service via Linkerd:

```bash
# Select an ECS node
ECS_NODE=$( \
  aws ec2 describe-instances \
    --filters Name=instance-state-name,Values=running Name=tag:Name,Values=l5d-demo-ecs \
    --query Reservations[*].Instances[0].PublicDnsName --output text \
)

# test routing via Linkerd
http_proxy=$ECS_NODE:4140 curl hello
Hello (172.31.20.160) World (172.31.19.35)!!

# view Linkerd and Consul UIs (osx)
open http://$ECS_NODE:9990
open http://$ECS_NODE:8500
```

The request flow we just tested:

`curl` -> `linkerd` -> `hello` -> `linkerd` -> `world`

### Test dynamic request routing

As our `hello-world` task also included a `world-v2` service, let's test
per-request routing:

```bash
http_proxy=$ECS_NODE:4140 curl -H 'l5d-dtab: /svc/world => /svc/world-v2' hello
Hello (172.31.20.160) World-V2 (172.31.19.35)!!
```

By setting the `l5d-dtab` header, we instructed Linkerd to dynamically route all
requests destined for `world` to `world-v2`.

{{< fig src="/images/ecs-linkerd-routing.png" title="Linkerd request routing" >}}

For more information, have a look at
[Dynamic Request Routing]({{% ref "/1/features/routing.md" %}}).

## linkerd-viz

[`linkerd-viz`](https://github.com/linkerd/linkerd-viz) collects and displays
metrics for all `linkerd`'s running in a cluster. Prior to deploying, let's
put some load through our system:

```bash
while true; do http_proxy=$ECS_NODE:4140 curl -s -o /dev/null hello; done
```

Now deploy a single `linkerd-viz` instance:

```bash
aws ecs run-task --cluster l5d-demo --task-definition linkerd-viz --count 1

# find the ECS node running linkerd-viz
TASK_ID=$(aws ecs list-tasks --cluster l5d-demo --family linkerd-viz --desired-status RUNNING --query taskArns[0] --output text)
CONTAINER_INSTANCE=$(aws ecs describe-tasks --cluster l5d-demo --tasks $TASK_ID --query tasks[0].containerInstanceArn --output text)
INSTANCE_ID=$(aws ecs describe-container-instances --cluster l5d-demo --container-instances $CONTAINER_INSTANCE --query containerInstances[0].ec2InstanceId --output text)
ECS_NODE=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query Reservations[*].Instances[0].PublicDnsName --output text)

# view linkerd-viz (osx)
open http://$ECS_NODE:3000
```

If everything worked correctly, we should see a dashboard like this:

{{< fig src="/images/ecs-linkerd-viz.png" title="linkerd-viz in ECS" >}}

## Further reading

For more information about configuring Linkerd, see the
[Linkerd Configuration](https://api.linkerd.io/latest/linkerd) page.

For more information about linkerd-viz, see the
[linkerd-viz GitHub repo](https://github.com/linkerd/linkerd-viz).
