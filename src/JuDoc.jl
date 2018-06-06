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
	1. IMPORTING SOURCE
=#

include("jd_paths.jl")
include("jd_vars.jl")
include("block_patterns.jl")
include("find_replace_md.jl")
include("find_replace_html.jl")
include("process_files.jl")

end # module
