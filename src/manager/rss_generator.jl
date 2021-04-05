# Items are assembled by the rss_generator in a global feed and sub-feeds
# for each of the tag. So each item is a tuple with the string of the item
# and
const RSS_ITEMS = Vector{
    Tuple{
        String,             # the rss item from template
        Vector{String}      #
    }
}

"""
$SIGNATURES

If there's an RSS feed to generate, check that the template files are there, if not
then get them from FranklinTemplates. Also check that a few key variables
are defined.
"""
function prepare_for_rss()::Nothing
    # check for key variables
    for key_var in (:website_title, :website_url, :website_description)
        isempty(globvar(key_var)::String) || continue
        print_warning("""
            RSS is set to be generated but the RSS feed is improperly described:
            at least one of the following variables have not been defined in
            your 'config.md': 'website_title', 'website_url', 'website_description'.
            The feed will not be (re)generated.
            \nRelevant pointer:
            $POINTER_PV
            """)
        return nothing
    end
    # check if there's an _rss folder, if there isn't generate one from
    # template (see FranklinTemplates)
    isdir(path(:rss)) || mkdir(path(:rss))
    for template in ("head.xml", "item.xml")
        dst = joinpath(path(:rss), template)
        if !isfile(dst)
            src = joinpath(
                dirname(pathof(FranklinTemplates)),
                "templates", "common", "_rss", template
            )
            cp(src, dst)
        end
    end
    return nothing
end


"""
$SIGNATURES

Extract the entries from RSS_ITEMS and assemble the RSS.
If RSS_ITEMS is empty, nothing is generated.
If tags are associated with items, also create one feed per tag.
"""
function rss_generator()::Nothing
    # is there anything to go in the RSS feed?
    isempty(RSS_ITEMS) && return nothing

    # global feed: HEAD * prod(SORTED_ITEMS) * closer
    # tag feed: HEAD * prod(SORTED_FILTERED_ITEMS) * closer
    #
    # NOTE: if a file `head_$(refstring(tag)).xml` is available, it will take precedence
    # for the corresponding tag feed; otherwise `head.xml` will be used.
    #
    # XXX XXX XXX XXX



    # are the basic defs there? otherwise warn and break
    rss_title = globvar("website_title")::String
    rss_descr = globvar("website_descr")::String
    rss_link  = globvar("website_url")::String

    if any(isempty, (rss_title, rss_descr, rss_link))
        print_warning("""
            RSS items were found but the RSS feed is improperly described:
            at least one of the following variables have not been defined in
            your 'config.md': 'website_title', 'website_descr', 'website_url'.
            The feed will not be (re)generated.
            \nRelevant pointer:
            $POINTER_PV
            """)
        return nothing
    end

    endswith(rss_link, "/") || (rss_link *= "/")
    rss_descr = fd2html(rss_descr; internal=true) |> remove_html_ps |> chomp

    # sort items by pubDate
    RSS_DICT_SORTED = sort(OrderedDict(RSS_DICT), rev = true, byvalue = true, by = x -> x[1].pubDate)

    # Global feed; include all items
    rss_path = joinpath(PATHS[:site], "feed.xml")
    ## Remove tags vector
    rss_items = OrderedDict{String,RSSItem}(k => v[1] for (k, v) in RSS_DICT_SORTED)
    ## Write the file
    write_rss_xml(rss_path, rss_title, rss_descr, rss_link, rss_items)

    # Tag specific feed; filter items by tag
    ## Collect all tags
    tags = Set{String}()
    foreach(x -> union!(tags, x[2]), values(RSS_DICT))
    for tag in tags
        rss_path = joinpath(path(:tag), refstring(tag), "feed.xml")
        ## Filter items containing this tag only
        rss_items = OrderedDict{String,RSSItem}(k => v[1] for (k, v) in RSS_DICT_SORTED if tag ∈ v[2])
        ## Find the relative path for the tag-feeds
        # so this will
        rss_rel = joinpath(
            strip(globvar("tag_page_path"), '/'),
            refstring(tag)
        )
        ## Write the file
        write_rss_xml(rss_path, rss_title, rss_descr, rss_link, rss_items, rss_rel)
    end

    return nothing
end


function write_rss_xml(rss_path, rss_title, rss_descr, rss_link, rss_items, rss_rel="")
    # is there an RSS file already? if so remove it
    isfile(rss_path) && rm(rss_path)
    # make sure the directory exists
    mkpath(dirname(rss_path))

    # create a buffer which will correspond to the output
    rss_buff = IOBuffer()
    write(rss_buff,
        """
        <rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom" xmlns:content="http://purl.org/rss/1.0/modules/content/">
        <channel>
          <title><![CDATA[$rss_title]]></title>
          <description><![CDATA[$(fix_relative_links(rss_descr, rss_link))]]></description>
          <link>$rss_link</link>
          <atom:link href="$(rss_link)$(rss_rel)feed.xml" rel="self" type="application/rss+xml" />
        """)


    # loop over items
    for (k, v) in rss_items
        full_link = rss_link * lstrip(v.link, '/')
        full_link = replace(full_link, r"index\.html$" => "")
        write(rss_buff,
          """
            <item>
              <title><![CDATA[$(v.title)]]></title>
              <link>$(full_link)</link>
              <description>
                <![CDATA[
                    $(fix_relative_links(v.description, rss_link))
                    $(ifelse(isempty(v.content),
                        "",
                        "<content:encoded><![CDATA[$(fix_relative_links(v.content, rss_link))]]></content:encoded>")
                      )
                    <br>
                    <a href=\"$(full_link)\">Read more</a>
                  ]]></description>",
                "]]>
              </description>
              <content:encoded><![CDATA[$(fix_relative_links(v.content, rss_link))]]></content:encoded>"))
          """)
        for elem in (:author, :category, :comments, :enclosure)
            e = getproperty(v, elem)
            isempty(e) || write(rss_buff,
              """
                  <$elem>$e</$elem>
              """)
        end
        write(rss_buff,
          """
              <guid>$(full_link)</guid>
              <pubDate>$(Dates.format(v.pubDate, "e, d u Y")) 00:00:00 UT</pubDate>
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





"""
    remove_html_ps

Convenience function to remove <p> and </p> in RSS description (not supposed to
happen).
"""
remove_html_ps(s::String)::String = replace(s, r"</?p>" => "")

"""
$SIGNATURES

RSS should not contain relative links so this finds relative links and prepends
them with the canonical link.

Example:

    julia> fix_relative_links(raw"src=/foo/bar", "base.com")
    "src=base.com/foo/bar"
"""
function fix_relative_links(s::AS, base_link::String)::String
    isempty(strip(base_link, '/')) && return String(s)
    if !endswith(base_link, '/')
        base_link *= '/'
    end
    return replace(s, PREPATH_FIX_PAT => SubstitutionString("\\1=\\2$base_link"))
end

"""
$SIGNATURES

Create an `RSSItem` out of the provided fields defined in the page vars.
"""
function add_rss_item()
    link  = url_curpage()
    title = jor("rss_title", "title")
    descr = jor("rss", "rss_description")

    descr = fd2html(descr; internal=true) |> remove_html_ps |> chomp

    content = ""
    if globvar(:rss_full_content)::Bool
        raw = read(locvar(:fd_rpath)::String, String)
        m = convert_md(raw; isinternal=true)
        # remove all `{{}}` functions
        m = replace(m, r"{{.*?}}" => "")
        content = convert_html(m)
    end

    author    = locvar(:rss_author)::String
    category  = locvar(:rss_category)::String
    comments  = locvar(:rss_comments)::String
    enclosure = locvar(:rss_enclosure)::String

    # Keep track of tags for tag specific feeds
    tags = locvar(:tags)::Vector{String}

    pubDate = locvar(:rss_pubdate)::Date
    if pubDate == Date(1)
        pubDate = locvar(:date)::Date
        if !isa(pubDate, Date) || pubDate == Date(1)
            pubDate = locvar(:fd_mtime_raw)::Date
        end
    end

    # warning for title which should really be defined
    isnothing(title) && (title = "")
    isempty(title)   && print_warning("""
        An RSS description was found but without title for page '$link'.
        """)

    rss = RSSItem(title, link, descr, content, author, category, comments, enclosure, pubDate)

    res = RSS_DICT[link] = (rss, tags)
    return res
end
