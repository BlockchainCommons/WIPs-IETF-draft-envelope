# Preparing Mermaid Images for Inclusion in IETF Internet Drafts

1. Export the Mermaid diagram to a file. Use no styles that represent colors or fills.

`node_case.mermaid:`

```mermaid
graph LR
    1(("8955db5e<br/>NODE"))
    2["13941b48<br/>#quot;Alice#quot;"]
    3(["78d666eb<br/>ASSERTION"])
    4["db7dd21c<br/>#quot;knows#quot;"]
    5["13b74194<br/>#quot;Bob#quot;"]
    1 -->|subj| 2
    1 --> 3
    3 -->|pred| 4
    3 -->|obj| 5
    style 1 stroke-width:3.0px
    style 2 stroke-width:3.0px
    style 3 stroke-width:3.0px
    style 4 stroke-width:3.0px
    style 5 stroke-width:3.0px
    linkStyle 0 stroke-width:2.0px
    linkStyle 1 stroke-width:2.0px
    linkStyle 2 stroke-width:2.0px
    linkStyle 3 stroke-width:2.0px
```

2. Use the [mermaid command line tool](https://github.com/mermaid-js/mermaid-cli) to convert the mermaid file to PDF using the configuration file below.

```zsh!
mmdc --input images/mermaid/node_case.mermaid \
    --output images/pdf/node_case.pdf \
    --outputFormat pdf \
    --configFile mermaid_config.json
```

The `mermaid_convert_to_pdf.sh` script is set up to do this step.

`mermaid_config.json:`

```json
{
    "theme": "default",
    "themeVariables": {
        "fontFamily": "sans-serif",
        "fontSize": "16px",

        "background": "transparent",
        "primaryTextColor" : "black",
        "primaryBorderColor" : "black",
        "primaryColor" : "transparent",
        "secondaryColor" : "transparent",
        "lineColor" : "black",

        "nodeBorder" : "black",
        "clusterBkg" : "transparent",
        "clusterBorder" : "black",
        "defaultLinkColor" : "black",
        "titleColor" : "black",
        "edgeLabelBackground" : "transparent",
        "mainBkg" : "transparent",
        "nodeTextColor" : "black"
    }
}
```

`node_case.pdf:`

![](https://i.imgur.com/4R7RjVC.png)

3. In Illustrator, flatten the image:

* Release all clip groups.
* Outline all text.
* Ungroup all groups.
* Remove the invisible border around the entire page.
* Remove the smaller background fill path behind the content.

![](https://i.imgur.com/ZOGFrpT.png)

4. Use the artboard tools to fit the artboard to the artwork, then expand the artboard to expand the artboard by 50 pixels on both axes.

![](https://i.imgur.com/VZFw49t.png)

5. "Save As..." the file as SVG 1.2 Tiny:

![](https://i.imgur.com/F5SodRN.png)

6. Use the [svgcheck tool](https://github.com/ietf-tools/svgcheck) to repair nonconforming aspects of the file.

```
svgcheck -r \
    images/svg/node_case.svg \
    --out images/svg-validated/node_case.svg
```

7. Remove ` x="0px" y="0px"` and ` id="Layer_1"` from the `svg` element:

```
sed -e "s/ x=\"0px\" y=\"0px\"//g" -i .backup images/svg-validated/node_case.svg
sed -e "s/ id=\"Layer_1\"//g" -i .backup images/svg-validated/node_case.svg
rm images/svg-validated/node_case.svg.backup
```

The `postprocess_mermaid.sh` script does steps 7 and 8.

1. Embed the SVG in the markdown file:

```
<artwork type="svg"><svg...>
</svg></artwork>
```

Linking to the artwork is possible, but doesn't seem to work during submission:

```
<artwork type="svg" src="images/svg-validated/node_case.svg"/>
```

![](https://i.imgur.com/WVciwBs.png)
