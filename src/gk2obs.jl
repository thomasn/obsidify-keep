module gk2obs

import Pkg;
Pkg.add("DataFrames");
Pkg.add("JSON3");

using DataFrames, JSON3

df = JSON3.read.(eachline("/home/thomasn/jdi/gk2obs/sample.json")) |> DataFrame;

for r in eachrow(df)
	println("== TITLE : ", r[:title], "==\n");
	println("== TEXT  : ", r[:textContent], "==\n");
	println("== LENGTH: ", length(r[:textContent]), "==\n");
end	

end # module

