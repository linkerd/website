---
title: Accelerate Linkerd2 with Intel Dynamic Load Balancer
date: 2024-04-09T00:00:00Z
tags:
  - performance
  - dlb
author: daixiang0
thumbnail: "/uploads/thumbnail.jpg"
description: 'Introduce solution of combining software and hardware about how Intel Dynamic Load Balancer helps Linkerd2.'
keywords: [performance, dlb]
---

[Intel® Dynamic Load Balancer (Intel® DLB)](https://www.intel.com/content/www/us/en/download/686372/intel-dynamic-load-balancer.html) is a hardware-managed system of queues and arbiters connecting producers and consumers. It is a PCI device envisaged to live in the server CPU uncore that can interact with software running on cores and potentially with other devices.

Intel DLB implements the following load balancing features:

- Offloads queue management from software:
  - Improves multi-producer / multi-consumer scenarios and enqueue batching to multiple destinations.
  - Intel DLB implements lockless access to shared queues. This removes the need for overhead locks when accessing shared queues in the software.
- Dynamic, flow aware load balancing and reordering:
  - Ensures equal distribution of tasks and better CPU core utilization. Can provide flow-based atomicity if required.
  - Distributes high bandwidth flows across many cores without loss of packet order.
  - Better determinism and avoids excessive queuing latencies.
  - Uses less IO memory footprint and saves DDR Bandwidth.
- Priority queuing (up to 8 levels) —allows for QoS:
  - Lower latency for traffic that is latency sensitive.
  - Optional delay measurements in the packets.
- Scalability:
  - Allows dynamic sizing of applications, with seamless scaling up/down.
  - Power aware; application can drop workers to lower power state in cases of lighter loads.

There are three types of load balancing queues:

- Unordered: For multiple producers and consumers, where the order of tasks is not important. Each task is assigned to the processor core with the lowest current load.
- Ordered: For multiple producers and consumers, where the order of tasks is important. When multiple tasks are processed by multiple processor cores, they must be rearranged in the original order.
- Atomic: For multiple producers and consumers, where tasks are grouped according to certain rules. These tasks are processed using the same set of resources and the order of tasks within the same group is important.

## How Intel DLB accelerates Linkerd2

Intel DLB accelerates Linkerd2 by accelerating [Tokio](https://tokio.rs/), which is Linkerd2's async runtime written in Rust.

Rust currently provides only the essentials for writing async code. Rust has very strict backward compatibility requirements and a specific runtime for Rust standard library has not been chosen. Along comes Tokio, which gets the biggest support from the community and has many sponsors.

Tokio is generic, reliable, easy to use, and flexible for most--but not all cases because of its scheduler.

## How Tokio implements its scheduler

Tokio’s scheduler is modeled on a work-stealing scheduler.

![work-stealing scheduler](/uploads/work-stealing-scheduler.png)

As shown in the above picture, in a work-stealing scheduler,

1. each processor spawns tasks, puts them in its own queue, and runs them.
2. If the queue is empty, the processor tries to steal from other threads.

The scheduling overhead is from synchronization. To reduce cost, CAS (compare and swap) is a common solution, but CAS cannot perfectly **scale with core count**.

Although scheduling overhead only occurs when it tries to “steal”, it is hard to balance the workload of all processors, which leads to high tail latency in high traffic cases.

## How Intel Dynamic Load Balancer helps Tokio

Intel DLB can be a lockless multiple-producer and multiple-consumer queue. In this scenario, we replaced the Tokio scheduler with Intel DLB as below:
![this picture](/uploads/work-balancing-scheduler.png)

The new work-balancing scheduler shows:
1. Threads spawn tasks.
2. Threads send tasks to Intel DLB.
3. Threads are notified by Intel DLB to get tasks. Then, it puts the tasks into its own queue and runs them.

In this way, the workload of all threads can be balanced by Intel DLB and perfectly scaled with core count.

## How to deploy the benchmark

The best case for Intel DLB-enabled Tokio is high traffic, like ingress. Since Linkerd2 should work with existing ingress solutions such as Nginx Ingress, we deploy the benchmark environment as below:
![dlb-benchmark-env](/uploads/dlb-benchmark-env.png)

In our lab, we compared the baseline of pure Linkerd2-Proxy to the target of Linkerd2-Proxy with Intel DLB and the result shows that the request per second has been improved and the latency has been reduced.

## Conclusion

With the help of the DLB hardware accelerator card built into the Intel Sapphire Rapids processor, provides Linkerd2 with a hardware accelerated solution, avoiding CAS scale issue and workload unbalancing issue, and effectively reducing latency. It is suitable for applications such as ingress gateways and other scenarios that need to efficiently handle high traffic.

The fourth-generation Intel Xeon scalable processor, codenamed Sapphire Rapids, is the successor to Ice Lake. The platform is built on Intel 7 node (formerly 10nm) and features up to 60 Golden Cove cores per processor along with new hardware acceleration cards that deliver significant performance improvements over the previous generation. DLB is one of the new hardware accelerator cards. If you are interested, you can go to the official website to view [more hardware accelerator card information](https://link.zhihu.com/?target=https%3A//www.intel.com/content/www/us/en/now/xeon-accelerated/accelerators.html).

The whole solution is experimental, please contact [me](mailto:loong.dai@intel.com) for any details if interested.

We firmly believe that with the development of cloud computing and service mesh, solutions combining software and hardware can provide users with higher performance.
