#=
Experimental

Perform an analysis with a 10-year window from the sea floor
=#

#SBATCH --mem-per-cpu=8000

using DIVAnd
using Compat: @info, range
using PyPlot
using NCDatasets
if VERSION >= v"0.7"
    using Dates
    using Statistics
    using Printf
end

include("../src/override_ssmult.jl")
include("./prep_dirs.jl")

# if this script is in /some/path/DIVAnd.jl/examples, the data should be in
# /some/path/DIVAnd-example-data (for Linux, Mac) and likewise for Windows.
fname = joinpath(dirname(@__FILE__),"..","..","DIVAnd-example-data","BlackSea","Salinity.bigfile")
bathname = joinpath(dirname(@__FILE__),"..","..","DIVAnd-example-data","Global","Bathymetry","gebco_30sec_16.nc")
bathisglobal = true

value,lon,lat,depth,time,ids = DIVAnd.loadbigfile(fname)

@show size(value)

dx = dy = 0.1
dx = dy = 0.2
#dx = dy = 0.1
#dx = dy = 0.05
#dx = dy = 0.04
#dx = dy = 0.03
#dx=15.0/(50*16)
#dy=6.0/(15*16)


lonr = 27:dx:42
latr = 40:dy:47


#depthr = [0., 10, 20, 30, 50, 75, 100, 125, 150, 200, 250, 300, 400, 500, 600, 700, 800, 900, 1000, 1100, 1200, 1300, 1400, 1500, 1750, 2000];
depthr = [0.,5, 10, 15, 20, 25, 30, 40, 50, 66, 75, 85, 100, 112, 125, 135, 150, 175, 200, 225, 250, 275, 300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300, 1350, 1400, 1450, 1500, 1600, 1750, 1850, 2000];

#depthr = [0., 5., 10.];
#depthr = 0:10.:30.;

depthr = [0.,20.,50.];

@show size(depthr)

epsilon2 = 0.1
epsilon2 = 0.01

sz = (length(lonr),length(latr),length(depthr))

# correlation length in meters (in x, y, and z directions)
lenx = fill(200_000,sz)
leny = fill(200_000,sz)
lenz = [10+depthr[k]/15 for i = 1:sz[1], j = 1:sz[2], k = 1:sz[3]]

@show mean(lenz)


years = 1993:1994
#years = [1993]

year_window = 10

# winter: January-March    1,2,3
# spring: April-June       4,5,6
# summer: July-September   7,8,9
# autumn: October-December 10,11,12

monthlists = [
    [1,2,3],
    [4,5,6],
    [7,8,9],
    [10,11,12]
];


TS = DIVAnd.TimeSelectorYW(years,year_window,monthlists)

filename = joinpath(outputdir, basename(replace(@__FILE__,r".jl$" => ".nc")))
@info "Output file: " * filename

varname = "Salinity"

timeorigin = DateTime(1900,1,1,0,0,0)

bx,by,b = DIVAnd.extract_bath(bathname,false,lonr,latr);

# plot the results for debugging

function plotres(timeindex,sel,fit,erri)
    tmp = copy(fit)
    tmp[erri .> .5] .= NaN;
    figure()
    subplot(2,1,1)
    title("$(timeindex) - surface")

    selsurface = sel .& (depth .< 5)
    vmin = minimum(value[selsurface])
    vmax = maximum(value[selsurface])

    scatter(lon[selsurface],lat[selsurface],10,value[selsurface];
            cmap = "jet", vmin = vmin, vmax = vmax)
    xlim(minimum(lonr),maximum(lonr))
    ylim(minimum(latr),maximum(latr))

    colorbar()
    subplot(2,1,2)
    pcolor(lonr,latr,tmp[:,:,1]';
           cmap = "jet", vmin = vmin, vmax = vmax)
    colorbar()

    figname = joinpath(figdir,basename(replace(@__FILE__,r".jl$" => @sprintf("_%04d.png",timeindex))));
    savefig(figname)
    @info "Saved figure as " * figname
end

# launch the analysis

DIVAnd.diva3d((lonr,latr,depthr,TS),
              (lon,lat,depth,time),
              value,
              (lenx,leny,lenz),
              epsilon2,
              filename,varname,
              bathname = bathname,
              bathisglobal = bathisglobal,
              plotres = plotres,
              timeorigin = timeorigin,
       )

nothing
