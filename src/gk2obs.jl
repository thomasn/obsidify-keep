module gk2obs

import Pkg;
Pkg.add("DataFrames");
Pkg.add("JSON3");

using DataFrames, JSON3

df = JSON3.read.(eachline("/home/thomasn/jdi/gk2obs/sample.json")) |> DataFrame;

i = 1;

df2 = (df[i, :title], df[i, :textContent] for i in 1:size(df, 1));

print(df2);

greet() = print("Hello World!")


boogie() = print("And thanks for all the salmon")

end # module
