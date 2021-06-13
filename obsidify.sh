#!/bin/bash
julia -e 'include("src/obsidify-keep.jl");obsidify_keep.main();' > x.log

