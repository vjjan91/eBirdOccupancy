from libpysal.weights.contiguity import Queen
import libpysal
from libpysal import examples
import matplotlib.pyplot as plt

import pandas_bokeh
from splot.libpysal import plot_spatial_weights
from bokeh.io import export_png

# libs for dataframes
import pandas as pd

# import libs for geodata
from shapely.geometry import Point, MultiPoint
from shapely.ops import nearest_points
import geopandas as gpd

# read in roads shapefile
roads = gpd.read_file("data/spatial/roads_studysite_2019/roads_studysite_2019.shp")
roads.head()

# read in checklist covariates for conversion to gpd
checklistCovars = pd.read_csv("data/eBirdChecklistVars.csv")
gdf = gpd.GeoDataFrame(
    checklistCovars,
    geometry=gpd.points_from_xy(checklistCovars.longitude, checklistCovars.latitude))


# define function for nearest neighbour
def nearest(row, geom_union, df1, df2, geom1_col='geometry',
            geom2_col='geometry', src_column=None):
    """Find the nearest point and return the corresponding value from specified column."""
    # Find the geometry that is closest
    this_nearest = df2[geom2_col] == nearest_points(row[geom1_col], geom_union)[1]
    # Get the corresponding value from df2 (matching is based on the geometry)
    value = df2[this_nearest][src_column].get_values()[0]
    return value


# make a unary union of the roads shapefile
unary_union = roads.unary_union

gdf['nearest_id'] = gdf.apply(nearest,
                              geom_union=unary_union, df1=gdf, df2=roads,
                              geom1_col='geometry', geom2_col="geometry",
                              src_column = "osm_id",
                              axis=1)
