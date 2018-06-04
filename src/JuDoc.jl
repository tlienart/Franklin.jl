module JuDoc

#=

Expected structure, see tweb_j

-- calling script --

# the path variables should only be set once. If modified, restart REPL to
# reload JuDoc appropriately.

const FOLDER_PATH  	   = @__DIR__
const PATH_INPUT       = joinpath(FOLDER_PATH, "web_input/")
const PATH_INPUT_LIBS  = PATH_INPUT * "_libs/"
const PATH_INPUT_CSS   = PATH_INPUT * "_css/"
const PATH_INPUT_HTML  = PATH_INPUT * "_html_parts/"
const PATH_OUTPUT      = joinpath(FOLDER_PATH, "web_output/")
const PATH_OUTPUT_LIBS = PATH_OUTPUT * "_libs/"
const PATH_OUTPUT_CSS  = PATH_OUTPUT * "_css/"

using JuDoc

convert_dir() # run this whenever you want an update #TODO make this continuous

-- input folder structure --

.
|
+-- config.md 	# setting main doc vars like author.
+-- index.md 	# (or index.html) the front page
|
+-- folder1
|	|
|	+-- file1.md
|	+-- file2.md
|
+-- folder2
|	|
|	+-- file1.md
|	+-- file2.md
|
+-- _css 		# css folder (copied from default, possibly modified)
+-- _html 		# template html (copied from default, possibly modified)
+-- _libs 		# katex, prism folder (copied from default)

=#

export convert_dir

#=
	0. PATHS ADJUSTMENTS
	- the calling script should define at the very least where the input folder is (Main.PATH_INPUT) and it should be a valid directory.
=#

# path variables. they can be modified by the set_paths function (only)
PATHS = Dict{Symbol, String}(
	:in 	  => "",
  	:in_libs  => "",
	:in_css   => "",
  	:in_html  => "",
	:out 	  => "",
	:out_libs => "",
	:out_css  => "")

# if the symbol is defined, take that value, otherwise, take a default.
ifisdef(symb, def) = isdefined(Main, symb) ? eval(:(Main.$symb)) : def

# reads the path variables from the Main environment. This is done
# every time convert_dir is called (cheap). It has side effects -> !
function set_paths!()
	global PATHS

	@assert isdefined(Main, :PATH_INPUT) "PATH_INPUT undefined"
	PATHS[:in] = Main.PATH_INPUT
	@assert isdir(PATHS[:in]) "PATH_INPUT does not lead to valid input folder"

	PATHS[:in_libs]  = ifisdef(:PATH_INPUT_LIBS, PATHS[:in] * "_libs/")
	PATHS[:in_css]   = ifisdef(:PATH_INPUT_CSS,  PATHS[:in] * "_css/")
	PATHS[:in_html]  = ifisdef(:PATH_INPUT_HTML, PATHS[:in] * "_html_parts/")

	PATHS[:out] 	 = ifisdef(:PATH_OUTPUT, "web_output/")
	PATHS[:out_libs] = ifisdef(:PATH_OUTPUT_LIBS, PATHS[:out] * "_libs/")
	PATHS[:out_css]  = ifisdef(:PATH_OUTPUT_CSS,  PATHS[:out] * "_css/")

	return PATHS
end

#=
	1. IMPORTING SOURCE
=#

include("block_patterns.jl")
include("find_replace_md.jl")
include("find_replace_html.jl")
include("process_files.jl")

end # module
