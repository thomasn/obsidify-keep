# gk2obs.jl
# @author Thomas Nichols <thomas@nexus10.com>
# @desc   Convert Google Keep notes to Obsidian Markdown

module gk2obs

import Pkg;
import Dates;

Pkg.add("DataFrames");
Pkg.add("JSON3");

using Debugger, Printf, DataFrames, JSON3, Dates;


function getstring(row::DataFrameRow, key::Symbol) ::String
    key in keys(row) ? row[key] : "***"
end



function chomp_files()
  df = JSON3.read.(eachline("/home/thomasn/jdi/gk2obs/sample.json")) |> DataFrame;

  for r in eachrow(df)
	# Don't even think about UTF-8 and graphemes...
	unixdate_seconds = r[:userEditedTimestampUsec] / 10^6; 
	@bp
        @printf("------- color: %s --------\n", getstring(r, :color));
	@bp
	datetime = Dates.unix2datetime(unixdate_seconds);
	ymddate = Dates.format(datetime, "yyyy-mm-dd");
	println("== DATE   : ", ymddate);
	println("== TITLE  : ", r.title, "==");
	println("== TEXT   : \n", r[:textContent], "\n\n");
	println("== LENGTHXX : ", length(r[:textContent]), "==\n");
	println("== TITLE  : ", r[:title], "==");
	println("== TRASH  : ", r[:isTrashed], "==");
	println("== ARCHIVE: ", r[:isArchived], "==");
#	println("== ANNOT  : ", r[:annotations], "==");
#	println("== URL    : ", r[:annotations][1][:url], "==");
  end	
end # function
end # module

gk2obs.chomp_files()

