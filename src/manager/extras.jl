function lunr()
    prepath = GLOBAL_PAGE_VARS["prepath"].first
    isempty(JuDoc.PATHS) && (FOLDER_PATH[] = pwd(); set_paths!())
    bkdir = pwd()
    lunr  = joinpath(PATHS[:libs], "lunr")
    # is there a lunr folder in /libs/
    isdir(lunr) ||
        (@warn "No `lunr` folder found in the `/libs/` folder."; return)
    # are there the relevant files in /libs/lunr/
    buildindex = joinpath(lunr, "build_index.js")
    isfile(buildindex) ||
        (@warn "No `build_index.js` file found in the `/libs/lunr/` folder."; return)
    # overwrite PATH_PREPEND = "..";
    if !isempty(prepath)
        f = String(read(buildindex))
        f = replace(f, r"const\s+PATH_PREPEND\s*?=\s*?\".*?\"\;" => "const PATH_PREPEND = \"$(prepath)\";"; count=1)
        buildindex = replace(buildindex, r".js$" => ".tmp.js")
        write(buildindex, f)
    end
    cd(lunr)
    try
        start = time()
        msg   = rpad("→ Building the Lunr index...", 35)
        print(msg)
        run(`$NODE $(splitdir(buildindex)[2])`)
        print_final(msg, start)
    catch e
        @warn "There was an error building the Lunr index."
    finally
        isempty(prepath) || rm(buildindex)
        cd(bkdir)
    end
    return
end
