# Packages. Note: make sure that all the packages that you use here are
# (1) available in either your global environment or your current page environment
# (2) are installed in the `.github/workflows/deploy.yml` file. See both the
# Project.toml and the `deploy.yml` file here as examples.
#
using DelimitedFiles
using TikzCDs

# ========================================================================

###########
### 001 ###
###########

# approach 1; uses DelimitedFiles
function hfun_members_table(params::Vector{String})::String
    path_to_csv = params[1]
    members = readdlm(path_to_csv, ',', skipstart=1)
    # write a simple table
    io = IOBuffer()
    write(io, "<table>")
    write(io, "<tr><th>Name</th><th>GitHub alias</th></tr>")
    for (name, alias) in eachrow(members)
        write(io, "<tr>")
        write(io, "<td>$name</td>")
        write(io, """<td><a href="https://github.com/$alias">$alias</a></td>""")
        write(io, "</tr>")
    end
    write(io, "</table>")
    return String(take!(io))
end

###########
### 007 ###
###########

# case 1
hfun_case_1() =
    """<p style="color:red;">var read from foo is $(pagevar("foo", "var"))</p>"""

# case 2, note the `@delay`
@delay function hfun_case_2()
    all_tags = globvar("fd_page_tags")
    isnothing(all_tags) && return ""
    all_tags = union(values(all_tags)...)
    tagstr = strip(prod("$t " for t in all_tags))
    return """<p style="color:red;">tags: { $tagstr }</p>"""
end

###########
### 008 ###
###########

function lx_capa(com, _)
    # this first line extracts the content of the brace
    content = Franklin.content(com.braces[1])
    output = replace(content, "a" => "A")
    return "**$output**"
end

function env_cap(com, _)
    content = Franklin.content(com)
    option = Franklin.content(com.braces[1])
    output = replace(content, option => uppercase(option))
    return "~~~<b>~~~$output~~~</b>~~~"
end

###########
### 009 ###
###########

function env_tikzcd(e, _)
  content = strip(Franklin.content(e))
  name = strip(Franklin.content(e.braces[1]))
  # save SVG at __site/assets/[path/to/file]/$name.svg
  rpath = joinpath("assets", splitext(Franklin.locvar(:fd_rpath))[1], "$name.svg")
  outpath = joinpath(Franklin.path(:site), rpath)
  # if the directory doesn't exist, create it
  outdir = dirname(outpath)
  isdir(outdir) || mkpath(outdir)
  # save the file and show it
  save(SVG(outpath), TikzCD(content))
  return "\\fig{/$(Franklin.unixify(rpath))}"
end
