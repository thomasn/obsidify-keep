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
REPORT_FILE = "__Obsidify_Log.md"


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
    println("---- inputdir=", parsed_args["inputdir"]); # TODO use input-dir??
    println("---- parsed_args is a ", typeof(parsed_args))
    params = Params(parsed_args["inputdir"],
                    joinpath(parsed_args["outputdir"], VAULT_SUBDIR),
                    parsed_args["verbose"]);
    return params;
end


function make_output_dirs(params::Params)
    vault = params.output_dir;
    # mkpath() creates intermediate directories, does not error if they exist
    mkpath(vault, mode=0o777);
    mkpath(joinpath(vault, MEDIA_SUBDIR), mode=0o777);
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
    target_dir = params.output_dir;
    if is_media
        target_dir = joinpath(target_dir,MEDIA_SUBDIR);
    end
    println("---- generic: is_media=", is_media, " target_dir=", target_dir);
    raw_fn = splitpath(filename)[end] # discard directories
    try
        cp(joinpath(params.input_dir, raw_fn),  joinpath(target_dir, raw_fn), force=false, follow_symlinks=true);
    catch err
        println("----hmmm: ", err.msg);
        push!(status.warnings, filename * ": " * err.msg);
    end

    # TODO
end

function chomp_json_file(params::Params, status::Status, filename::String)
    # TODO handle isArchive and isTrash
    # TODO strip trailing spaces from filenames / titles
    #
    # TODO Takeout/Keep/2018-04-13T00_29_24.173+01_00.json has sample 'attachment' - an 
    # amr-wb audio, auto-transcribed... grep 'what to do with the bicycle'
    # each attachment has (filePath, mimetype) - possible multiple attachments - in
    # addition to textContent
    # 
    # TODO Takeout/Keep/2018-11-05T13_54_26.091Z.json has sample 'annotation' - grep imivi52
    #     - each annotation has (description, source, title, url) - possible multiple
    #     annotations - in addition to textContent
    

    df = JSON3.read.(eachline(filename)) |> DataFrame;
    for r in eachrow(df)
        check_for_unknown_keys(params, status, keys(r));
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
        println("-------- fn=", filename);

        md_filename=splitpath(filename)[end];    # get filename without [path
        md_filename = replace(md_filename, ".json" => ".md");
        md_filename = joinpath(params.output_dir, md_filename);
        println("-------- md=", md_filename);

        open(md_filename, "w") do file
            title = getstring(r, :title);
            println(file, "---");
            println(file, "title: ", title);
            println(file, "date: ", ymddate);
            if getbool(r, :isPinned)
                println(file, "pinned: true");
            end
            if getbool(r, :isArchived)
                println(file, "archived: true");
            end
            if getbool(r, :isTrashed)
                println(file, "trashed: true");
            end
            # TODO: check for Obsidian-recognized meta-tags
            println(file, "---");
            println(file, "");

            println(file, "# ", title);
            println(file, "");
            # TODO: Not even thinking about UTF-8 and graphemes...
            print_text_content(file, r);
            print_list_content(file, r);
            print_annotations(file, r); 

        end # open
    end
end


function output_report(params::Params, status::Status)
    println("TODO: output report");
    open(joinpath(params.input_dir, REPORT_FILE), "w") do rf
        for warning in status.warnings
            println(rf, "------- warning: ", warning);
        end
        for label in status.labels
            println(rf, "-------- label: ", label);
        end
    end
end

function thats_all(status::Status)
    println("TODO: That's All Folks!");
end


function getstring(row::DataFrameRow, key::Symbol) ::String
    key in keys(row) ? row[key] : "";
end

function getbool(row::DataFrameRow, key::Symbol) ::Bool
    key in keys(row) ? row[key] : False;
end

function getvector(row::DataFrameRow, key::Symbol) ::Vector{Any}
    key in keys(row) ? row[key] :  [nothing];
end


# function getTODO(row::DataFrameRow, key::Symbol) ::String
#     key in keys(row) ? row[key] : [:url=>"https://foo"];
# end


function get_file_extension(filename)
    return filename[findlast(isequal('.'),filename):end];
end



function check_for_unknown_keys(params::Params, status::Status, keyvec::Vector{Symbol})
    # TODO scream if there's a field name I don't recognize
    # TODO check these are all processed
    known_keys = [
                  :annotations,
                  :attachments,
                  :color,
                  :isArchived,
                  :isTrashed,
                  :isPinned,
                  :labels,
                  :listContent,
                  :sharees,
                  :textContent,
                  :title,
                  :userEditedTimestampUsec,
                 ];

    for key in keyvec;
        if !(key in known_keys)
            warning = "unknown key: " * String(key);
            println("--------", warning);
            push!(status.warnings, warning);
        end
    end
end


function print_text_content(file::IO, row::DataFrameRow)
    text_content = getstring(row, :textContent);
    if (length(text_content) > 0)
        println(file, text_content);
    end
end


function print_list_content(file::IO, row::DataFrameRow)
    # Render as:
    # - [ ] Monday
    # - [x] Tuesday"
    
    list_content = getvector(row, :listContent);
    if list_content == [nothing]
        return
    end
    for list_item in list_content
        # println(file, "----: LIST_ITEM [", typeof(list_item), "] ---- ", list_item); # TODO
        text = list_item[:text];
        flag = (list_item[:isChecked]) ? "[x]" : "[ ]";
        println(file, "- ", flag, " ", text);
    end
end


function print_annotations(file::IO, row::DataFrameRow)
    annotations = getvector(row, :annotations);    
    if annotations == [nothing]
        return
    end
    for annotation in annotations
        println(file, "----: ANNOTATION [", typeof(annotation), "] ---- ", annotation); # TODO
    end
end

end # module

if abspath(PROGRAM_FILE) == @__FILE__
    obsidify_keep.main()
end

