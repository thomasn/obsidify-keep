# obsidify-keep.jl
# @author Thomas Nichols <thomas@nexus10.com>
# @desc   Convert Google Keep notes to Obsidian Markdown

# A Google Keep repository can be exported using [Google Takeout](https://takeout.google.com/settings/takeout) 
# - this generates a Takeout/Keep directory containing:
#
# * json: the primary textual content, processed and output to vault
# * Labels.txt: list of label (tag) names used - added to report 
# * audio/video files: copied to vault/media
# * html: ignored unless JSON processing fails, in which case the corresponding html is copied
# * other files: copied to vault and added to report file

module obsidify_keep

import Pkg;
import Dates;

Pkg.add("DataFrames");
Pkg.add("JSON3");

using ArgParse, DataFrames, Dates, Debugger, JSON3;

LABEL_FILE = "Labels.txt";
MEDIA_EXTENSIONS = [".3gp", ".png", ".jpg", ".jpeg", ".mpeg", ".mp3", ".mp4", ".awb", ".gif"];
RECOGNIZED_EXTENSIONS = [".json", ".html"]
VAULT_SUBDIR = "vault";
MEDIA_SUBDIR = "media";
REPORT_FILE = "__Obsidify - Google Keep Escape Diary.md"


function main()
    params = read_args();
    make_output_dirs(params);
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


function make_output_dirs(params::Params)
    vault = params.output_dir * "/" * VAULT_SUBDIR;
    # mkpath() creates intermediate directories, does not error if they exist
    mkpath(vault, mode=0o777);
    mkpath(vault * "/" * MEDIA_SUBDIR, mode=0o777);
end


function chomp_all_files(params::Params) :: Status
    # Log all warnings and store labels in Status object
    status = Status([], []);
    # readdir() gives Vector{String} of filenames
    filenames = readdir(params.input_dir);
    # match file extension to relevant chomp method
    for fn in filenames
        ext = get_file_extension(fn);
        println("---- fn=", fn, "  ext=", ext);
        if (ext==".json")
            chomp_json_file(params, status, params.input_dir * "/" * fn);
        elseif(ext==".html")
            ;  # no action
        elseif(fn==LABEL_FILE)
            chomp_labels_file(params, status, joinpath(params.input_dir, LABEL_FILE));
        else 
            is_media = ext in MEDIA_EXTENSIONS;
            chomp_generic_file(params, status,is_media, fn);
        end
    end #for
    return status;
end


function chomp_labels_file(params::Params, status::Status, filename::String)
    # 
    # return a Vector of all labels used in the Keep repo.
    # TODO
    append!(status.labels, 
            ["LABEL1",
             "LABEL2",
            ]);
end

function chomp_generic_file(params::Params, status::Status, is_media::Bool, filename::String);
    target_dir = joinpath(params.output_dir, VAULT_SUBDIR);
    if is_media
        target_dir = joinpath(target_dir,MEDIA_SUBDIR);
    end
    println("---- generic: is_media=", is_media, " target_dir=", target_dir);
    try
        cp(joinpath(params.input_dir, filename), joinpath(target_dir, filename), force=false, follow_symlinks=true);
    catch err
        println("----hmmm: ", err.msg);
        push!(status.warnings, filename * ": " * err.msg);
    end

    # TODO
end

function chomp_json_file(params::Params, status::Status, filename::String)
    # TODO grep 'isChecked': Google Keep supports checkboxes
    # TODO handle isArchive and isTrash

    df = JSON3.read.(eachline(filename)) |> DataFrame;
    for r in eachrow(df)
        # TODO: Not even thinking about UTF-8 and graphemes...
        # TODO: 'listContent' has text/isChecked pairs: choose Markdown equivalent
        # implement as "\n- [ ] Monday\n- [x] Tuesday"
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
end


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

