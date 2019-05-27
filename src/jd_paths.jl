"""
    JD_FOLDER_PATH

Container to keep track of where JuDoc is being run.
"""
const JD_FOLDER_PATH = Ref{String}()


"""
    JD_IGNORE_FILES

Collection of file names that will be ignored at compile time.
"""
const JD_IGNORE_FILES = [".DS_Store"]


"""
    INFRA_EXT

Collection of file extensions considered as potential infrastructure files.
"""
const JD_INFRA_EXT = [".html", ".css"]


"""
    JD_PATHS

Dictionary for the paths of the input folders and the output folders. The simpler case only
requires the main input folder to be defined i.e. `JD_PATHS[:in]` and infers the others via the
`set_paths!()` function.
"""
const JD_PATHS = Dict{Symbol,String}()


"""
    set_paths!()

This assigns all the paths where files will be read and written with root the `JD_FOLDER_PATH`
which is assigned at runtime.
"""
function set_paths!()::Dict{Symbol,String}
    @assert isassigned(JD_FOLDER_PATH) "JD_FOLDER_PATH undefined"
    @assert isdir(JD_FOLDER_PATH[]) "JD_FOLDER_PATH is not a valid path"

    # NOTE it is recommended not to change the names of those paths.
    # Particularly for the output dir. If you do, check for example that
    # functions such as JuDoc.publish point to the right dirs/files.

    JD_PATHS[:f]        = normpath(JD_FOLDER_PATH[])
    JD_PATHS[:in]       = joinpath(JD_PATHS[:f],      "src")
    JD_PATHS[:in_pages] = joinpath(JD_PATHS[:in],     "pages")
    JD_PATHS[:in_css]   = joinpath(JD_PATHS[:in],     "_css")
    JD_PATHS[:in_html]  = joinpath(JD_PATHS[:in],     "_html_parts")
    JD_PATHS[:out]      = joinpath(JD_PATHS[:f],      "pub")
    JD_PATHS[:out_css]  = joinpath(JD_PATHS[:f],      "css")
    JD_PATHS[:libs]     = joinpath(JD_PATHS[:f],      "libs")
    JD_PATHS[:assets]   = joinpath(JD_PATHS[:f],      "assets")

    return JD_PATHS
end
