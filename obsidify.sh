#!/bin/bash
julia -e 'include("src/gk2obs.jl");gk2obs.main();' > x.log

