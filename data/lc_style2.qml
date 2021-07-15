<!DOCTYPE qgis PUBLIC 'http://mrcc.com/qgis.dtd' 'SYSTEM'>
<qgis version="3.20.0-Odense" hasScaleBasedVisibilityFlag="0" minScale="1e+08" maxScale="0" styleCategories="AllStyleCategories">
  <flags>
    <Identifiable>1</Identifiable>
    <Removable>1</Removable>
    <Searchable>1</Searchable>
    <Private>0</Private>
  </flags>
  <temporal fetchMode="0" mode="0" enabled="0">
    <fixedRange>
      <start></start>
      <end></end>
    </fixedRange>
  </temporal>
  <customproperties>
    <Option type="Map">
      <Option type="bool" value="false" name="WMSBackgroundLayer"/>
      <Option type="bool" value="false" name="WMSPublishDataSourceUrl"/>
      <Option type="int" value="0" name="embeddedWidgets/count"/>
      <Option type="QString" value="Value" name="identify/format"/>
    </Option>
  </customproperties>
  <pipe>
    <provider>
      <resampling zoomedInResamplingMethod="nearestNeighbour" maxOversampling="2" zoomedOutResamplingMethod="nearestNeighbour" enabled="false"/>
    </provider>
    <rasterrenderer type="paletted" band="1" alphaBand="-1" nodataColor="" opacity="1">
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
        <paletteEntry color="#70ad5c" label="Evergreen Forest" value="1" alpha="255"/>
        <paletteEntry color="#a3b061" label="Deciduous Forest" value="2" alpha="255"/>
        <paletteEntry color="#ccb267" label="Mixed/Degraded Forest" value="3" alpha="255"/>
        <paletteEntry color="#f7d0f1" label="Agriculture/Settlement" value="4" alpha="255"/>
        <paletteEntry color="#e7c786" label="Grassland" value="5" alpha="255"/>
        <paletteEntry color="#e5d5b4" label="Plantation" value="7" alpha="255"/>
        <paletteEntry color="#1f78b4" label="Waterbody" value="9" alpha="255"/>
      </colorPalette>
      <colorramp type="gradient" name="[source]">
        <Option type="Map">
          <Option type="QString" value="112,173,92,255" name="color1"/>
          <Option type="QString" value="226,226,226,255" name="color2"/>
          <Option type="QString" value="0" name="discrete"/>
          <Option type="QString" value="gradient" name="rampType"/>
          <Option type="QString" value="0.016;117,173,92,255:0.032;123,174,93,255:0.048;128,174,93,255:0.063;133,174,94,255:0.079;138,174,94,255:0.095;143,175,95,255:0.111;147,175,95,255:0.127;152,175,96,255:0.143;157,175,96,255:0.159;161,176,97,255:0.175;165,176,97,255:0.19;170,176,98,255:0.206;174,176,98,255:0.222;178,176,99,255:0.238;182,177,99,255:0.254;186,177,100,255:0.27;190,177,100,255:0.286;193,177,101,255:0.302;197,178,101,255:0.317;201,178,102,255:0.333;204,178,103,255:0.349;208,178,103,255:0.365;211,179,104,255:0.381;214,179,104,255:0.397;217,179,105,255:0.413;220,180,106,255:0.429;223,180,106,255:0.444;225,181,107,255:0.46;227,182,107,255:0.476;229,182,108,255:0.492;230,184,109,255:0.508;230,185,110,255:0.524;231,186,111,255:0.54;231,188,112,255:0.556;231,189,114,255:0.571;231,191,116,255:0.587;231,192,118,255:0.603;231,194,121,255:0.619;231,195,123,255:0.635;231,196,127,255:0.651;231,198,130,255:0.667;231,199,134,255:0.683;231,201,138,255:0.698;231,202,142,255:0.714;231,203,147,255:0.73;230,205,151,255:0.746;230,206,156,255:0.762;230,207,160,255:0.778;230,209,165,255:0.794;230,210,169,255:0.81;230,211,173,255:0.825;229,212,178,255:0.841;229,214,182,255:0.857;229,215,187,255:0.873;229,216,191,255:0.889;229,218,195,255:0.905;228,219,200,255:0.921;228,220,204,255:0.937;228,221,209,255:0.952;227,223,213,255:0.968;227,224,217,255:0.984;227,225,222,255" name="stops"/>
        </Option>
        <prop k="color1" v="112,173,92,255"/>
        <prop k="color2" v="226,226,226,255"/>
        <prop k="discrete" v="0"/>
        <prop k="rampType" v="gradient"/>
        <prop k="stops" v="0.016;117,173,92,255:0.032;123,174,93,255:0.048;128,174,93,255:0.063;133,174,94,255:0.079;138,174,94,255:0.095;143,175,95,255:0.111;147,175,95,255:0.127;152,175,96,255:0.143;157,175,96,255:0.159;161,176,97,255:0.175;165,176,97,255:0.19;170,176,98,255:0.206;174,176,98,255:0.222;178,176,99,255:0.238;182,177,99,255:0.254;186,177,100,255:0.27;190,177,100,255:0.286;193,177,101,255:0.302;197,178,101,255:0.317;201,178,102,255:0.333;204,178,103,255:0.349;208,178,103,255:0.365;211,179,104,255:0.381;214,179,104,255:0.397;217,179,105,255:0.413;220,180,106,255:0.429;223,180,106,255:0.444;225,181,107,255:0.46;227,182,107,255:0.476;229,182,108,255:0.492;230,184,109,255:0.508;230,185,110,255:0.524;231,186,111,255:0.54;231,188,112,255:0.556;231,189,114,255:0.571;231,191,116,255:0.587;231,192,118,255:0.603;231,194,121,255:0.619;231,195,123,255:0.635;231,196,127,255:0.651;231,198,130,255:0.667;231,199,134,255:0.683;231,201,138,255:0.698;231,202,142,255:0.714;231,203,147,255:0.73;230,205,151,255:0.746;230,206,156,255:0.762;230,207,160,255:0.778;230,209,165,255:0.794;230,210,169,255:0.81;230,211,173,255:0.825;229,212,178,255:0.841;229,214,182,255:0.857;229,215,187,255:0.873;229,216,191,255:0.889;229,218,195,255:0.905;228,219,200,255:0.921;228,220,204,255:0.937;228,221,209,255:0.952;227,223,213,255:0.968;227,224,217,255:0.984;227,225,222,255"/>
      </colorramp>
    </rasterrenderer>
    <brightnesscontrast brightness="0" contrast="0" gamma="1"/>
    <huesaturation colorizeBlue="128" saturation="0" colorizeStrength="100" grayscaleMode="0" colorizeOn="0" colorizeRed="255" colorizeGreen="128"/>
    <rasterresampler maxOversampling="2"/>
    <resamplingStage>resamplingFilter</resamplingStage>
  </pipe>
  <blendMode>0</blendMode>
</qgis>
