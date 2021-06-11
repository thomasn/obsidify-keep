# gk2obs.jl
# @author Thomas Nichols <thomas@nexus10.com>
# @desc   Convert Google Keep notes to Obsidian Markdown

# A Google Keep repository can be exported using the [Takeout](https://takeout.google.com/settings/takeout) 
# tool - this generates a Takeout/Keep directory containing:
#
# * json - the primary textual content
# * html - ignored unless JSON processing fails, in which case the corresponding html is copied
# * Labels.txt: label (tag) names used - added to report 
# * 3gp - audio: copied
# * png - image: copied
# * jpg - image: copied
# * awb - audio: copied
# * other files: copied and added to report

module gk2obs

import Pkg;
import Dates;

Pkg.add("DataFrames");
Pkg.add("JSON3");

using Debugger, Printf, DataFrames, JSON3, Dates;


function getstring(row::DataFrameRow, key::Symbol) ::String
    key in keys(row) ? row[key] : "***"
end

function getbool(row::DataFrameRow, key::Symbol) ::Bool
    key in keys(row) ? row[key] : False;
end

function getvector(row::DataFrameRow, key::Symbol) ::String
	key in keys(row) ? row[key] : [:url=>"https://foo"];
end


function chomp_labels_file(filename::String)
    # TODO
end

function chomp_generic_file(filename::String, do_logging::Bool = True)
    # TODO
end

function chomp_json_file(filename::String)
    df = JSON3.read.(eachline(filename)) |> DataFrame;

    for r in eachrow(df)
	# TODO: Not even thinking about UTF-8 and graphemes...
	unixdate_seconds = r[:userEditedTimestampUsec] / 10^6; 
	datetime = Dates.unix2datetime(unixdate_seconds);
	ymddate = Dates.format(datetime, "yyyy-mm-dd");
	println("== DATE   : ", ymddate);
	println("== TITLE  : ", getstring(r, :title), "==");
	println("== TEXT   : \n", getstring(r, :textContent), "\n\n");
	println("== LENGTH : ", length(getstring(r, :textContent)), "==\n");
	println("== TITLE  : ", getstring(r, :title), "==");
	println("== TRASH  : ", getbool(r, :isTrashed), "==");
	println("== ARCHIVE: ", getbool(r, :isArchived), "==");
	# println("== ANNOT  : ", getvector(r, :annotations), "==");
	#	println("== URL    : ", getvector(r, :annotations)[1][:url], "==");
  end
end # chomp_file

function main()
    chomp_json_file("/home/thomasn/jdi/gk2obs/sample.json");
end

end # module

gk2obs.main()

