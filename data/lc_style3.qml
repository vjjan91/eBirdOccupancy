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
        <paletteEntry color="#4e7758" label="Evergreen Forest" value="1" alpha="255"/>
        <paletteEntry color="#86a47d" label="Deciduous Forest" value="2" alpha="255"/>
        <paletteEntry color="#b7a671" label="Mixed/Degraded Forest" value="3" alpha="255"/>
        <paletteEntry color="#f7d0f1" label="Agriculture/Settlement" value="4" alpha="255"/>
        <paletteEntry color="#d9b979" label="Grassland" value="5" alpha="255"/>
        <paletteEntry color="#d7c8a7" label="Plantation" value="7" alpha="255"/>
        <paletteEntry color="#1f78b4" label="Waterbody" value="9" alpha="255"/>
      </colorPalette>
      <colorramp type="gradient" name="[source]">
        <Option type="Map">
          <Option type="QString" value="102,155,144,255" name="color1"/>
          <Option type="QString" value="212,212,212,255" name="color2"/>
          <Option type="QString" value="0" name="discrete"/>
          <Option type="QString" value="gradient" name="rampType"/>
          <Option type="QString" value="0.016;105,156,142,255:0.032;108,157,140,255:0.048;111,157,138,255:0.063;114,158,136,255:0.079;117,159,135,255:0.095;120,160,133,255:0.111;123,161,131,255:0.127;126,162,129,255:0.143;129,163,128,255:0.159;133,163,126,255:0.175;136,164,124,255:0.19;140,165,123,255:0.206;144,165,121,255:0.222;148,166,120,255:0.238;152,166,119,255:0.254;157,166,117,255:0.27;162,166,116,255:0.286;167,166,115,255:0.302;172,166,114,255:0.317;178,166,114,255:0.333;183,166,113,255:0.349;187,166,112,255:0.365;192,166,112,255:0.381;195,166,111,255:0.397;199,166,110,255:0.413;202,167,110,255:0.429;204,167,109,255:0.444;207,168,108,255:0.46;209,169,107,255:0.476;210,170,107,255:0.492;211,171,106,255:0.508;212,172,105,255:0.524;213,174,105,255:0.54;214,175,105,255:0.556;214,176,106,255:0.571;215,178,107,255:0.587;215,179,108,255:0.603;216,180,110,255:0.619;216,181,112,255:0.635;216,183,115,255:0.651;217,184,118,255:0.667;217,185,121,255:0.683;217,187,125,255:0.698;216,188,129,255:0.714;216,190,134,255:0.73;216,191,138,255:0.746;216,192,142,255:0.762;216,193,147,255:0.778;216,195,151,255:0.794;216,196,156,255:0.81;215,197,160,255:0.825;215,199,164,255:0.841;215,200,169,255:0.857;215,201,173,255:0.873;215,202,177,255:0.889;214,204,182,255:0.905;214,205,186,255:0.921;214,206,190,255:0.937;214,207,195,255:0.952;213,209,199,255:0.968;213,210,204,255:0.984;213,211,208,255" name="stops"/>
        </Option>
        <prop k="color1" v="102,155,144,255"/>
        <prop k="color2" v="212,212,212,255"/>
        <prop k="discrete" v="0"/>
        <prop k="rampType" v="gradient"/>
        <prop k="stops" v="0.016;105,156,142,255:0.032;108,157,140,255:0.048;111,157,138,255:0.063;114,158,136,255:0.079;117,159,135,255:0.095;120,160,133,255:0.111;123,161,131,255:0.127;126,162,129,255:0.143;129,163,128,255:0.159;133,163,126,255:0.175;136,164,124,255:0.19;140,165,123,255:0.206;144,165,121,255:0.222;148,166,120,255:0.238;152,166,119,255:0.254;157,166,117,255:0.27;162,166,116,255:0.286;167,166,115,255:0.302;172,166,114,255:0.317;178,166,114,255:0.333;183,166,113,255:0.349;187,166,112,255:0.365;192,166,112,255:0.381;195,166,111,255:0.397;199,166,110,255:0.413;202,167,110,255:0.429;204,167,109,255:0.444;207,168,108,255:0.46;209,169,107,255:0.476;210,170,107,255:0.492;211,171,106,255:0.508;212,172,105,255:0.524;213,174,105,255:0.54;214,175,105,255:0.556;214,176,106,255:0.571;215,178,107,255:0.587;215,179,108,255:0.603;216,180,110,255:0.619;216,181,112,255:0.635;216,183,115,255:0.651;217,184,118,255:0.667;217,185,121,255:0.683;217,187,125,255:0.698;216,188,129,255:0.714;216,190,134,255:0.73;216,191,138,255:0.746;216,192,142,255:0.762;216,193,147,255:0.778;216,195,151,255:0.794;216,196,156,255:0.81;215,197,160,255:0.825;215,199,164,255:0.841;215,200,169,255:0.857;215,201,173,255:0.873;215,202,177,255:0.889;214,204,182,255:0.905;214,205,186,255:0.921;214,206,190,255:0.937;214,207,195,255:0.952;213,209,199,255:0.968;213,210,204,255:0.984;213,211,208,255"/>
      </colorramp>
    </rasterrenderer>
    <brightnesscontrast brightness="0" contrast="0" gamma="1"/>
    <huesaturation colorizeBlue="128" saturation="0" colorizeStrength="100" grayscaleMode="0" colorizeOn="0" colorizeRed="255" colorizeGreen="128"/>
    <rasterresampler maxOversampling="2"/>
    <resamplingStage>resamplingFilter</resamplingStage>
  </pipe>
  <blendMode>0</blendMode>
</qgis>
