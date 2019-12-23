// code to access ESA globcover and save to drive

var image = ee.Image("ESA/GLOBCOVER_L4_200901_200912_V2_3"),
    table = ee.FeatureCollection("users/pratik_unterwegs/WG");
var landcover = image.select('landcover'). // clip by wg shapefile
    clip(table.geometry());

Map.addLayer(landcover, {}, 'Landcover'); // vis in GEE

// export to drive at 300m res
Export.image.toDrive({
   image: image,
   description: 'glob_cover_wghats',
   scale: 300,
  region: table.geometry().bounds()});