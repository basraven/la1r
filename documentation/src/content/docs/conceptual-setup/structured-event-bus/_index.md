# Structured Event Bus
The data vehicle which stores the structured events, forming the logical epi-center of the event-driven la1r. The majority of the events are sourced by transformed raw data from the Raw Data Bus

* All events in the structured event bus conform to the [./event-specifications] to be formally "accepted"
* The current goal is to have a single event bus through which the majority (if it makes sense) of the applications communicate through.
