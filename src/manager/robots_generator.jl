# Sitemap: $(joinpath(path(:site), "sitemap.xml"))
#
# User-agent: *
# Disallow:
#
# TODO
# allow {{robots_exclude}} for a HTML page to add it to disallow
# allow a parameter to switch "Disallow:" to "Disallow: /"

"""
$SIGNATURES

Generate a `robots.txt`, if one already exists, it will be replaced.
"""
function robots_generator()
    dst = joinpath(path(:site), "robots.txt")
    isfile(dst) && rm(dst)
    io = IOBuffer()
    globvar("generate_sitemap") && println(io, """
        Sitemap: $(joinpath(globvar(:website_url), "sitemap.xml"))
        """)
    println(io, """
        User-agent: *
        Disallow:
        """)
    write(dst, take!(io))
    return nothing
end
