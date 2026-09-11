# TEI Renderer — Oxygen TEI CSS

This renderer displays TEI documents natively (as XML) with the visual styling provided by the [oxygen-tei](https://github.com/TEIC/oxygen-tei) CSS framework.

## Setup

1. **Download the CSS stylesheet** into this folder (the same folder as this README):

   ```
   https://raw.githubusercontent.com/TEIC/oxygen-tei/refs/heads/master/oxygen-tei/frameworks/tei/xml/tei/css/tei.css
   ```

   Save it here as `tei.css`. You can do this from the command line with:

   ```
   curl -o tei.css https://raw.githubusercontent.com/TEIC/oxygen-tei/refs/heads/master/oxygen-tei/frameworks/tei/xml/tei/css/tei.css
   ```

2. **Enable the configuration file.** DoTS ships a template, `renderer_config_template.xml`, which is version-controlled but not active by default. Copy or rename it to `renderer_config.xml` (untracked) in the renderer configuration directory:

   ```
   cp renderer_config_template.xml renderer_config.xml
   ```

## That's it

Once `tei.css` is in place and `renderer_config.xml` exists, the TEI renderer is picked up automatically — no further configuration is needed. DoTS resolves the stylesheet path through `renderer_config.xml` and injects the corresponding `xml-stylesheet` processing instruction when this renderer is requested.
