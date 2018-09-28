"""
	JD_PATHS

Dictionary for the paths of the input folders and the output folders. The
simpler case only requires the main input folder to be defined i.e.
`JD_PATHS[:in]` and infers the others via the `set_paths!()` function.
"""
JD_PATHS = Dict{Symbol, String}()


"""
	IGNORE_FILES

Collection of file names that will be ignored at compile time.
"""
const IGNORE_FILES = [".DS_Store"]


"""
	INFRA_EXT

Collection of file extensions considered for infrastructure files.
"""
const INFRA_EXT = [".html", ".css"]


"""
	set_paths!()

Queries the `Main` module to see if the different path variables are defined.
`Main.PATH_INPUT` must be defined (and valid), the others have a default value.
"""
function set_paths!()
	global JD_PATHS

	@assert isdefined(Main, :FOLDER_PATH) "FOLDER_PATH undefined"
	JD_PATHS[:f] = normpath(Main.FOLDER_PATH * "/")
	@assert isdir(JD_PATHS[:f]) "FOLDER_PATH is not a valid path"

	JD_PATHS[:in] = JD_PATHS[:f] * "src/"
	JD_PATHS[:in_pages] = JD_PATHS[:in] * "pages/"
	JD_PATHS[:in_css] = JD_PATHS[:in] * "_css/"
	JD_PATHS[:in_html] = JD_PATHS[:in] * "_html_parts/"

	JD_PATHS[:out] = JD_PATHS[:f] * "pub/"
	JD_PATHS[:out_css] = JD_PATHS[:f] * "css/"

	JD_PATHS[:libs] = JD_PATHS[:f] * "libs/"

	return JD_PATHS
end
