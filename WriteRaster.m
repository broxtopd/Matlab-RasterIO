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

% USAGE: WriteRaster(data,ofname,varargin)
%   data is a matrix of the raster data
%   ofname is the output raster data file
%   varargin refers to a number of optional parameters corresponding mostly to GDAL command line arguments
%       CopyProj: copy projection information from another file (Make sure
%       that the data array and the file should match
%       geo: Pass in a georeferencing structure (like the one that was read
%       by 'ReadRaster'
%       a_nodata - nodata value to be assigned to the output file
%       ot - output type of the output file 'Byte','Int16','UInt16',
%         'UInt32','Int32','Float32','Float64','CInt16','CInt32',
%         'CFloat32','CFloat64'
%       of - output file format.  This parameter is required if output
%         is anything other than a geotiff.  For a list of output
%         types, enter '!gdal_translate --long-usage'
% EXAMPLE: Read SWE.tif or SWE.asc
%          data = ReadRaster('DEMO/SWE.asc');
%          data = ReadRaster('DEMO/SWE.tif');
%          % Read a subsetted area of SWE.tif
%          [data2,geo] = ReadRaster('DEMO/SWE.tif','te',[-110 35 -90 45]); 
%          % Create 2-D Matrix of x and y coordinates
%          x = repmat(geo.x,[geo.sz(1) 1]);
%          y = repmat(geo.y,[1 geo.sz(2)]);
%          % Writes Raster data with georefererencing information from the
%          % geo struct and from a file
%          WriteRaster(data2,'DEMO/SWE2.tif','geo',geo)
%          WriteRaster(data,'DEMO/SWE3.tif','CopyProj','DEMO/SWE.tif')
%           % Writes an ASC file instead of a tif
%          WriteRaster(data,'DEMO/SWE3.asc','CopyProj','DEMO/SWE.tif','of','AAIGrid')


function WriteRaster(data,ofname,varargin)
    p = inputParser;
    ot_expected = {'Byte','Int16','UInt16','UInt32','Int32','Float32','Float64','CInt16','CInt32','CFloat32','CFloat64'};
    of_expected = {'GTiff','NTIF','HFA','ELAS','AAIGrid','DTED','PNG','JPEG','GIF','XPM','BMP','PCIDSK','PCRaster', ...
    'ILWIS','SGI','SRTMHGT','Leveller','Terragen','GMT','netCDF','HDF4Image','ISIS2','ERS','FIT','RMF','RST','INGR', ...
    'GSAG','GSBG','GS7BG','R','PNM','ENVI','EHdr','PAux','MEF','MEF2','BT','LAN','IDA','LCP','GTX','NTv2','CTable2', ...
    'KRO','ROI_PAC','ARG''USGSDEM','KEA','ADRG','BLX','SAGA','KMLSUPEROVERLAY','XYZ','HF2','ZMap'};
    
    addRequired(p,'data',@isnumeric);
    addRequired(p,'ofname',@ischar);
    addParameter(p,'CopyProj','',@ischar);
    addParameter(p,'geo',[],@isstruct);
    addParameter(p,'a_nodata',[],@isnumeric);
    addParameter(p,'ot','',@(x) any(validatestring(x,ot_expected)));
    addParameter(p,'of','',@(x) any(validatestring(x,of_expected)));
    parse(p,data,ofname,varargin{:});
    CopyProj = p.Results.CopyProj;
    geo = p.Results.geo;
    a_nodata = p.Results.a_nodata;
    if ~isempty(geo)
        if isempty(a_nodata) && ~strcmp(geo.nodatavalue,'None')
             a_nodata = geo.nodatavalue;
        end
    end
    ot = p.Results.ot;
    of = p.Results.of;
    
    fpath = [fileparts(mfilename('fullpath')) filesep 'scripts'];
    addpath(fpath);
    imwrite2tif(data,[],ofname,class(data));
    rmpath(fpath);
    if ~isempty(CopyProj)
        fullpath = mfilename('fullpath');
        [pathstr,~,~] = fileparts(fullpath);
        eval(['!python "' pathstr filesep 'scripts' filesep 'gdalcopyproj.py" "' CopyProj '" "' ofname '"']);
    elseif ~isempty(geo) 
        fullpath = mfilename('fullpath');
        [pathstr,~,~] = fileparts(fullpath);
        arg_str = ['-a_ullr ' num2str([geo.ulx geo.uly geo.lrx geo.lry]) ' -a_srs "' geo.proj4 '"'];
        eval(['!python "' pathstr filesep 'scripts' filesep 'gdal_edit.py" ' arg_str ' "' ofname '"']);
    else
        disp('Warning: No Georeferencing information found...')
    end
    
    if ~isempty(a_nodata) || ~isempty(ot) || ~isempty(of)
        ifname = [tempname '.tif'];
        movefile(ofname,ifname);
        arg_str = '';
        if ~isempty(a_nodata), arg_str = [arg_str '-a_nodata ' a_nodata]; end
        if ~isnan(ot), arg_str = [arg_str '-ot ' num2str(ot)]; end
        if ~isnan(of), arg_str = [arg_str '-of ' num2str(of)]; end
        eval(['!gdal_translate ' arg_str ' "' ifname '" "' ofname '"']);
        delete(ifname);
    end
end
