"""
FOLDER_PATH

Container to keep track of where Franklin is being run.
"""
const FOLDER_PATH = Ref{String}()


"""
IGNORE_FILES

Collection of file names that will be ignored at compile time.
"""
const IGNORE_FILES = [".DS_Store", ".gitignore", "LICENSE.md", "README.md",
                      "franklin", "franklin.pub", "node_modules/"]


"""
INFRA_EXT

Collection of file extensions considered as potential infrastructure files.
"""
const INFRA_FILES = [".html", ".css"]


"""
PATHS

Dictionary for the paths of the input folders and the output folders. The simpler case only
requires the main input folder to be defined i.e. `PATHS[:src]` and infers the others via the
`set_paths!()` function.
"""
const PATHS = LittleDict{Symbol,String}()


"""
$(SIGNATURES)

This assigns all the paths where files will be read and written with root the `FOLDER_PATH`
which is assigned at runtime.
"""
function set_paths!()::LittleDict{Symbol,String}
    @assert isassigned(FOLDER_PATH) "FOLDER_PATH undefined"
    @assert isdir(FOLDER_PATH[])    "FOLDER_PATH is not a valid path"

    # NOTE it is recommended not to change the names of those paths.
    # Particularly for the output dir. If you do, check for example that
    # functions such as Franklin.publish point to the right dirs/files.

    if FD_ENV[:STRUCTURE] < v"0.2"
        PATHS[:folder]    = normpath(FOLDER_PATH[])
        PATHS[:src]       = joinpath(PATHS[:folder], "src")
        PATHS[:src_pages] = joinpath(PATHS[:src],    "pages")
        PATHS[:src_css]   = joinpath(PATHS[:src],    "_css")
        PATHS[:src_html]  = joinpath(PATHS[:src],    "_html_parts")
        PATHS[:pub]       = joinpath(PATHS[:folder], "pub")
        PATHS[:css]       = joinpath(PATHS[:folder], "css")
        PATHS[:libs]      = joinpath(PATHS[:folder], "libs")
        PATHS[:assets]    = joinpath(PATHS[:folder], "assets")
        PATHS[:literate]  = joinpath(PATHS[:folder], "scripts")
        PATHS[:tag]       = joinpath(PATHS[:pub],    "tag")
    else
        PATHS[:folder]   = normpath(FOLDER_PATH[])
        PATHS[:site]     = joinpath(PATHS[:folder], "__site")    # mandatory
        PATHS[:assets]   = joinpath(PATHS[:folder], "_assets")   # mandatory
        PATHS[:css]      = joinpath(PATHS[:folder], "_css")      # mandatory
        PATHS[:layout]   = joinpath(PATHS[:folder], "_layout")   # mandatory
        PATHS[:libs]     = joinpath(PATHS[:folder], "_libs")     # mandatory
        PATHS[:literate] = joinpath(PATHS[:folder], "_literate") # optional
        PATHS[:tag]      = joinpath(PATHS[:site],   "tag")
    end

    return PATHS
end

"""
    path(s)

Return the paths corresponding to `s` e.g. `path(:folder)`.
"""
path(s) = PATHS[Symbol(s)]


"""
Pointer to the `/output/` folder associated with an eval block (see also
[`@OUTPUT`](@ref)).
"""
const OUT_PATH = Ref("")

"""
This macro points to the `/output/` folder associated with an eval block.
So for instance, if an eval block generates a plot, you could save the plot
with something like `savefig(joinpath(@OUTPUT, "ex1.png"))`.
"""
macro OUTPUT()
    return OUT_PATH[]
end
