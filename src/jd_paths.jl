"""
FOLDER_PATH

Container to keep track of where JuDoc is being run.
"""
const FOLDER_PATH = Ref{String}()


"""
IGNORE_FILES

Collection of file names that will be ignored at compile time.
"""
const IGNORE_FILES = [".DS_Store"]


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
    @assert isdir(FOLDER_PATH[]) "FOLDER_PATH is not a valid path"

    # NOTE it is recommended not to change the names of those paths.
    # Particularly for the output dir. If you do, check for example that
    # functions such as JuDoc.publish point to the right dirs/files.

    PATHS[:folder]    = normpath(FOLDER_PATH[])
    PATHS[:src]       = joinpath(PATHS[:folder],  "src")
    PATHS[:src_pages] = joinpath(PATHS[:src],     "pages")
    PATHS[:src_css]   = joinpath(PATHS[:src],     "_css")
    PATHS[:src_html]  = joinpath(PATHS[:src],     "_html_parts")
    PATHS[:pub]       = joinpath(PATHS[:folder],  "pub")
    PATHS[:css]       = joinpath(PATHS[:folder],  "css")
    PATHS[:libs]      = joinpath(PATHS[:folder],  "libs")
    PATHS[:assets]    = joinpath(PATHS[:folder],  "assets")
    PATHS[:literate]  = joinpath(PATHS[:folder],  "scripts")

    return PATHS
end
