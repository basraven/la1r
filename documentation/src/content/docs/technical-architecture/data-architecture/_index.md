---
title: Data Architecture
type: docs
bookToc: false
bookCollapseSection : false
weight: 4
---
## Data Architecture
There are several setups used in the area of Data Architecture and Data Processing.
They all focus on contribution enhanced "intelligent" decision making in the La1r setup.

### (Streaming) Transformations
Since there can be a large difference between how data is received, for example for commercial of the shelf (COTS) applications, and how it should be structured conforming to the described event standard, there is a need for (streaming) Transformations.

#### Streaming analytics as default
Since La1r is applying a Kappa architecture (see [capability architecture](./conceptual-setup) for more details on this), it is essential that as many of it's processes occur in a streaming fashion.
This also includes all the performed analytics.
Streaming analytics brings new considerations, such as messaging ordering and quality of prefix data.
Since these concepts are handled out-of-the-box (OOTB) in Spark 2.x, Spark 2.x is considered as the default method of applying streaming analytics.

### (Streaming) Analytics
To enhance La1r with intelligent analytics and decision making, streaming analytics is applied to facilitate these needs.

### Streaming transformations
A several scenario's in la1r, a (streaming) transformation needs to be made to get the raw streaming data in the structured shape.
This is often the case because there are several integrations with commercial-of-the-shelf (COTS) products which do not follow the same structured model.

### Nifi and GUI as default
Transformations should be easily adjustable to quickly fit the changing data needs. For this reason Nifi is used as the default tool for (streaming) data transformations.
This is where Nifi, with its easily adjustable GUI can facilitate for accommodating (with realtime changes).
Using a COTS solution such as Nifi also helps to reduce the amount of code that needs to be written for performing (sometimes insignificant) transformations.
