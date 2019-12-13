# import classic python libs
import itertools
from operator import itemgetter
import numpy as np
import seaborn as sns

# libs for dataframes
import pandas as pd

# import libs for geodata
from shapely.ops import nearest_points
import geopandas as gpd

# import ckdtree
from scipy.spatial import cKDTree
from shapely.geometry import Point, MultiPoint, LineString

# read in roads shapefile
roads = gpd.read_file("data/spatial/roads_studysite_2019/roads_studysite_2019.shp")
roads.head()

# read in checklist covariates for conversion to gpd
# get unique coordinates, assign them to the df
# convert df to geo-df
chkCovars = pd.read_csv("data/eBirdChecklistVars.csv")
unique_locs = chkCovars.drop_duplicates(subset=['longitude','latitude'])[['longitude', 'latitude']]
unique_locs['coordId'] = np.arange(1, unique_locs.shape[0]+1)
chkCovars = chkCovars.merge(unique_locs, on=['longitude', 'latitude'])

unique_locs = gpd.GeoDataFrame(
   unique_locs,
    geometry=gpd.points_from_xy(unique_locs.longitude, unique_locs.latitude))
unique_locs.crs = {'init' :'epsg:4326'}

# reproject spatials to 43n epsg 32642
roads = roads.to_crs({'init': 'epsg:32642'})
unique_locs = unique_locs.to_crs({'init': 'epsg:32642'})


# make a function based on geopandas distance
def dist_to_road(point, roads):
    return roads.distance(point).min()


# get distance to nearest road
unique_locs['min_dist_to_lines'] = unique_locs.geometry.apply(dist_to_road, args=(roads,))
# plot histogram
sns.distplot(a=unique_locs['min_dist_to_lines']/1e3)

# write to file
unique_locs = pd.DataFrame(unique_locs.drop(columns='geometry'))
unique_locs = unique_locs.drop(columns='min_dist_to_lines')
unique_locs['dist_road'] = round(unique_locs['dist_road'], 2)
unique_locs.to_csv(path_or_buf="data/locs_dist_to_road.csv", index=False)

# ends here
