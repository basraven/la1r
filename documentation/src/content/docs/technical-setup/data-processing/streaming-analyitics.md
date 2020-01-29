---
title: (Streaming) Analytics
---
# Streaming analyitics as default
Since La1r is applying a Kappa architecture (see [conceptual setup](./conceptual-setup) for more details on this), it is essential that as many of it's processes occur in a streaming fasion.
This also includes all the performed analytics. 
Streaming analytics brings new considerations, such as messaging ordering and quality of prefix data. 
Since these concepts are handled out-of-the-box (OOTB) in Spark 2.x, Spark 2.x is considered as the default method of applying streaming analytics.