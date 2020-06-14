---
title: Capability Architecture
type: docs
bookToc: false
weight: 2
---

## Conceptual details
To give a 1-minute overview: this is the conceptual model driving La1r:
![Conceptual](/svg/conceptual.svg)

It shows the conceptual layout of how all components in the Event-Driven architecture are structured.
Since we are now only focussing on the conceptual aspects, implementation details such as infrastructure stack are not discussed here.
The fundamental architecture for La1r follows [a Kappa architectural pattern](https://wikipedia.com/kappa-architecture) for processing data.
This means that the architecture will handle bulk/batch data the same way as it handles streaming/realtime data.

There has been made a distinction between two types of data streams:

* Raw Data Stream - Data that is not "Governed" and does not apply to the imposed event structures as described on this site. This is often the data sink for commercial-of-the-shelf (COTS) components with which need to be integrated. To save the hassle of writing custom extensions to those components, it is easier to push the data to a "raw" even stream and transform the raw events into structured events which conform to the even structures.
* Structured Data Stream - This data stream only contains data which conforms to the defined standard for events

To summarize, we identify several conceptual components:

* **Raw Data producer** - Any sensor, smart camera, etc. which is hooked up to the raw data stream and produces data from which well formed events can be produced.
* **Raw Data Stream** - The data vehicle which stores all incoming data which can be used to create events off, this can be very raw measurement data of data structured in an application specific format
* **Streaming Event Transformations** - This can be any application which is connected to the Raw Data Stream and is able to create events conforming to the Event Specifications based on the data coming from the Raw Data Stream (this is non-restrictive and can also come from other places)
* **Event Specifications** - All specifications used to structure **all** events which are published on the Structured Event Stream. These Events specifications will also be published [on la1r.com](/). These event specifications are not a direct part of the actual data flow, but are of a significant enough importance to name it in this diagram.
* **Structured Event Stream** - The data stream which stores the structured events, forming the logical epi-center of the event-driven la1r. The majority of the events are sourced by transformed raw data from the Raw Data Stream or results of analyzed raw/structured events
* **Streaming Analytics Processes** - This is identical to the Automated Event Transformation, only these processes analyze the data to find significant patterns which can be used by other (decoupled) processes further downstream.
* **Structured Event Consumer** - This can be any device which consumes events which are published on the Structured Event Stream and acts on it with a certain behavior, for example a light switching on based on an event. This consumer also entails translating the Structured Event into a format a device is able to operate on.

## Conceptual Architecture Principles
The la1r architecture followes several conceptual principles which components in its architecture should follow.
Since this will not capture implementation specific / technical principles, a section on technical principles is describe [in the technical architecture page](./technical-setup)

1. Data is realtime and streaming - Always assume that data, streaming through the la1r infrastructure is in streaming "format". Do not unnecessarily store it, or batch it when realtime streaming solutions can also be applied
1. Don't assume information share - since an enterprise environment is conceptually simulated, it should also be simulated that (conceptual) teams are not fully aware of all integrations made by other (conceptual) teams. The implications of this is that there is a need for decoupling and formal information definitions. An example of this is the site you're currently reading, but further efforts should be made such as formal separation of layers, environments and data to appropriately conform to this conceptual requirement. 
1. Decentralized application paradigms where possible - To support the horizontal scaling capabilities, an effort should be made to apply decentralized paradigms, which often improve scalability and availability when implemented correctly. 

{{< columns >}}
## Event Specifications
Since there needs to be a way of formally converging to an aligned data setup, a formal event specification setup is made.
This event specification will dictate how all events in the structured stream should be shaped.
Events not conforming to this standard can be disregarded.

[Read more](/docs/conceptual-setup/event-specifications)

<--->

## Governance Catalogs
Since we are still "simulating" an enterprise environment, and since my own memory is sub-optimal, appropriate governance catalogs need to be setup to fully capture the IT landscape on several domains.

[Read more](/docs/conceptual-setup/governance-catalogs)

<--->

{{< /columns >}}
