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

using ArgParse, DataFrames, Dates, Debugger, JSON3, Printf;

LABEL_FILE = "Labels.txt";
RECOGNIZED_EXTENSIONS = ["json", "html", "3gp", "png", "jpg", "awb"]
OUTPUT_SUBDIR = "vault";
REPORT_FILE = "__Obsidify - Google Keep Escape Diary.md"


function main()
    params = read_args();
    status = chomp_all_files(params);
    output_report(params, status);
    thats_all(status);
end

#-- Implementation -------- --#

struct Params
    input_dir::String;
    output_dir::String;
    verbose::Bool;
end

struct Status
    labels::Vector{String};
    warnings::Vector{String};
end

function read_args() :: Params
    s = ArgParseSettings()
    @add_arg_table s begin
        "--inputdir", "-i"
            help = "location of the Takeout/Keep directory"
	    arg_type = String
	    default = "./Takeout/Keep"
        "--outputdir", "-o"
	help = "location of the output directory"
            arg_type = String
            default = "."
        "--verbose", "-v"
            help = "enable detailed logging"
            action = :store_true
    end
    parsed_args = parse_args(ARGS, s);
    @bp
    println("---- inputdir=", parsed_args["inputdir"]); # TODO
    println("---- parsed_args is a ", typeof(parsed_args))
    params = Params(parsed_args["inputdir"], parsed_args["outputdir"], parsed_args["verbose"]);
    return params;
end


function chomp_all_files(params::Params) :: Status
    # TODO glob files in Keep dir
    status = Status([], []);
    # readdir() gives Vector{String} of filenames
    filenames = readdir(params.input_dir);
    for fn in filenames
        ext = get_file_extension(fn);
        println("---- fn=", fn, "  ext=", ext);
        if (ext==".json")
            chomp_json_file(params, status, params.input_dir * "/" * fn);
            return status; # TODO noooooo....
        elseif(ext==".html")
            println("got HTML ----");
        end #if
    end #for
    # mkpath() creates intermediate directories, does not error if they exist
    # match file extension to relevant chomp method
    # https://github.com/vtjnash/Glob.jl is an option if globbing is required
    # grep 'isChecked': Google Keep supports checkboxes
    #
   chomp_labels_file(params, status);
   chomp_json_file(params, status, "/home/thomasn/jdi/gk2obs/sample.json");
   return status;
end


function chomp_labels_file(params::Params, status::Status)
    # 
    # return a Vector of all labels used in the Keep repo.
	    # TODO
	    append!(status.labels, 
	        ["LABEL1",
	         "LABEL2",
		 ]);
	end

	function chomp_generic_file(params::Params, status::Status, filename::String)
	    # TODO
	end

	function chomp_json_file(params::Params, status::Status, filename::String)
	    df = JSON3.read.(eachline(filename)) |> DataFrame;

	    for r in eachrow(df)
		# TODO: Not even thinking about UTF-8 and graphemes...
		check_for_unknown_keys(keys(r));
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
	end # chomp_json_file


	function output_report(params::Params, status::Status)
	    println("TODO: output report");
	end

	function thats_all(status::Status)
	    println("TODO: That's All Folks!");
	end


function getstring(row::DataFrameRow, key::Symbol) ::String
key in keys(row) ? row[key] : "***"
end

function getbool(row::DataFrameRow, key::Symbol) ::Bool
    key in keys(row) ? row[key] : False;
end

function get_file_extension(filename)
    return filename[findlast(isequal('.'),filename):end]
end

function getvector(row::DataFrameRow, key::Symbol) ::String
	key in keys(row) ? row[key] : [:url=>"https://foo"];
end


function check_for_unknown_keys(keyvec::Vector{Symbol})
    # TODO scream if there's a field name I don't recognize
    known_keys = [
		  :annotations,
                  :attachments,
                  :color,
                  :isTrashed,
                  :isPinned,
                  :isArchived,
                  :textContent,
                  :title,
                  :userEditedTimestampUsec,
		  ];

    for key in keyvec;
	    if !(key in known_keys)
            println("unknown key: ", key);
	end
    end
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    gk2obs.main()
end

