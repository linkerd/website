---
title: "Google Summer of Code"
---
Welcome to the [Linkerd](https://linkerd.io) Google Summer of Code program! We
are looking forward to getting to know you and help make your contribution a
rewarding experience.

Does the idea of writing some amazing code for the most lightweight Kubernetes
service mesh, and learning from some of the best service mesh engineers
intrigue you?

Join us on thd Linkerd [Slack](https://linkerd.slack.com). Look for the `gsoc`
channel!

## Project Ideas

So you are up for the challenge, and ready to show off your problem-solving
skills? Check out the list of projects below. When you are ready, go to the
[Application Process](#application-process) section for more information on how
to proceed.

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
preferred channels (email, slack) and works with ServiceProfiles to easily
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
Suggesting your own project idea is highly encouraged. Talk to one of the
Linkerd mentors to explore your idea.
{{< /note >}}

## Application Process

It's very easy to get involved in the Linkerd GSoC program. The Linkerd
community has been known for its friendly and pressureless environment.

Come and meet your prospective mentors and fellow students on the Linkerd
[Slack](https://linkerd.slack.com) in the `gsoc` channel. Tell us which
projects interest you, and let's get your started!

### Requirements

All students are required to get to know Linkerd by completing this
[Getting Started](https://linkerd.io/2/getting-started/) tutorial.

As part of the acceptance requirements, students **must** have at least one pull
requests reviewed and merged in the [Linkerd2](https://github.com/linkerd/linkerd2)
repository. You may like to start working on some of these
[good first issues](https://github.com/linkerd/linkerd2/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22)
.

Before proceeding with writing any code, read through the Linkerd's
[Developer Certificate of Origin](https://github.com/linkerd/linkerd2/blob/master/DCO).

Information on how to build the code can be found
[here](https://github.com/linkerd/linkerd2/blob/master/BUILD.md).

{{< note >}}
Pull requests will be reviewed on a first-come-first-serve basis. Please
account for the extra time you might need to address review feedbacks.

**Do not wait till the last minute!**
{{< /note >}}

### Request For Comments

When you are ready, submit a request-for-comments (RFC) to the Linkerd RFC
repository as a
[draft pull request](https://help.github.com/en/github/collaborating-with-issues-and-pull-requests/about-pull-requests#draft-pull-requests)
. Name your pull request after your project. Use the pull request template to
capture all the required information.

The Linkerd mentors will review your RFC and provide feedback accordingly.

{{< note >}}
Make sure you are familiar with the application review period, per the
[GSoC timeline](https://summerofcode.withgoogle.com/how-it-works/).

RFCs will be reviewed on a first-come-first serve basis.

**Do not wait till the last minute!**
{{</note>}}

Once your RFC is reviewed, you will be introduced to your mentor.

All acceptance announcements will be made on Slack.

## Project Execution

Congratulation! You are now part of the Linkerd GSoC team. Let's work together
to build something awesome!

Your mentor will schedule a kick-off meeting with you. If needed, talk to your
mentor about setting up a GitHub project board to help you track your tasks.

Throughout the project duration, utilize the `gsoc` channel often for any
project and coding questions.

When ready, submit your code as a draft pull request to the
[Linkerd2](https://github.com/linkerd/linkerd2) repository. We found that
submitting a draft pull request early allows us to receive helpful peer feedback
sooner. These feedback helps to identify any design and implementation
deviation.

Make sure you surface any roadblocks and risks to your mentors early. Ask lots
of questions!

It will also be helpful for your mentor to receive a weekly status communication
from you. Previous mentors and students have use this template to faciliate
their weekly catch-up:

```text
Accomplishments and Key Updates
Mention all the work done with relevant links and discussions that happened

Next Work
Mention the work that is planned for next week

Risks
Mention about any deadlines that are coming up and any problems that you are facing

Asks
Mention about any doubts, questions that you have or any calls that you scheduled/want to schedule
```

Towards the end of your project, we may make arrangement for you to demonstrate
your work on one of the Linkerd's monthly community meeting. This is an
excellent opportunity for you to show off the amazing thing that you have been
building!

## Final Project Evaluation

Coming soon.
