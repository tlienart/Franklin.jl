jdf_empty() = x -> nothing

jdf_lunr(pre="") = x -> lunr(pre)

# jdf_literate() = x -> literate_gen()

function lunr(prepath="")
    isempty(JuDoc.PATHS) && (FOLDER_PATH[] = pwd(); set_paths!())
    bk   = pwd()
    lunr = joinpath(PATHS[:libs], "lunr")
    # is there a lunr folder in /libs/
    isdir(lunr) ||
        (@warn "No `lunr` folder found in the `/libs/` folder."; return)
    # are there the relevant files in /libs/lunr/
    buildindex = joinpath(lunr, "build_index.js")
    isfile(buildindex) ||
        (@warn "No `build_index.js` file found in the `/libs/lunr/` folder."; return)
    # overwrite PATH_PREPEND = "...";
    rep = ifelse(isempty(prepath), "..", prepath)
    f = String(read(buildindex))
    f = replace(f, r"const\s+PATH_PREPEND\s*?=\s*?\".*?\"\;" => "const PATH_PREPEND = \"$(rep)\";"; count=1)
    write(buildindex, f)
    cd(lunr)
    try
        start = time()
        msg   = rpad("→ Building the Lunr index...", 35)
        print(msg)
        success(`$NODE build_index.js`);
        print_final(msg, start)
    catch e
        @warn "There was an error building the Lunr index."
    finally
        cd(bk)
    end
    return
end
