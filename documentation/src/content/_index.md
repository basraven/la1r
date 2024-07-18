---
title: La1r
type: docs
bookToc: false
---

## Blog with an overview of my homelab
```Source: https://github.com/basraven/la1r```


### Technical Architecture
[Read more](docs/technical-architecture/)

### Planning
[Read more](docs/planning/)

### Why this site?
Especially for myself


{{< hint info >}}
**Override Mermaid Initialization Config**

To override the [initialization config](https://mermaid-js.github.io/mermaid/#/Setup) for Mermaid,
create a `mermaid.json` file in your `assets` folder!
{{< /hint >}}

## Example


<div class="book-columns flex flex-wrap">
  <div class="flex-even markdown-inner">

```tpl
{{</* mermaid class="optional" >}}
flowchart TD
    A[Christmas] -->|Get money| B(Go shopping)
    B --> C{Let me think}
    C -->|One| D[Laptop]
    C -->|Two| E[iPhone]
    C -->|Three| F[fa:fa-car Car]

{{< /mermaid */>}}
```

  </div>
  <div class="flex-even markdown-inner">

{{< mermaid class="optional" >}}
flowchart TD
 b --> a
{{< /mermaid >}}

  </div>
</div>