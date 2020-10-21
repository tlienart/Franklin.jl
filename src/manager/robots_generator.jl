# Sitemap: $(joinpath(path(:site), "sitemap.xml"))
#
# User-agent: *
# Disallow:
#

const DISALLOW = Vector{String}()

"""
$SIGNATURES

Add an entry to `DISALLOW`.
"""
function add_disallow_item()
    loc = url_curpage()
    loc in DISALLOW && return nothing
    push!(DISALLOW, loc)
    return loc
end

"""
$SIGNATURES

Generate a `robots.txt`, if one already exists, it will be replaced.
"""
function robots_generator()
    dst = joinpath(path(:site), "robots.txt")
    isfile(dst) && rm(dst)
    io = IOBuffer()
    globvar(:generate_sitemap) && println(io, """
        Sitemap: $(joinpath(globvar(:website_url), "sitemap.xml"))
        """)
    print(io, """
        User-agent: *
        """)
    if length(DISALLOW) != 0 || length(globvar(:robots_disallow)) != 0
        for page in DISALLOW
            print(io, """
                Disallow: $page
                """)
        end
        for dir in globvar(:robots_disallow)
            print(io, """
                Disallow: $dir
                """)
        end
    else
        print(io, """
            Disallow:
            """)
    end
    write(dst, take!(io))
    return nothing
end
