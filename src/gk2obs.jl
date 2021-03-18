module gk2obs

import Pkg;
Pkg.add("JSON3");

using JSON3

json = JSON3.read.(eachline("/home/thomasn/jdi/gk2obs/sample.json")) ;

i = 1;

print (jsondxif2 = (df[i, :title], df[i, :textContent] for i in 1:size(df, 1));

print(df2);

greet() = print("Hello World!")


boogie() = print("And thanks for all the salmon")

end # module
