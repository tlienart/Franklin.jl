function lunr()::Nothing
    prepath = ""
    haskey(GLOBAL_VARS, "prepath") && (prepath = GLOBAL_VARS["prepath"].first)
    isempty(PATHS) && (FOLDER_PATH[] = pwd(); set_paths!())
    bkdir = pwd()
    lunr  = joinpath(PATHS[:libs], "lunr")
    # is there a lunr folder in /libs/
    isdir(lunr) ||
        (@warn "No `lunr` folder found in the `/libs/` folder."; return)
    # are there the relevant files in /libs/lunr/
    buildindex = joinpath(lunr, "build_index.js")
    if !isfile(buildindex)
		@warn "No `build_index.js` file found in the `/libs/lunr/` folder."
		return nothing
	end
    # overwrite PATH_PREPEND = "..";
    if !isempty(prepath)
        f = String(read(buildindex))
        f = replace(f,
					r"const\s+PATH_PREPEND\s*?=\s*?\".*?\"\;" =>
					 "const PATH_PREPEND = \"$(prepath)\";"; count=1)
        buildindex = replace(buildindex, r".js$" => ".tmp.js")
        write(buildindex, f)
    end
    cd(lunr)
    try
        start = time()
        msg   = rpad("→ Building the Lunr index...", 35)
        print(msg)
        run(`$(NODE()) $(splitdir(buildindex)[2])`)
        print_final(msg, start)
    catch e
        @warn "There was an error building the Lunr index."
    finally
        isempty(prepath) || rm(buildindex)
        cd(bkdir)
    end
    return
end

"""
Display a Plotly plot given an exported JSON `String`.

```
using PlotlyJS
fdplotly(json(plot([1, 2]))
```
"""
function fdplotly(json::String; id="fdp"*Random.randstring('a':'z', 3),
	 			  style="width:600px;height:350px")::Nothing
    println("""
		~~~
		<div id="$id" style="$style"></div>

		<script>
			var fig = $json;
			graphDiv = document.getElementById('$id');
			Plotly.newPlot(graphDiv, fig.data, fig.layout)
		</script>
		~~~
		""")
    return nothing
end

"""
    html_plotly

Convenience function to plot a Plotly. User need to add a Javascript function `PlotlyJS_json`.
"""
function html_plotly(
			src::AbstractString;
			id::String = "fdp"*Random.randstring('a':'z', 3),
            style::String = "")

	pp = globvar(:prepath)::String
	pp = ifelse(isempty(pp), pp, "/$pp")
	pp = ifelse(FD_ENV[:FINAL_PASS]::Bool, pp, "")

	return """
		   <div id="$id" style="$style"></div>
		   <script>
		   graphDiv = document.getElementById("$id");
		   plotlyPromise = PlotlyJS_json(graphDiv, '$pp$src');
		   </script>
		   """
end
