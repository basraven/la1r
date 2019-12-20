---
title: Conceptual Setup
type: docs
bookToc: false
weight: 2
---
# Conceptual details
To give a 1-minute overview: this is the conceptual model driving La1r:
![Conceptual](/svg/conceptual.svg)

It clearly shows how the Event-Driven architecture is the heart of La1r

To summarize, we identify several conceptual components:
* **Raw Data producer** - Any sensor, smart camera, etc. which is hooked up to the raw data bus and produces data from which well formed events can be produced.
* **Raw Data Bus** - The data vehicle which stores all incoming data which can be used to create events off, this can be very raw measurement data of data structured in an application specific format
* **Automation Event Transformation** - This can be any application which is connected to the Raw Data Bus and is able to create events conforming to the Event Specifications based on the data coming from the Raw Data Bus (this is non-restrictive and can also come from other places)
* **Event Specifications** - All specifications used to structure **all** events which are published on the Structured Event Bus. These Events specifications will also be published [on la1r.com](/)
* **AI Processes** - This is identical to the Automated Event Transformation, only these processes primarily involve AI to add events to the Structured Events Bus. In addition it can take already published events and create new events on that behavior based on predictive models.
* **Structured Event Consumer** - This can be any device which consumes events which are published on the Structured Event Bus and acts on it with a certain behavior, for example a light switching on based on an event. This consumer also entails translating the Structured Event into a format a device is able to operate on.
