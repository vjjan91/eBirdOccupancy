# code to get spatial variograms

# check python path
import sys

# should yield python 3.7 file path
for p in sys.path:
    print(p)

import pandas as pd # similar to dplyr! yay!
import os  # has list dir functions etc
import numpy as np  # some matrix functions
from scipy import misc
import matplotlib.pyplot as plt

# read in image

# check the current working directory
os.getcwd()
currentWd = p # os.path.dirname(os.path.abspath(__file__)) #os.getcwd()

# gather chelsa file folder
outputFolder = os.path.join(currentWd, "data/chelsa")

# gather chelsafiles
imgFiles = list()
for root, directories, filenames in os.walk(outputFolder):
    for filename in filenames:
        imgFiles.append(os.path.join(root, filename))

# subset for cropped rasters
imgFiles = list(filter(lambda x: "crop" in x, imgFiles))

# define a custom function to read in


def funcReadAndSelect (x):
    assert "str" in str(type(x)), "input doesn't seem to be a filepath"
    image = misc.imread(x)
    return image


# read in data
imgData = list(map(funcReadAndSelect, imgFiles))

# load gstat and make variograms
# make variogram
from skgstat import Variogram
landSize = imgData[1].shape[1] # a is an example landscape read in earlier
sampleSize = 1000



# define a custom function for variograms
def funcVariogram (img):
    assert "array" in str(type(img)), "image needs to be a numpy array"
    # handle the zero octave completely homogeneous landscapes
    coords = np.random.randint(0, landSize - 1, (sampleSize, 2))
    values = np.fromiter((img[c[0], c[1]] for c in coords), dtype=float)
    v = Variogram(coords, values, model="spherical", normalize=False, n_lags=20)
    return v


# map variogram over imgdata
vgramData = list(map(funcVariogram, imgData))

# to be continued