# import classic python libs
import itertools
from operator import itemgetter
import numpy as np
import matplotlib.pyplot as plt
import math

# libs for dataframes
import pandas as pd

# import libs for geodata
from shapely.ops import nearest_points
import geopandas as gpd
import rasterio

# import ckdtree
from scipy.spatial import cKDTree
from shapely.geometry import Point, MultiPoint, LineString, MultiLineString

# read in roads shapefile
roads = gpd.read_file("data/spatial/roads_studysite_2019/roads_studysite_2019.shp")
roads.head()

# read in checklist covariates for conversion to gpd
# get unique coordinates, assign them to the df
# convert df to geo-df
chkCovars = pd.read_csv("data/eBirdChecklistVars.csv")
unique_locs = chkCovars.drop_duplicates(subset=['longitude','latitude'])[['longitude', 'latitude', 'nSp']]
unique_locs['coordId'] = np.arange(1, unique_locs.shape[0]+1)
chkCovars = chkCovars.merge(unique_locs, on=['longitude', 'latitude'])

unique_locs = gpd.GeoDataFrame(
   unique_locs,
    geometry=gpd.points_from_xy(unique_locs.longitude, unique_locs.latitude))
unique_locs.crs = {'init' :'epsg:4326'}

# reproject spatials to 43n epsg 32643
roads = roads.to_crs({'init': 'epsg:32643'})
unique_locs = unique_locs.to_crs({'init': 'epsg:32643'})


# function to simplify multilinestrings
def simplify_roads(complex_roads):
    simpleRoads = []
    for i in range(len(complex_roads.geometry)):
        feature = complex_roads.geometry.iloc[i]

        if feature.geom_type == "LineString":
            simpleRoads.append(feature)
        elif feature.geom_type == "MultiLineString":
            for road_level2 in feature:
                simpleRoads.append(road_level2)
    return simpleRoads


# function to use ckdtrees for nearest point finding
def ckdnearest(gdfA, gdfB):
    A = np.concatenate(
        [np.array(geom.coords) for geom in gdfA.geometry.to_list()])
    simplified_features = simplify_roads(gdfB)

    B = [np.array(geom.coords) for geom in simplified_features]
    B = np.concatenate(B)
    ckd_tree = cKDTree(B)
    dist, idx = ckd_tree.query(A, k=1)

    return dist


# get distance to nearest road
unique_locs['dist_road'] = ckdnearest(unique_locs, roads)

# write to file
unique_locs = pd.DataFrame(unique_locs.drop(columns='geometry'))
unique_locs['dist_road'] = round(unique_locs['dist_road'], 2)
unique_locs.to_csv(path_or_buf="data/locs_dist_to_road.csv", index=False)

# merge unique locs with chkCovars
chkCovars = chkCovars.merge(unique_locs, on=['latitude', 'longitude', 'coordId'])

# make histogram plots
chkCovars['dist_road'].hist(bins=100, grid=False, )
plt.xlabel("distance to road (m)")
plt.xscale('log')

plt.savefig("figs/fig_dist_roads.png", dpi=300)

# sanity check
# read in unique locs with dist to road
unique_locs = pd.read_csv("data/locs_dist_to_road.csv")
# make geodata
unique_locs = gpd.GeoDataFrame(
   unique_locs,
    geometry=gpd.points_from_xy(unique_locs.longitude, unique_locs.latitude))
unique_locs.crs = {'init': 'epsg:4326'}
unique_locs = unique_locs.to_crs({'init': 'epsg:32643'})

# read in hills
hills = gpd.read_file("data/spatial/hillsShapefile/Nil_Ana_Pal.shp")
hills = hills.to_crs({'init': 'epsg:32643'})

# plot
base = roads.plot(linewidth=0.3)
unique_locs.plot(ax=base, column="dist_road", markersize=0.2,
                 cmap="gnuplot2", legend=True,
                 legend_kwds={'label': "nearest road (m)",
                              'orientation': "horizontal"})
hills.geometry.boundary.plot(ax=base, linewidth=0.8, edgecolor="red",
                             color=None)

plt.savefig("figs/map_dist_roads.png", dpi=300)

# read locs and plot against elev
unique_locs = unique_locs.to_crs({'init': 'epsg:4326'})
coords = [(x, y) for x, y in zip(unique_locs.longitude, unique_locs.latitude)]

# Open the raster and store metadata
src = rasterio.open('data/elevationHills.tif')

# Sample the raster at every point location and store values in DataFrame
unique_locs['elev'] = [x[0] for x in src.sample(coords)]

#### code for nearest neighbour distances ####
# function to use ckdtrees for nearest point finding
def ckdnearest_point(gdfA, gdfB):
    A = np.concatenate(
    [np.array(geom.coords) for geom in gdfA.geometry.to_list()])
    #simplified_features = simplify_roads(gdfB)
    B = np.concatenate(
    [np.array(geom.coords) for geom in gdfB.geometry.to_list()])
    #B = np.concatenate(B)
    ckd_tree = cKDTree(B)
    dist, idx = ckd_tree.query(A, k=[2])
    return dist


# get distance to nearest road
unique_locs['dist_road'] = ckdnearest(unique_locs, roads)

# get distance to nearest other site
unique_locs['nnb'] = ckdnearest_point(unique_locs, unique_locs)

# write to file
unique_locs = pd.DataFrame(unique_locs.drop(columns='geometry'))
unique_locs['dist_road'] = unique_locs['dist_road']
unique_locs['nnb'] = unique_locs['nnb']
unique_locs.to_csv(path_or_buf="data/locs_dist_to_road.csv", index=False)

# merge unique locs with chkCovars
chkCovars = chkCovars.merge(unique_locs, on=['latitude', 'longitude', 'coordId'])

# ends here
