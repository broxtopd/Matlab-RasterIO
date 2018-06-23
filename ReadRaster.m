% USES GDAL to read both the data and georeferencing from a raster data
% file

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2018, Patrick Broxton
% 
%  Permission is hereby granted, free of charge, to any person obtaining a
%  copy of this software and associated documentation files (the "Software"),
%  to deal in the Software without restriction, including without limitation
%  the rights to use, copy, modify, merge, publish, distribute, sublicense,
%  and/or sell copies of the Software, and to permit persons to whom the
%  Software is furnished to do so, subject to the following conditions:
% 
%  The above copyright notice and this permission notice shall be included
%  in all copies or substantial portions of the Software.
% 
%  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
%  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
%  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
%  THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
%  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
%  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
%  DEALINGS IN THE SOFTWARE.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% USAGE: [data,geo] = ReadRaster(ifname,varargin)
%   data is a matrix of the raster data
%   geo is a structure containing the georeferencing information
%   ifname is the input raster data file
%   varargin refers to a number of optional parameters corresponding mostly to GDAL command line arguments
%       MatchRaster: Raster whos georeferencing information to match
%       exactly (CAREFUL THAT IF PIXELS OF THE SOURCE RASTER DON'T LINE UP EXACTLY WITH THOSE IN THE MATCH
%       RASTER, THEY WILL BE RESAMPLED)
%       te: ulx lry lrx ul - bounding box to subset the data (the actual
%       map extents will line up to the pixel boundaries, thus preserving the original data)
%       t_srs - target projection for input file
%       r - resampling method
%       tr - resolution
%       ts - size
%       a_nodata - add a nodata value
% EXAMPLE: Read SWE.tif or SWE.asc
%          data = ReadRaster('DEMO/SWE.asc');
%          data = ReadRaster('DEMO/SWE.tif');
%          % Read a subsetted area of SWE.tif
%          [data2,geo] = ReadRaster('DEMO/SWE.tif','te',[-110 35 -90 45]); 
%          % Create 2-D Matrix of x and y coordinates
%          x = repmat(geo.x,[geo.size(1) 1]);
%          y = repmat(geo.y,[1 geo.size(2)]);
%          % Writes Raster data with georefererencing information from the
%          % geo struct and from a file
%          WriteRaster(data2,'DEMO/SWE2.tif','geo',geo)
%          WriteRaster(data,'DEMO/SWE3.tif','CopyProj','DEMO/SWE.tif')
%          % Writes an ASC file instead of a tif
%          WriteRaster(data,'DEMO/SWE3.asc','CopyProj','DEMO/SWE.tif','of','AAIGrid')

function [data,geo] = ReadRaster(ifname,varargin)
    p = inputParser;
    r_expected = {'average','near','bilinear','cubic','cubicspline','lanczos','mode','max','min','med','Q1','Q3'};

    addRequired(p,'ifname',@ischar);
    addParameter(p,'MatchRaster','',@ischar);
    addParameter(p,'t_srs','',@ischar);
    addParameter(p,'te',[],@isnumeric);
    addParameter(p,'r','',@(x) any(validatestring(x,r_expected)));
    addParameter(p,'tr',[],@isnumeric);
    addParameter(p,'ts',[],@isnumeric);
    addParameter(p,'a_nodata',[],@isnumeric);
    parse(p,ifname,varargin{:});
    te = p.Results.te;
    MatchRaster = p.Results.MatchRaster;
    t_srs = p.Results.t_srs;
    r = p.Results.r;
    tr = p.Results.tr;
    ts = p.Results.ts;
    a_nodata = p.Results.a_nodata;
    
    [~,~,ext] = fileparts(ifname);

    if ~isempty(MatchRaster)
        ofname = [tempname '.tif'];
        arg_str = '';
        if ~isempty(r), arg_str = [arg_str '-r ' r]; end
        if ~isnan(tr), arg_str = [arg_str '-t ' num2str(tr)]; end
        if ~isnan(ts), arg_str = [arg_str '-s ' num2str(ts)]; end
        if ~isnan(a_nodata), arg_str = [arg_str '-d ' num2str(a_nodata)]; end
        fullpath = mfilename('fullpath');
        [pathstr,~,~] = fileparts(fullpath);
        eval(['!python "' pathstr filesep 'scripts' filesep 'clip_to_raster.py" ' arg_str ' "' ifname '" "' MatchRaster '" "' ofname '"']);
        [ulx,uly,lrx,lry,pixelWidth,pixelHeight,proj4string,nodatavalue] = getgeorefinfo(ofname);
        data = imread(ofname);
        delete(ofname);
    elseif isempty(t_srs) && (~isempty(te) || ~isempty(tr) || ~isempty(ts) || ~isempty(a_nodata) || ~strcmpi(ext,'.tif'))
        ofname = [tempname '.tif'];
        arg_str = '';
        if ~isempty(r), arg_str = [arg_str ' -r ' r]; end
        if ~isnan(tr), arg_str = [arg_str ' -tr ' num2str(tr)]; end
        if ~isnan(ts), arg_str = [arg_str ' -outsize ' num2str(ts)]; end
        if ~isnan(te), projwin = num2str([te(1) te(4) te(3) te(2)]); arg_str = [arg_str ' -projwin ' num2str(projwin)]; end
        if ~isnan(a_nodata), arg_str = [arg_str ' -a_nodata ' num2str(a_nodata)]; end
        eval(['!gdal_translate ' arg_str ' "' ifname '" "' ofname '"']);
        [ulx,uly,lrx,lry,pixelWidth,pixelHeight,proj4string,nodatavalue] = getgeorefinfo(ofname);
        data = imread(ofname);
        delete(ofname);
   	elseif ~isempty(t_srs)
        ofname = [tempname '.tif'];
        arg_str = '';
        if ~isempty(t_srs), arg_str = [arg_str ' -t_srs "' t_srs '"']; end
        if ~isempty(r), arg_str = [arg_str ' -r ' r]; end
        if ~isnan(tr), arg_str = [arg_str ' -tr ' num2str(tr)]; end
        if ~isnan(ts), arg_str = [arg_str ' -ts ' num2str(ts)]; end
        if ~isnan(te), arg_str = [arg_str ' -te ' num2str(te)]; end
        if ~isnan(a_nodata), arg_str = [arg_str ' -a_nodata ' num2str(a_nodata)]; end
        eval(['!gdalwarp ' arg_str ' "' ifname '" "' ofname '"']);
        [ulx,uly,lrx,lry,pixelWidth,pixelHeight,proj4string,nodatavalue] = getgeorefinfo(ofname);
        data = imread(ofname);
        delete(ofname);     
    else
        [ulx,uly,lrx,lry,pixelWidth,pixelHeight,proj4string,nodatavalue] = getgeorefinfo(ifname);
        data = imread(ifname);
    end
    
    ulx = str2double(ulx);
    uly = str2double(uly);
    lrx = str2double(lrx);
    lry = str2double(lry);
    pixelWidth = str2double(pixelWidth);
    pixelHeight = str2double(pixelHeight);
    sz = size(data);
    dx = (lrx - ulx) / sz(2);
    dy = (uly - lry) / sz(1);
    x = ulx + dx/2 : dx : lrx - dx/2;
    y = (uly - dy/2 : -dy : lry + dy/2)';
    
    geo.ulx = ulx;
    geo.uly = uly;
    geo.lrx = lrx;
    geo.lry = lry;
    geo.dx = pixelWidth;
    geo.dy = -pixelHeight;
    geo.sz = sz;
    geo.x = x;
    geo.y = y;
    geo.proj4 = proj4string;
    geo.nodatavalue = nodatavalue;
end

function [ulx,uly,lrx,lry,pixelWidth,pixelHeight,proj4string,nodatavalue] = getgeorefinfo(ifname)
% Use the python gdal bindings to provide simple georeferencing information 
% (python program generates a text file, which is read here)

    fullpath = mfilename('fullpath');
    [pathstr,~,~] = fileparts(fullpath);
    
    ofname = [tempname '.txt'];
    eval(['!python "' pathstr filesep 'scripts' filesep 'geotiffinfo.py" "' ifname '" "' ofname '"']);
    fid = fopen(ofname);
    pixelWidth = fgetl(fid);
    pixelHeight = fgetl(fid);
    ulx = fgetl(fid);
    uly = fgetl(fid);
    lrx = fgetl(fid);
    lry = fgetl(fid);
    proj4string = fgetl(fid);
    nodatavalue = fgetl(fid);
    fclose(fid);
    delete(ofname);
end
