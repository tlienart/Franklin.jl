# <?xml version="1.0" encoding="utf-8" standalone="yes" ?>
# <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
# <url>
#      <loc>http://www.example.com/</loc>
#      ?<lastmod>2005-01-01</lastmod>
#      ?<changefreq>monthly</changefreq>
#      ?<priority>0.8</priority>
# </url>
# </urlset>
#
# TODO
# allow {{sitemap_exclude}} for a HTML page to avoid having it in sitemap
#

struct SMOpts
    lastmod::Date        # 2005-01-01 -- format YYYY-MM-DD
    changefreq::String   # one of...
    priority::Float64    #
    function SMOpts(l, c, p)
        c = lowercase(c)
        allowedf = ("always", "hourly", "daily", "weekly", "monthly",
        "yearly", "never")
        assertf = """
        Given change frequency on $(FD_ENV[:SOURCE]) is invalid according to
        sitemap specifications, expected one of $allowedf.
        """
        assertp = """
        Given priority on $(FD_ENV[:SOURCE]) is invalid according to sitemap
        specifications, expected a floating point number between 0 and 1.
        """
        @assert c in allowedf assertf
        @assert 0 <= p <= 1 assertp
        return new(l, c, p)
    end
end

const SITEMAP_DICT = LittleDict{String,SMOpts}()

"""
$SIGNATURES

Add an entry to `SITEMAP_DICT`.
"""
function add_sitemap_item(; html=false)
    loc = url_curpage()
    locvar(:sitemap_exclude) && return nothing
    if !html
        lastmod = locvar(:fd_mtime_raw)
        changefreq = locvar(:sitemap_changefreq)
        priority = locvar(:sitemap_priority)
    else
        # use default which can be overwritten in a {{sitemap_opts ...}}
        fp = joinpath(path(:folder), locvar(:fd_rpath))
        lastmod = Date(unix2datetime(stat(fp).mtime))
        changefreq = "monthly"
        priority = 0.5
    end
    res = SITEMAP_DICT[loc] = SMOpts(lastmod, changefreq, priority)
    return res
end

"""
$SIGNATURES

Generate a `sitemap.xml`, if one already exists, it will be replaced.
"""
function sitemap_generator()
    dst = joinpath(path(:site), "sitemap.xml")
    isfile(dst) && rm(dst)
    io = IOBuffer()
    println(io, """
        <?xml version="1.0" encoding="utf-8" standalone="yes" ?>
        <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
        """)
    base_url = globvar(:website_url)
    for (k, v) in SITEMAP_DICT
        key = joinpath(escapeuri.(split(k, '/'))...)
        loc = "<loc>$(joinpath(base_url, key))</loc>"
        lastmod = "<lastmod>$(v.lastmod)</lastmod>"
        changefreq = "<changefreq>$(v.changefreq)</changefreq>"
        priority = "<priority>$(v.priority)</priority>"
        write(io, """
            <url>
                $loc
                $lastmod
                $changefreq
                $priority
            </url>
            """)
    end
    println(io, "</urlset>")
    write(dst, take!(io))
    return nothing
end
