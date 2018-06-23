# Get georeferencing information from a raster file and print to text file
#
###############################################################################
# Copyright (c) 2018, Patrick Broxton
# 
#  Permission is hereby granted, free of charge, to any person obtaining a
#  copy of this software and associated documentation files (the "Software"),
#  to deal in the Software without restriction, including without limitation
#  the rights to use, copy, modify, merge, publish, distribute, sublicense,
#  and/or sell copies of the Software, and to permit persons to whom the
#  Software is furnished to do so, subject to the following conditions:
# 
#  The above copyright notice and this permission notice shall be included
#  in all copies or substantial portions of the Software.
# 
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
#  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
#  THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
#  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
#  DEALINGS IN THE SOFTWARE.
###############################################################################

import sys,os
import gdal,osr
from gdalconst import *

src = sys.argv[1]
fname_out = sys.argv[2]

ds = gdal.Open(src, GA_ReadOnly)
if ds is None:
    print('Content-Type: text/html\n')
    print('Could not open ' + src)
    sys.exit(1)

# Get the geotransform, the georeferencing, and the dimensions of the raster to match
transform = ds.GetGeoTransform()
rows = ds.RasterYSize
cols = ds.RasterXSize
ulx = transform[0]
uly = transform[3]
pixelWidth = transform[1]
pixelHeight = transform[5]
lrx = ulx + (cols * pixelWidth)
lry = uly + (rows * pixelHeight)
wkt = ds.GetProjection()
srs = osr.SpatialReference()
srs.ImportFromWkt(wkt)
proj4string = srs.ExportToProj4().strip()
nodata = ds.GetRasterBand(1).GetNoDataValue()
ds = None

# Write the output file
f_out = open(fname_out, 'w')
f_out.write(str(pixelWidth) + '\n')
f_out.write(str(pixelHeight) + '\n')
f_out.write(str(ulx) + '\n')
f_out.write(str(uly) + '\n')
f_out.write(str(lrx) + '\n')
f_out.write(str(lry) + '\n')
f_out.write(proj4string + '\n')
f_out.write(str(nodata) + '\n')
f_out.close()
