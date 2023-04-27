# Packages. Note: make sure that all the packages that you use here are
# (1) available in either your global environment or your current page environment
# (2) are installed in the `.github/workflows/deploy.yml` file. See both the
# Project.toml and the `deploy.yml` file here as examples.
#
using DelimitedFiles
using Dates
using Weave
using DataFrames
using PrettyTables

const isAppleARM = Sys.isapple() && Sys.ARCH === :aarch64
if !isAppleARM
    using TikzPictures
end

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
    (all_tags === nothing) && return ""
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

if !isAppleARM

    # so we don't have to install LaTeX on CI
    tikzUseTectonic(true)

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
        save(SVG(outpath), TikzPicture(content; environment="tikzcd", preamble="\\usepackage{tikz-cd}"))
        return "\\fig{/$(Franklin.unixify(rpath))}"
    end
    
end

###########
### 013 ###
###########

function hfun_insertmd(params)
    rpath = params[1]
    fullpath = joinpath(Franklin.path(:folder), rpath)
    isfile(fullpath) || return ""
    return fd2html(read(fullpath, String), internal=true)
end

###########
### 015 ###
###########

function hfun_insert_weave(params)
    rpath = params[1]
    fullpath = joinpath(Franklin.path(:folder), rpath)
    (isfile(fullpath) && splitext(fullpath)[2] == ".jmd") || return ""
    print("Weaving... ")
    t = tempname()
    weave(fullpath, out_path=t)
    println("✓ [done].")
    fn = splitext(splitpath(fullpath)[end])[1]
    html = read(joinpath(t, fn * ".html"), String)
    start = findfirst("<BODY>", html)
    finish = findfirst("</BODY>", html)
    range = nextind(html, last(start)):prevind(html, first(finish))
    html = html[range]
    return html
end
    
###########
### 019 ###
###########
    
function hfun_render_table()
    val = rand(1:10, 5)
    tag = rand('A':'Z', 5)
    math = rand(["\$a + b\$", "\$\\frac{1}{2}\$", "\$\\sqrt{2\\pi}\$"], 5)
    website = rand(["[Franklin home page](https://franklinjl.org)", "[Franklin Github](https://github.com/tlienart/Franklin.jl)"], 5)
    df = DataFrame(; val, tag, math, website)
    pretty_table(
        String, # export table as a String
        df;
        nosubheader = true, # Remove the type from the column names
        tf = tf_html_default, # Use the default HTML rendered
        alignment = :c, # Center alignment
        formatters = ((x, i, j) -> string(x), (x, i, j) -> Franklin.fd2html(x, nop = true)), # Convert every inner cell to html
        allow_html_in_cells = true, # needed given the previous rendering
    )
end
