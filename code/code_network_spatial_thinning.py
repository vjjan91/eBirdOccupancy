
# import classic python libs
import numpy as np
import matplotlib.pyplot as plt

# libs for dataframes
import pandas as pd

# network lib
import networkx as nx

# import libs for geodata
import geopandas as gpd

# import ckdtree
from scipy.spatial import cKDTree

# read in checklist covariates for conversion to gpd
# get unique coordinates, assign them to the df
# convert df to geo-df
chkCovars = pd.read_csv("data/eBirdChecklistVars.csv")

ul = chkCovars.drop_duplicates(subset=['longitude','latitude'])[['longitude', 'latitude']]
ul['coordId'] = np.arange(0, ul.shape[0])

# get effort proxy at each coord
effort = chkCovars.groupby(['longitude', 'latitude'])['duration'].sum()
effort = effort.reset_index()
effort['coordId'] = np.arange(0, effort.shape[0])

# make gpd and drop col from ul
ulgpd = gpd.GeoDataFrame(ul,
              geometry=gpd.points_from_xy(ul.longitude, ul.latitude))
ulgpd.crs = {'init' :'epsg:4326'}
ul = pd.DataFrame(ul.drop(columns='geometry'))

# reproject spatials to 43n epsg 32642
ulgpd = ulgpd.to_crs({'init': 'epsg:32642'})


# function to use ckdtrees for nearest point finding
def ckd_pairs(gdfA, dist_indep):
    nnbrs = len(gdfA.index)
    A = np.concatenate(
    [np.array(geom.coords) for geom in gdfA.geometry.to_list()])
    ckd_tree = cKDTree(A)
    dist = ckd_tree.query_pairs(r=dist_indep, output_type='ndarray')
    return dist


site_pairs = ckd_pairs(ulgpd, 100)
site_pairs = pd.DataFrame(data=site_pairs, columns=['p1', 'p2'])

# make dict of positions and array of coordinates
site_id = np.concatenate((site_pairs.p1.unique(), site_pairs.p2.unique()))
site_id = np.unique(site_id)
locations_df = ul[ul.coordId.isin(site_id)][['longitude', 'latitude']].to_numpy()
pos_dict = dict(zip(site_id, locations_df))

# make network and plot
b = nx.from_pandas_edgelist(site_pairs, 'p1', 'p2')

# find modules in the network and get effort to each
modules = list(nx.algorithms.community.greedy_modularity_communities(b))

m = []
for i in np.arange(len(modules)):
    module_number = [i]*len(modules[i])
    module_coords = list(modules[i])
    m = m + list(zip(module_number, module_coords))

module_data = pd.DataFrame(m, columns=['module', 'coordId'])
module_data = pd.merge(module_data, ul, on='coordId')
module_data = pd.merge(module_data,
                       effort[['duration', 'coordId']],
                       on='coordId')

# output data
module_data.to_csv(path_or_buf="data/site_modules.csv", index=False)
site_pairs.to_csv(path_or_buf="data/site_pairs.csv", index=False)