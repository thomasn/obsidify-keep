# obsidify-keep.jl
# @author Thomas Nichols <thomas@nexus10.com>
# @desc   Convert Google Keep notes to Obsidian Markdown

# A Google Keep repository can be exported using [Google Takeout](https://takeout.google.com/settings/takeout) 
# - this generates a zip file of a Takeout/Keep directory containing:
#
# * json: the primary textual content, processed and output to vault
# * Labels.txt: list of label (tag) names used - added to report 
# * audio/video files: copied to vault/media
# * html: currently ignored
# * other files: copied to vault and added to report file

module ObsidifyKeep

using ArgParse, DataFrames, Dates, Debugger, JSON3, Pkg;
Pkg.add("DataFrames");
Pkg.add("JSON3");



include("spinner.jl");


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
    s = ArgParseSettings();
    @add_arg_table s begin
        "--input-dir", "-i"
        help = "location of the Takeout/Keep directory"
        arg_type = String
        default = "./Takeout/Keep"
        "--output-dir", "-o"
        help = "location of the output directory"
        arg_type = String
        default = "."
        "--verbose", "-v"
        help = "enable detailed logging"
        arg_type = Bool
        default = false
    end
    parsed_args = parse_args(Base.ARGS, s);
    params = Params(parsed_args["input-dir"],
                    joinpath(parsed_args["output-dir"], VAULT_SUBDIR),
                    parsed_args["verbose"]);
    params.verbose ? println("---- ARGS: ",      Base.ARGS)          : 0 ;
    params.verbose ? println("---- input-dir=",  params.input_dir)   : 0 ;
    params.verbose ? println("---- output-dir=", params.output_dir)  : 0 ;
    params.verbose ? println("---- verbose=",    params.verbose)     : 0 ;
    return params;
end


function make_output_dirs(params::Params)
    vault = params.output_dir;
    # unlike mkdir(), mkpath() creates intermediate directories, does not error if they exist
    mkpath(vault, mode=0o777);
    mkpath(joinpath(vault, MEDIA_SUBDIR), mode=0o777);
end


function chomp_all_files(params::Params) :: Status
    # Log all warnings and store labels in Status object
    status = Status([], []);
    println();
    spinner_pos = UInt16(1);
    # readdir() gives Vector{String} of filenames
    filenames = readdir(params.input_dir);
    # match file extension to relevant chomp method
    for fn in filenames
        spinner_pos = crank_spinner(spinner_pos);
        ext = get_file_extension(fn);
        if (ext==".json")
            chomp_json_file(params, status, joinpath(params.input_dir, fn));
        elseif(ext==".html")
            ;  # no action
        elseif(fn==LABEL_FILE)
            chomp_labels_file(params, status, joinpath(params.input_dir, LABEL_FILE));
        else 
            is_media = ext in MEDIA_EXTENSIONS;
            chomp_generic_file(params, status,is_media, fn);
        end
        spinner_pos = crank_spinner(spinner_pos);
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
    raw_fn = splitpath(filename)[end] # discard directories
    try
        # TODO use force=false and change filename in case of collision
        # (though OS-level collision handling - e.g. Windows "Filename (Copy).md" is viable)
        cp(joinpath(params.input_dir, raw_fn),  joinpath(target_dir, raw_fn), force=true, follow_symlinks=true);
    catch err
        push!(status.warnings, filename * ": " * err.msg);
    end

    # TODO
end

function chomp_json_file(params::Params, status::Status, filename::String)
    # TODO handle isArchive and isTrash
    # TODO strip trailing spaces from filenames / titles
    # TODO at two trailing spaces to output lines to force newlines
    #
    # 
    # TODO: Not even thinking about UTF-8 and graphemes...
    

    df = JSON3.read.(eachline(filename)) |> DataFrame;
    for r in eachrow(df)
        check_for_unknown_keys(params, status, keys(r));
        unixdate_seconds = r[:userEditedTimestampUsec] / 10^6; 
        datetime = Dates.unix2datetime(unixdate_seconds);
        ymddate = Dates.format(datetime, "yyyy-mm-dd");

        md_filename=splitpath(filename)[end];    # get filename without [path
        md_filename = replace(md_filename, ".json" => ".md");
        md_filename = joinpath(params.output_dir, md_filename);

        try
            open(md_filename, "w") do file
                print_metadata(file, r, ymddate);
                title = getstring(r, :title);
                println(file, "# ", title);
                println(file, "");
               print_attachments(file, r)
                print_text_content(file, r);
                print_list_content(file, r);
                print_annotations(file, r); 
            end
        catch err
            msg = "";
            if (typeof(err) == ErrorException)
                msg = filename * ": " * err.msg;
            elseif (typeof(err) == SystemError)
                msg = filename * ": " * err.prefix;
            else
                msg = "Unknown $(typeof(err))"
            end
            push!(status.warnings, filename * ": " * msg);
            params.verbose ? println("ERROR: ", msg) : 0 ;
        end
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
            push!(status.warnings, warning);
        end
    end
end


function print_metadata(file::IO,row::DataFrameRow, ymddate::String)

    title = getstring(row, :title);
    println(file, "---");
    println(file, "title: ", title);
    println(file, "date: ", ymddate);
    if getbool(row, :isPinned)
        println(file, "pinned: true");
    end
    if getbool(row, :isArchived)
        println(file, "archived: true");
    end
    if getbool(row, :isTrashed)
        println(file, "trashed: true");
    end
    # TODO: check for Obsidian-recognized meta-tags
    println(file, "---");
    println(file, "");
end

function print_attachments(file::IO, row::DataFrameRow)
    attachments = getvector(row, :attachments);    
    if attachments == [nothing] || attachments == []
        return
    end
    
    # Each attachment has (filePath, mimetype) - possible multiple attachments - in
    # addition to textContent
    # NOTE: VLC can play the audio/amr-wb ".amr" and audio/3gp ".3gp" formats.
    # FUTURE: support output of <audio.../> and <video.../> tags for inline players
    # BUG: Takeout mangles filenames - the file extension shown in JSON input is the last segment of the mime-type but the media files have 3-char extensions - hence we need to remap:
    # TODO: confirm no other extensions are mis-mapped.

    extension_map = Dict(
                         "amr-wb" => "awb",
                         "3gp"    => "3gp",
                         "jpeg"   => "jpg"
                        );

    for attachment in attachments
        file_path = get(attachment, "filePath", "");
        mimetype = attachment[:mimetype];
        # Get the final segment of the mimetype, which needs to be remapped:
        buggy_extension = rsplit(mimetype, '/', limit=2)[end];
        @bp
        patched_extension = get(extension_map, buggy_extension, "");
        if (patched_extension != "")
            file_path = replace(file_path, "." * buggy_extension => "." * patched_extension);
            alt_text = file_path;
            uri = joinpath(MEDIA_SUBDIR, file_path);
            # TODO: test with "![[assetfile]] instead - maybe with filename as alt text?
            # See ![[file|file]] syntax - will this set alt text?
            println(file, "![$alt_text]($uri)");
        end
    end
end


function print_annotations(file::IO, row::DataFrameRow)
    annotations = getvector(row, :annotations);    
    if annotations == [nothing] || annotations == []
        return
    end

    # Output a horizontal break
    println(file);
    println(file, "--------");
    println(file);

    for annotation in annotations
        source = annotation[:source];
        if (source == "WEBLINK")
            title = annotation[:title];
            description = annotation[:description];
            url = annotation[:url];
            println(file, "- [$title]($url \"$description\")");
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
        text = list_item[:text];
        flag = (list_item[:isChecked]) ? "[x]" : "[ ]";
        println(file, "- ", flag, " ", text);
    end
end




end # module

if abspath(PROGRAM_FILE) == @__FILE__
    ObsidifyKeep.main()
end

