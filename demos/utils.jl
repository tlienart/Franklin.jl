# Packages. Note: make sure that all the packages that you use here are
# (1) available in either your global environment or your current page environment
# (2) are installed in the `.github/workflows/deploy.yml` file. See both the
# Project.toml and the `deploy.yml` file here as examples.
#
using DelimitedFiles

# ========================================================================

# with question 001 / approach 1; uses DelimitedFiles
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
