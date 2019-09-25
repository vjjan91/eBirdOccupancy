<!DOCTYPE qgis PUBLIC 'http://mrcc.com/qgis.dtd' 'SYSTEM'>
<qgis minScale="1e+08" styleCategories="AllStyleCategories" version="3.4.6-Madeira" hasScaleBasedVisibilityFlag="0" maxScale="0">
  <flags>
    <Identifiable>1</Identifiable>
    <Removable>1</Removable>
    <Searchable>1</Searchable>
  </flags>
  <customproperties>
    <property key="WMSBackgroundLayer" value="false"/>
    <property key="WMSPublishDataSourceUrl" value="false"/>
    <property key="embeddedWidgets/count" value="0"/>
    <property key="identify/format" value="Value"/>
  </customproperties>
  <pipe>
    <rasterrenderer opacity="1" band="1" type="paletted" alphaBand="-1">
      <rasterTransparency/>
      <minMaxOrigin>
        <limits>None</limits>
        <extent>WholeRaster</extent>
        <statAccuracy>Estimated</statAccuracy>
        <cumulativeCutLower>0.02</cumulativeCutLower>
        <cumulativeCutUpper>0.98</cumulativeCutUpper>
        <stdDevFactor>2</stdDevFactor>
      </minMaxOrigin>
      <colorPalette>
        <paletteEntry color="#ffffff" value="0" alpha="255" label="0"/>
        <paletteEntry color="#1f4dcc" value="1" alpha="255" label="1"/>
        <paletteEntry color="#e21cb4" value="2" alpha="255" label="2"/>
        <paletteEntry color="#d23f3f" value="3" alpha="255" label="3"/>
        <paletteEntry color="#edb60e" value="4" alpha="255" label="4"/>
        <paletteEntry color="#67cc80" value="5" alpha="255" label="5"/>
        <paletteEntry color="#b57eef" value="6" alpha="255" label="6"/>
        <paletteEntry color="#97da54" value="7" alpha="255" label="7"/>
      </colorPalette>
      <colorramp name="[source]" type="randomcolors"/>
    </rasterrenderer>
    <brightnesscontrast brightness="0" contrast="0"/>
    <huesaturation grayscaleMode="0" colorizeOn="0" colorizeGreen="128" colorizeStrength="100" colorizeRed="255" colorizeBlue="128" saturation="0"/>
    <rasterresampler maxOversampling="2"/>
  </pipe>
  <blendMode>0</blendMode>
</qgis>
