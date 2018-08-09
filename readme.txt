These functions use gdal to read and write raster data into Matlab (including providing functionality to 
subset, resize, and reproject the raster files before they are read).  These functions require that GDAL 
and a python distribution with GDAL bindings are installed and accessable via the command line.  

ReadRaster

USAGE: [data,geo] = ReadRaster(ifname,varargin)
  data is a matrix of the raster data
  geo is a structure containing the georeferencing information
  ifname is the input raster data file
  varargin refers to a number of optional parameters corresponding mostly to GDAL command line arguments
      MatchRaster: Raster whos georeferencing information to match
        exactly (CAREFUL THAT IF PIXELS OF THE SOURCE RASTER DON'T LINE UP EXACTLY WITH THOSE IN THE MATCH
        RASTER, THEY WILL BE RESAMPLED)
      te: ulx lry lrx ul - bounding box to subset the data (the actual
      map extents will line up to the pixel boundaries, thus preserving the original data)
      t_srs - target projection for input file
      r - resampling method
      tr - resolution
      ts - size
      a_nodata - add a nodata value

WriteRaster

 USAGE: WriteRaster(data,ofname,varargin)
  data is a matrix of the raster data
  ofname is the output raster data file
  varargin refers to a number of optional parameters corresponding mostly to GDAL command line arguments
      CopyProj: copy projection information from another file (Make sure
      that the data array and the file should match
      geo: Pass in a georeferencing structure (like the one that was read
        by 'ReadRaster'
      a_nodata - nodata value to be assigned to the output file
      ot - output type of the output file 'Byte','Int16','UInt16',
        'UInt32','Int32','Float32','Float64','CInt16','CInt32',
        'CFloat32','CFloat64'
      of - output file format.  This parameter is required if output
        is anything other than a geotiff.  For a list of output
        types, enter '!gdal_translate --long-usage'

EXAMPLE: Read SWE.tif or SWE.asc
         data = ReadRaster('DEMO/SWE.asc');
         data = ReadRaster('DEMO/SWE.tif');
         % Read a subsetted area of SWE.tif
         [data2,geo] = ReadRaster('DEMO/SWE.tif','te',[-110 35 -90 45]); 
         % Create 2-D Matrix of x and y coordinates
         x = repmat(geo.x,[geo.sz(1) 1]);
         y = repmat(geo.y,[1 geo.sz(2)]);
         % Writes Raster data with georefererencing information from the
         % geo struct and from a file
         WriteRaster(data2,'DEMO/SWE2.tif','geo',geo)
         WriteRaster(data,'DEMO/SWE3.tif','CopyProj','DEMO/SWE.tif')
         % Writes an ASC file instead of a tif
         WriteRaster(data,'DEMO/SWE3.asc','CopyProj','DEMO/SWE.tif','of','AAIGrid')

