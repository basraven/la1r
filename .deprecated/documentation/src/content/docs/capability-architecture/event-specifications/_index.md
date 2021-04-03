# Event Specifications
The event specifications are a exhaustive list of specifications to which any event should conform.
With specifying this, decoupled and predictable interactions between services can be achieved.

These types of event specifications are currently defined:

* **Content specifications** - Specifications putting requirements on the content of the event
* **Attribute specifications** - Specifications putting requirements on the attributes of an event

## Content specifications

1. All content of an event should be structured in JSON format
1. There cannot be duplicate data between content and attribute data
1. All events should contain a Unix epoch timestamp with Amsterdam as timezone, "unixts" should be formated as ```%i```
1. All events should contain an "origin" reference (e.g. "automated/face-recognition/1")
1. The payload of an event can reference external data with "payload" or can contain string or blob information:
    * Direct string, blob or other payload formats such as a JSON object
    * Direct source path in cephFS (spoofed until ceph is implemented) 
    * Direct protocol link (e.g. tcp://videostream1.bas)
    * Hyperlink (e.g. https://videostream1.la1r.com)

### Content Examples

* **Example 1**, a payload with a link

    ```json
    {
        "unixts" : 1578157000,
        "origin" : "manual/light-switch/6",
        "payload" : "tcp://videostream1.la1r.com"

    }
    ```

* **Example 2**, a payload with a JSON blob

    ```json
    {
        "unixts" : 1577157000,
        "origin" : "automated/picture-on-login/pc-1",
        "payload" : {
            "online-time-seconds" : 3212,
            "capture-location" : "/captures/temp/weekly-cleaned/picture-on-login/pc-1/1.jpeg"
        }

    }
    ```

## Attribute specifications

1. The topic modelling standard should be applied on any event published
1. Attributes need to be as specific as possible, it should not attempt to group multiple entities because this can be achieved by more advanced queries in the event bus protocol by the use of wildcards.

### Topic modelling standard
Topic modelling is a conceptual architectural decision which should be made very conscious of future extensions.
Large refactor movements in the conceptual structure of an Event bus can have a major change impact because many applications need to change their way of interacting.

### What needs to be captured in topics
The following things arose while brainstorming about what should be captured in a La1r structured event bus:
> This list will probably be extended in the (near) future

* Any of the flow types
  * Actuator - such as lights that can dim of switch, these can be binary, stepped or by value.
  * Sensor - such as temperature, presence, location or humidity sensors
  * Intent - this can be behavior, derived from manual input from a person, or based on automated (AI) analytics
* Location specificity - is something specific for a location (in the la1r / outside the la1r)? Numbering with "-%i" as template. "-" if not location specific.
* Person or device specificity - is something specific for a person or device? Numbering with "-%i" as template. "-" if not person or device specific.

### Topic hierarchy
Taking this into consideration, all events in the structured event bus need to following this topic hierarchy (all lower case, without spaces or special characters), either indirect by translation from the raw event bus or direct when considering these standards:

```shell
<flow type>/<Location specification>/<Person or device specification>
```

#### Examples of hierarchy usage

* Example 1 - turing off light 1 in the living room

    ```shell
    actuator/living-room/lightswitch-1
    ```

* Example 2 - security camera 1 sensing an unidentified person

    ```shell
    sensor/front-door/doorbel-camera-1
    ```

* Example 3 - analysis algo 1 predicts an intent to shutdown all lights in the backyard

    ```shell
    intent/backyard/lightswitch-all
    ```
