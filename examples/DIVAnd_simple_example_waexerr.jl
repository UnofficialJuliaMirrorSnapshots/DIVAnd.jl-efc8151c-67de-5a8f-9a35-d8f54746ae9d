# A simple example of DIVAnd in 2 dimensions
# with observations from an analytical function.

using DIVAnd
using Compat: @info, range
using PyPlot
if VERSION >= v"0.7"
    using LinearAlgebra
end

include("./prep_dirs.jl")

# using ndgrid

# observations
x = rand(75);
y = rand(75);

#x = rand(10);
#y = rand(10);

jmsize=120

f = sin.(6x) .* cos.(6y);

# final grid
xi,yi = ndgrid(range(0,stop=1,length=jmsize),range(0,stop=1,length=jmsize));

# reference field
fref = sin.(xi*6) .* cos.(yi*6);

# all points are valid points
mask = trues(size(xi));

# this problem has a simple cartesian metric
# pm is the inverse of the resolution along the 1st dimension
# pn is the inverse of the resolution along the 2nd dimension

pm = ones(size(xi)) / (xi[2,1]-xi[1,1]);
pn = ones(size(xi)) / (yi[1,2]-yi[1,1]);

# correlation length
len = 0.1;

# obs. error variance normalized by the background error variance
epsilon2 = 1.;
# Error scale to made comparable to the one used by DIVAndrun in case it is not normalized
#errorscale=1
# fi is the interpolated field
@time myerr,bjmb,fa,sa=  DIVAnd_aexerr(mask,(pm,pn),(xi,yi),(x,y),f,len,epsilon2);

fi,s = DIVAndrun(mask,(pm,pn),(xi,yi),(x,y),f,len,epsilon2);

@time exerr=reshape(diag(s.P),jmsize,jmsize);

# plotting of results
subplot(2,2,1);
pcolor(xi,yi,myerr);
colorbar()
clim(-0.5,1.5)
plot(x,y,"k.");
title("Almost Exact error");

subplot(2,2,2);
pcolor(xi,yi,exerr);
colorbar()
clim(-0.5,1.5)
title("Exact error");

subplot(2,2,3);
pcolor(xi,yi,bjmb);
colorbar()
clim(-0.5,1.5)
title("Background error");

subplot(2,2,4);
pcolor(xi,yi,myerr./bjmb);
colorbar()
clim(-0.5,1.5)
title("Bscaled error");

figname = joinpath(figdir,basename(replace(@__FILE__,r".jl$" => "_1.png")));
savefig(figname)
@info "Saved figure as " * figname

jmfig=figure("next one")

# plotting of results
subplot(1,2,1);
pcolor(xi,yi,fa);
colorbar()
clim(-0.5,1.5)
plot(x,y,"k.");
title("Analysis from aexerr");

subplot(1,2,2);
pcolor(xi,yi,fi);
colorbar()
clim(-0.5,1.5)
title("Analysis");

figname = joinpath(figdir,basename(replace(@__FILE__,r".jl$" => "_2.png")));
savefig(figname)
@info "Saved figure as " * figname

# Copyright (C) 2014, 2018 Alexander Barth <a.barth@ulg.ac.be>
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, see <http://www.gnu.org/licenses/>.
