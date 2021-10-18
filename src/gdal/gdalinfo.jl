"""
get detailed GDAL information

## return
- `file`     : 
- `range`    : [lon_min, lon_max, lat_min, lat_max]
- `cellsize` : [dx, dy]
- `lon`      : longitudes with the length of nlon
- `lat`      : latitudes with the length of nlat
- `dim`      : [width, height]
- `ntime`    : length of time
"""
function gdalinfo(file::AbstractString) 
    ds = ArchGDAL.read(file)
    gt = ArchGDAL.getgeotransform(ds)
    # band = ArchGDAL.getband(ds, 1)
    w, h = ArchGDAL.width(ds), ArchGDAL.height(ds)
    dx, dy = gt[2], -gt[end]
    x0 = gt[1] #+ dx/2
    x1 = x0 + w* dx
    y1 = gt[4] #- dy/2
    y0 = y1 - h*dy
    rbbox = box(x0, y0, x1, y1)
    
    lon = x0 + dx/2 : dx: x1
    lat = reverse(y0 + dy/2 : dy: y1)
    nband = ArchGDAL.nraster(ds)
    
    Dict(
        "file"     => basename(file),
        "bbox"     => rbbox, 
        "cellsize" => [dx, dy], 
        "coords"    => [lon, lat],
        "dim"      => [w, h, nband])
end

function gdalinfo(ga::GeoArray)
    # mid = [1, 1];
    # if length(mid) == 1; mid = [mid, mid]; end
    dx = ga.f.linear[1]
    dy = abs(ga.f.linear[4])
    dy2 = ga.f.linear[4]
    
    mid = [1, 1]
    delta = [dx, dy]/2 .* mid
    
    rbbox = st_bbox(ga)
    lon = rbbox.xmin + delta[1]:dx:rbbox.xmax
    lat = rbbox.ymin + delta[2]:dy:rbbox.ymax
    if dy2 < 0; lat = reverse(lat); end

    Dict(
        "bbox"     => rbbox, 
        "cellsize" => [dx, dy], 
        "coords"    => [lon, lat],
        "dim"      => size(ga.A))
end

gdal_open(file::AbstractString) = ArchGDAL.read(file)

function nband(file::AbstractString)
    # ArchGDAL.unsafe_read(file) do ds
    ArchGDAL.read(file) do ds
        ArchGDAL.nraster(ds)
    end
end
nratser = nband

export gdalinfo, nband, gdal_open
