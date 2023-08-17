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
    loc in DISALLOW || push!(DISALLOW, loc)
    return nothing
end

"""
$SIGNATURES

Generate a `robots.txt`, if one already exists, it will be replaced.
"""
function robots_generator()
    dst = joinpath(path(:site), "robots.txt")
    isfile(dst) && rm(dst)
    io = IOBuffer()
    sitemap_file = splitext(globvar(:sitemap_file))[1] * ".xml"
    globvar(:generate_sitemap)::Bool && println(io, """
        Sitemap: $(joinpath(globvar(:website_url)::String, sitemap_file))
        """)
    print(io, """
        User-agent: *
        """)
    if !(all(isempty, (DISALLOW, globvar(:robots_disallow)::Vector{String})))
        for page in DISALLOW
            print(io, """
                Disallow: $page
                """)
        end
        for dir in globvar(:robots_disallow)::Vector{String}
            if dir == "/"
                dir = ""
            end
            print(io, """
                Disallow: /$dir
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
