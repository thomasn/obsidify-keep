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

INPUT_DIR = "Keep";
LABEL_FILE = "Labels.txt";
RECOGNIZED_EXTENSIONS = ["json", "html", "3gp", "png", "jpg", "awb"]
OUTPUT_DIR = "vault";
REPORT_FILE = "Google Keep Escape Diary.md"

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


function chomp_all_files()
    # glob files in Keep dir
    # readdir() gives Vector{String} of filenames
    # mkpath() creates intermediate directories, does not error if they exist
    # match file extension to relevant chomp method
    # https://github.com/vtjnash/Glob.jl is an option if globbing is required
    # grep 'isChecked': Google Keep supports checkboxes
    @bp
    chomp_json_file("/home/thomasn/jdi/gk2obs/sample.json");
end

function output_report()
    println("TODO: output report");
end

function thats_all()
    println("TODO: That's All Folks!");
end
function main()
    chomp_all_files()
    output_report()
    thats_all()
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    gk2obs.main()
end

