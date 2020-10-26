#!/bin/bash

## Une seule fois
./dyn-site build

## première utilisation
./dyn-site up 

./dyn-site user-rodasrv
./dyn-site user-etc-dyn-html
./dyn-site user-ln-tools-etc
./dyn-site user-install-dyndoc

./dyn-site pkg rcqls DyndocWebTools.dyn
./dyn-site pkg rcqls dyndoc-share library/RCqls
./dyn-site add Web

## installation julia
./dyn-site host-install-julia 1.3 0 
./dyn-site gem install jl4rb
./dyn-site host-dyndoc-yml-julia
./dyn-site user-export-rubylib
## installation mongo
./dyn-site gem install mongo