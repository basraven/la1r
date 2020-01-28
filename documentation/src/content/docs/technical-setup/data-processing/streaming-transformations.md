---
title: (Streaming) Transformations
---
# Streaming transformations
A serveral scenario's in la1r, a (streaming) transformation needs to be made to get the raw streaming data in the structured shape.
This is often the case because there are several integrations with commercial-of-the-shelf (COTS) products which do not follow the same structured model.

## Nifi and GUI as default
Transformations should be easily adjustable to quickly fit the changing data needs. For this reason Nifi is used as the default tool for (streaming) data transformations.
This is where Nifi, with its easily adjustable GUI can facilitate for accomodating (with realtime changes).
Using a COTS solution such as Nifi also helps to reduce the amount of code that needs to be written for performing (sometimes insignificant) transformations.