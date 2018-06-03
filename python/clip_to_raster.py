import sys,os
from osgeo import gdal,osr
from gdalconst import *
import subprocess

# Clips a selected input raster to have the exact same projection, extent, and resolution as another
# USAGE: python clip_to_raster.py src clipsrc dst
# INPUTS: src - the raster to reproject
#         clipsrc - the raster to match
# OUTPUT: dst - the output file
# Important: If the pixels in src and clipsrc do not line up exactly, the pixels in SRS will be resampled
# To preserve the extents, even if they have the exact same resolution

# Created by Patrick Broxton (broxtopd@gmail.com)
# Updated 8/8/2017

resampling_list = ('average','near','bilinear','cubic','cubicspline','lanczos','mode','max','min','med','Q1','Q3')

# Optional parameters
def optparse_init():
    """Prepare the option parser for input (argv)"""

    from optparse import OptionParser, OptionGroup
    usage = 'Usage: %prog [options] input_file(s) [output]'
    p = OptionParser(usage)
    p.add_option('-r', '--resample', dest='resample', type='choice', choices=resampling_list,
                    help='Resampling method (%s) - default "near"' % ','.join(resampling_list))     # Resampling method
    p.add_option('-t', '--tr', dest='tr', help='Map Resolution')                # Override output map resolution    
    p.add_option('-s', '--ts', dest='ts', help='Map Size')                      # Override output map size
    p.add_option('-d', '--dstnodata', dest='dstnodata', help='NoData value')    # Add nodata value
    p.set_defaults(resample='near',tr = '',ts = '',dstnodata = '')
    return p
    
if __name__ == '__main__':

    # Parse the command line arguments      
    argv = gdal.GeneralCmdLineProcessor( sys.argv )
    parser = optparse_init()
    options,args = parser.parse_args(args=argv[1:])
    src = args[0]       # src
    clipsrc = args[1]   # clipsrc
    dst = args[2]       # dst
    
    resample = options.resample
    tr = options.tr
    ts = options.ts
    dstnodata = options.dstnodata
    
    # Test if there is a problem opening the input data
    ds = gdal.Open(src, GA_ReadOnly)
    if ds is None:
        print('Content-Type: text/html\n')
        print('Could not open ' + src)
        sys.exit(1)
        
    ds = gdal.Open(clipsrc, GA_ReadOnly)
    if ds is None:
        print('Content-Type: text/html\n')
        print('Could not open ' + clipsrc)
        sys.exit(1)
        
    # Read the georeferecing info on the raster_to_match
    transform = ds.GetGeoTransform()
    wkt = ds.GetProjection()
    rows = ds.RasterYSize
    cols = ds.RasterXSize
    ulx = transform[0]
    uly = transform[3]
    pixelWidth = transform[1]
    pixelHeight = transform[5]
    lrx = ulx + (cols * pixelWidth)
    lry = uly + (rows * pixelHeight)
    te = str(ulx) + ' ' + str(lry) + ' ' + str(lrx) + ' ' + str(uly)
    srs = osr.SpatialReference()
    srs.ImportFromWkt(wkt)
    proj4 = srs.ExportToProj4()
        
    # Build Argument list for gdalwarp based on the program inputs
    args = ''
    if ts != '':
        args += ' -ts ' + ts
    elif tr!= '':
        args += ' -tr ' + tr
    else:
        args += ' -tr ' + str(pixelWidth) + ' ' + str(pixelHeight)
    if dstnodata != '':
        args += ' -dstnodata ' + dstnodata

    # Reproject the input_raster to match the raster_to_match
    cmd = 'gdalwarp' + args + ' -te ' + te + ' -multi -r ' + resample + ' -overwrite -t_srs "' + proj4 + '" "' + src + '" "' + dst + '"'
    subprocess.call(cmd, shell=True) 
    