---
title: "Google Summer of Code"
---
Welcome to the [Linkerd](https://linkerd.io) Google Summer of Code program! We
are looking forward to getting to know you and help make your contribution a
rewarding experience.

Does the idea of writing some amazing code for the most lightweight Kubernetes
service mesh, and learning from some of the best service mesh engineers
intrigue you?

Join us on the Linkerd [Slack](https://linkerd.slack.com). Look for the `#gsoc`
channel!

## Project Ideas

So you are up for the challenge? Check out the list of projects below. When you
are ready, go to the [Application Process](#application-process) section for
more information on how to proceed.

### Auto-Update

Linkerd has frequent updates and keeping up with the weekly edge releases can
be difficult. This project involves building a Kubernetes operator that can
observe the version-check API, auto-update the control plane and replace the
Linkerd data plane proxies with the correct version.

#### Expected outcomes

* An operator that watches the version-check API and triggers an update on
  changes.

* Flexible upgrade plans that are saved for each version to describe ordering
  and how to move between versions.

* Validation that each step of an upgrade completes successfully.

* Rolling modification of existing data plane proxies to the latest version
  based off annotations.

#### Recommended Skills

* Go

* Kubernetes

#### Difficulty level

Hard

#### Issue

[https://github.com/linkerd/linkerd2/issues/1903](https://github.com/linkerd/linkerd2/issues/1903)

### Conformance Validation

Linkerd has an extensive `check` suite that validates a cluster is ready to
install Linkerd and that the install was successful. These checks are,
unfortunately, static checks. Because of the wide number of ways a Kubernetes
cluster can be configured, users want a way to validate their specific install
for conformance over time. This project involves building a sample application
that exercises all of the features of Linkerd and allows an end user to run it
on their own cluster to validate that everything is working and configured
correctly over a long period of time time.

#### Expected outcomes

* Sample application that exercises all Linkerd features.

* CLI integration to start, monitor and stop the tests.

* Reporting to describe what is not working for users.

#### Recommended Skills

* Go

* Bash

* Kubernetes

* gRPC

#### Difficulty level

Medium

#### Issue

[https://github.com/linkerd/linkerd2/issues/1096](https://github.com/linkerd/linkerd2/issues/1096)

### Alertmanager Integration

Linkerd provides rich metrics that are stored in Prometheus out of the box.
These are for both the control plane and data plane. The goal is to provide
Alertmanager integration that comes out of the box, is configurable with
preferred channels (email, Slack) and works with ServiceProfiles to easily
create alerts that are per-service and per-route.

#### Expected outcomes

* Alertmanager installation as part of the control plane.

* Default alerting policy for the control plane.

* Simple configuration for desired alert channel.

* Integration with ServiceProfiles to setup rules to alert in Alertmanager.

#### Recommended Skills

* Go

* Prometheus

* Grafana

#### Difficulty level

Easy

#### Issue

[https://github.com/linkerd/linkerd2/issues/1726](https://github.com/linkerd/linkerd2/issues/1726)

### Scale Testing

Linkerd is used by many companies to enrich and secure their production
service network communication. It's very important that new features do not
regress its performance. The goal of this project is to automate the scale
testing infrastructure so that we can easily repeat the scale testing process,
and gain visibility into any performance regression.

#### Expected outcomes

* Automatically add a sample workload to the cluster.

* Record cluster, control plane and data plane metrics during test.

* Report on resource usage, Linkerd performance and potential errors encountered.

#### Recommended Skills

* Go

* Bash

* Kubernetes

* Prometheus

#### Difficulty level

Medium

#### Issue

[https://github.com/linkerd/linkerd2/issues/3895](https://github.com/linkerd/linkerd2/issues/3895)

{{< note >}}
If you have other project ideas not listed here, please talk to one of the
Linkerd mentors.
{{< /note >}}

## Application Process

It's very easy to get involved in the Linkerd GSoC program. The Linkerd
community has been known for its welcoming environment.

Come meet your prospective mentors and fellow students on the Linkerd
[Slack](https://linkerd.slack.com) in the `#gsoc` channel. Let's get you
started!

### Requirements

All students are required to get to know Linkerd by completing this
[Getting Started](https://linkerd.io/getting-started/) tutorial.

As part of the acceptance requirements, students **must** have at least one pull
requests reviewed and merged in the [Linkerd2](https://github.com/linkerd/linkerd2)
repository. You may like to start working on some of these
[good first issues](https://github.com/linkerd/linkerd2/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22)
.

Before proceeding with writing any code, read through the Linkerd's
[Developer Certificate of Origin](https://github.com/linkerd/linkerd2/blob/main/DCO).

Information on how to build the code can be found
[here](https://github.com/linkerd/linkerd2/blob/main/BUILD.md).

{{< note >}}
Pull requests will be reviewed on a first-come-first-serve basis. Please
account for the extra time you might need to address review feedbacks.

**Do not wait till the last minute!**
{{< /note >}}

### Request For Comments

When you are ready, submit a request for comments (RFC) to the Linkerd GSoC
repository as a
[draft pull request](https://help.github.com/en/github/collaborating-with-issues-and-pull-requests/about-pull-requests#draft-pull-requests)
.

The Linkerd GSoC repository is located at
[https://github.com/linkerd/gsoc](https://github.com/linkerd/gsoc).
Follow the instruction provided
[here](https://github.com/linkerd/gsoc/blob/master/README.md) to complete your
RFC.

Each pull request will be assigned to the most relevant reviewer, who will
lead its triage. Once your RFC is reviewed, you will be introduced to your
mentor.

{{< note >}}
Make sure you are familiar with the application review period, per the
[GSoC timeline](https://summerofcode.withgoogle.com/how-it-works/).

RFCs will be reviewed on a first-come-first serve basis.

**Do not wait till the last minute!**
{{</note>}}

## Project Execution

Congratulation! You are now part of the Linkerd GSoC team. Let's work together
to build something awesome!

Your mentor will schedule a kick-off meeting with you.

You'll have a GitHub project board setup just for your project! This will
contain all the issues that you're working on as part of your project. You are
expected to create issues which outline all the deliverables listed in the RFC
that you created along with any other things that come up along the way. The
board is a great way for you and your mentor to understand how everything is
going and what needs to be tackled next.

There are two important channels in Slack: `#gsoc` and `#contributors`. For
anything that is specifically related to GSoC, ask questions there! All the code
and project related questions should go into `#contributors`. Most of the Linkerd
maintainers are waiting there and can help answer your questions if your mentor
is unavailable.

Each deliverable will take the form of a PR to the
[Linkerd2](https://github.com/linkerd/linkerd2) repository. Remember that these
should take less than 2 weeks to code, be reviewed and merged. Plan for it
taking at least 3 days for a review to be completed from initially being
created. There will be lots of back and forth in the PR to get your code honed
to perfection. If you feel like the current deliverable you're working on will
take longer than 2 weeks, bring it up with your mentor! This means that the
scoping wasn't quite right and you'll want to chat a little bit about reducing
the size of the deliverable. Remember, large PRs take a lot longer to review and
get in the way of having feedback early and often.

Make sure you surface any roadblocks and risks to your mentors early. Ask lots
of questions!

---

It will also be helpful for your mentor to receive a weekly status communication
from you. Previous mentors and students have use this template to facilitate
their weekly catch-up:

### Accomplishments and Key Updates

Mention all the work done with relevant links and discussions that happened

### Next Work

Mention the work that is planned for next week

### Risks

Mention about any deadlines that are coming up and any problems that you are facing

### Asks

Mention about any doubts, questions that you have or any calls that you
scheduled/want to schedule

---

Towards the end of your project, we may make arrangement for you to demonstrate
your work on the Linkerd's monthly community meetup. This is an
excellent opportunity for you to show off the amazing thing that you have been
building!

## Project Evaluation

Coming soon.
