# code for fast ckdtree based nearest neighbour searching

import geopandas as gpd
import numpy as np
import pandas as pd

from scipy.spatial import cKDTree
from shapely.geometry import Point

gpd1 = gpd.GeoDataFrame([['John', 1, Point(1, 1)], ['Smith', 1, Point(2, 2)],
                         ['Soap', 1, Point(0, 2)]],
                        columns=['Name', 'ID', 'geometry'])
gpd2 = gpd.GeoDataFrame([['Work', Point(0, 1.1)], ['Shops', Point(2.5, 2)],
                         ['Home', Point(1, 1.1)]],
                        columns=['Place', 'geometry'])

def ckdnearest(gdA, gdB):
    nA = np.array(list(zip(gdA.geometry.x, gdA.geometry.y)) )
    nB = np.array(list(zip(gdB.geometry.x, gdB.geometry.y)) )
    btree = cKDTree(nB)
    dist, idx = btree.query(nA, k=1)
    gdf = pd.concat(
        [gdA, gdB.loc[idx, gdB.columns != 'geometry'].reset_index(),
         pd.Series(dist, name='dist')], axis=1)
    return gdf

ckdnearest(gpd1, gpd2)

# for points to linestring
import itertools
from operator import itemgetter

import geopandas as gpd
import numpy as np
import pandas as pd

from scipy.spatial import cKDTree
from shapely.geometry import Point, LineString

gpd1 = gpd.GeoDataFrame([['John', 1, Point(1, 1)],
                         ['Smith', 1, Point(2, 2)],
                         ['Soap', 1, Point(0, 2)]],
                        columns=['Name', 'ID', 'geometry'])
gpd2 = gpd.GeoDataFrame([['Work', LineString([Point(100, 0), Point(100, 1)])],
                         ['Shops', LineString([Point(101, 0), Point(101, 1), Point(102, 3)])],
                         ['Home',  LineString([Point(101, 0), Point(102, 1)])]],
                        columns=['Place', 'geometry'])


def ckdnearest(gdfA, gdfB, gdfB_cols=['Place']):
    A = np.concatenate(
        [np.array(geom.coords) for geom in gdfA.geometry.to_list()])
    B = [np.array(geom.coords) for geom in gdfB.geometry.to_list()]
    B_ix = tuple(itertools.chain.from_iterable(
        [itertools.repeat(i, x) for i, x in enumerate(list(map(len, B)))]))
    B = np.concatenate(B)
    ckd_tree = cKDTree(B)
    dist, idx = ckd_tree.query(A, k=1)
    idx = itemgetter(*idx)(B_ix)
    gdf = pd.concat(
        [gdfA, gdfB.loc[idx, gdfB_cols].reset_index(drop=True),
         pd.Series(dist, name='dist')], axis=1)
    return gdf

c = ckdnearest(gpd1, gpd2)