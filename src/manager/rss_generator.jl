# Specifications: RSS 2.0 -- https://cyber.harvard.edu/rss/rss.html#sampleFiles
# steps:
# 0. check if the relevant variables are defined otherwise don't generate the RSS
# 1. is there an RSS file?
#  --> remove it and create a new one (bc items may have been updated)
# 2. go over all pages
#  --> is there a rss var?
#  NO  --> skip
#  YES --> recuperate the `jd_ctime` and `jd_mtime` and add a RSS channel object
# 3. save the file

struct RSSItem
    title::String
    link::String
    description::String
    author::String
    category::String
    comments::String
    enclosure::String
    # guid -- hash of link
    pubDate::String
end

const RSS_DICT = Dict{String,RSSItem}()

"""Convenience function for fallback fields"""
jor(v::PageVars, a::String, b::String) = ifelse(isempty(first(v[a])), first(v[b]), first(v[a]))


"""
$SIGNATURES

Create an `RSSItem` out of the provided fields defined in the page vars.
"""
function add_rss_item(jdv::PageVars)::RSSItem
    link   = url_curpage()
    title  = jor(jdv, "rss_title", "title")
    descr  = jor(jdv, "rss", "rss_description") |> jd2html
    author = jor(jdv, "rss_author", "author")

    category  = jdv["rss_category"]  |> first
    comments  = jdv["rss_comments"]  |> first
    enclosure = jdv["rss_enclosure"] |> first

    pubDate = jdv["rss_pubdate"] |> first
    if pubDate == Date(1)
        pubDate = jdv["date"] |> first
        if pubDate == Date(1) || !isa(pubDate, Date)
            pubDate = jdv["jd_mtime"] |> first
        end
    end

    # warning for title which should really be defined
    isnothing(title) && (title = "")
    isempty(title) && @warn "Found an RSS description but no title for page $link."

    RSS_DICT[url] = RSSItem(title, link, descr,
        author, category, comments, enclosure, pubDate)
end


"""
$SIGNATURES

Extract the entries from RSS_DICT and assemble the RSS. If the dictionary is empty, nothing
is generated.
"""
function rss_generator()::Nothing
    # is there anything to go in the RSS feed?
    isempty(RSS_DICT) && return nothing

    # are the basic defs there? otherwise warn and break
    rss_title = GLOBAL_PAGE_VARS["website_title"]
    rss_descr = GLOBAL_PAGE_VARS["website_descr"]
    rss_link  = GLOBAL_PAGE_VARS["website_url"]

    if any(isempty, (rss_title, rss_descr, rss_link))
        @warn """I found RSS items but the RSS feed is not properly described:
              at least one of the following variables has not been defined in
              your config.md: `website_title`, `website_descr`, `website_url`.
              The feed will not be (re)generated."""
        return nothing
    end
    # is there an RSS file already? if so remove it
    rss_path = joinpath(PATHS[:folder], "feed.xml")
    isfile(rss_path) && rm(rss_path)

    # create a buffer which will correspond to the output
    rss_buff = IOBuffer()
    write(rss_buff,
        """
        <?xml version="1.0" encoding="utf-8"?>
        <rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
        <channel>
          <title>$rss_title</title>
          <description>$rss_descr</description>
          <link>$rss_link</link>
        """)
    # loop over items
    for (k, v) in RSS_DICT
        write(rss_buff,
          """
          <item>
            <title>$(v.title)</title>
            <link>$(v.link)</link>
            <description>$(v.description)</description>
            <author>$(v.author)</author>
            <category>$(v.category)</category>
            <comments>$(v.comments)</comments>
            <encloosure>$(v.enclosure)</enclosure>
            <guid>$(hash(v.link))</guid>
            <pubDate>$(Dates.format(d, "e, d u Y")) 00:00:00 UTC</pubDate>
          </item>
          """)
    end
    # finalize
    write(rss_buff,
        """
        </channel>
        </rss>
        """)
    write(rss_path, take!(rss_buff))

    return nothing
end
