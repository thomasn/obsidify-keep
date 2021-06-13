#!/bin/bash
julia -e 'include("src/obsidify-keep.jl");gk2obs.main();' > x.log

