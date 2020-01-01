# Event Specifications
The event specifications are a exhaustive list of specifications to which any event should conform.
With specifying this, decoupled and predictable interactions between services can be achieved.


These types of event specifications are currently defined:
* **Content specifications** - Specifications putting requirements on the content of the event
* **Attribute specifications** - Specifications putting requirements on the attributes of an event


# Content specifications
1. All content of an event should be structured in JSON format
1. There cannot be duplicate data between content and attribute data


# Attribute specifications
1. The topic modelling standard should be applied on any event published
1. Attributes need to be as specific as possible, it should not attempt to group multiple entities because this can be achieved by more advanced queries in the event bus protocol by the use of wildcards.


## Topic modelling standard
Topic modelling is a conceptual architectural decision which should be made very conscious of future extensions.
Large refactor movements in the conceptual structure of an Event bus can have a major change impact because many applications need to change their way of interacting.

### What needs to be captured in topics
The following things arose while brainstorming about what should be captured in a La1r structured event bus:
> This list will probably be extended in the (near) future

* Actuators - such as lights that can dim of switch, these can be binary, stepped or by value.
* Sensors - such as temperature, presence, location or humidity sensors
* Intent - this can be behavior, derived from manual input from a person, or based on automated (AI) analytics


* Person specificity - is something specific for a person?
* Location specificity - is something specific for a location (in the la1r / outside the la1r)?
* Time specificity - is something specific for a time?
