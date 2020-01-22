# NOTE:
# - this is an experimental script comparing Common Mark specs
# with what Franklin supports. A lot of things break but not all
# of it is a sign of Franklin doing the wrong thing. For instance:
#
# --> support for headers in Franklin is a bit more involved adding links
# to headers by default which Common Mark does not do so of course
# all examples with headers currently fail.
#
# --> common mark accepts stray backticks, Franklin doesn't
#
# --> double backslash mean something specific in Franklin
#
# --> Franklin doesn't cleanly handle <p> </p>
#
# Eventually  the `similar_enough` function will be adjusted to ignore
# those cases.
# --------------------------------------------------------------------

dir_jd = dirname(dirname(pathof(Franklin)))
dir_specs = joinpath(dir_jd, "test", "parser", "common_mark")
tests = read(joinpath(dir_specs, "spec029.json"),  String)

md = eachmatch(r"\"markdown\":\s\"(.*?)\",", tests)
md = [unescape_string(m.captures[1]) for m in md]

html = eachmatch(r"\"html\":\s\"(.*?)\",", tests)
html = [unescape_string(h.captures[1]) for h in html]

function unwrap_identity(s)
    rx = r"&#(.*?);"
    em = eachmatch(rx, s) |> collect
    head = 1
    ss = ""
    for (i, m) in enumerate(em)
        pos   = prevind(s, m.offset)
        if pos > head
           ss *= SubString(s, head, pos)
        end
        c   = Char(parse(Int,m.captures[1]))
        ss *= c
        head = nextind(s, m.offset + ncodeunits(m.match) - 1)
    end
    if head < lastindex(s)
        ss *= SubString(s, head, lastindex(s))
    end
    ss
end

function similar_enough(s_ref, s)
    cleanup(s_ref) == cleanup(s)
end

function cleanup(s)
    s_ = s
    s_ = replace(s_, r"<h(.) id.*?><a href.*?>" => s"<h\1>")
    s_ = replace(s_, "</a></h" => "</h")
    s_ = replace(s_, r"^<p>" => "")
    s_ = replace(s_, r"</p>\n$" => "")
    s_ = replace(s_, "\n</code>" => "</code>")
    s_ = unwrap_identity(s_)
    strip(s_)
end

function preprocess(md)
    md = replace(md, "\$" => "\\\$")
end

function check(r)
    fails = Int[]
    for i in r
        mdi = preprocess(md[i])

        htmli = html[i]
        flag = try
            similar_enough(htmli, mdi |> fd2html_td)
        catch
            false
        end
        if !flag
            println("Breaks example $i")
            push!(fails, i)
        else
            println("Example $i successful [$i]")
        end
    end
    println("FAILURE RATE -- $(round(length(fails)/length(r), digits=2)*100)")
    fails
end

jdc(i) = cleanup(preprocess(md[i]) |> fd2html_td)
htc(i) = cleanup(html[i])

# TABS
# NOTE: issue with `\t`
# - also thing with first line tab (currently not accepted in Franklin)
check(1:11)

# PRECEDENCE (fails because Franklin does not support stray `)
check(12)

check(13:31)

#  setext headings are not supported
check(70)

# INDENTED CODE BLOCKS
println("\n==Indented code blocks==\n")
f = check(77:88)

# HTML code blocks (not expected to work in  Franklin)
# fail: all
# println("HTML code blocks")
# check(117:160)


##########################
##########################


### -- ALL OK

# Blank Lines
println("\n==Blank lines==\n")
f = check(197)

# textual content
println("\n==Textual content==\n")
f = check(647:649)

### --- MOST OK

# Block quotes
println("\n==Block quotes==\n")
f = check(198:222)

# Autolinks
println("\n==Autolinks==\n")
f = check(590:608)

# XXX XXX XXX XXX XXX XXX XXX

### --- MOST NOK

# HEADINGS
println("\n==Headers==\n")
check(32:49)

# FENCED CODE  BLOCKS
println("\n==Fenced code blocks==\n")
f = check(89:116)


# LINK REFERENCE DEFINITIONS
println("\n==Link references definitions==\n")
f = check(161:188)

# Paragraphs
println("\n==Paragraphs==\n")
f = check(189:196)

# List items
println("\n==List items==\n")
f = check(223:270)

# Backslash escapes
println("\n==Backslash escapes==\n")
f = check(298:310)

# Entity and numeric chars
println("\n==Entity and num char==\n")
f = check(311:327)

# Code spans
println("\n==Code spans==\n")
f = check(328:349)

# Emphasis
println("\n==Emphasis==\n")
f = check(350:480)

# Links
println("\n==Links==\n")
f = check(481:567)

# Images
# NOTE:
# - link title not supported
println("\n==Images==\n")
f = check(568:589)

# Raw HTML (XXX should not expect this to work)
println("\n==Raw HTML== (EXPECTED TO FAIL)\n")
f = check(609:629)

# Hard line break
# NOTE: fail due to Julia Markdown chomping off `\n`
println("\n==Hard line breaks== (JMD CHOMP LR)\n")
f = check(630:644)

### -- ALL NOK

# Lists
# NOTE: fail due to Julia Markdown inserting paragraphs in lists
println("\n==List items== (JMD ADDS PARAGRAPH)\n")
f = check(271:296)

# inline
# NOTE: fail due to stray backtick
println("\n==Inlines== (STRAY BACKTICK)\n")
f = check(297)

# soft line break
# NOTE: fail due to Julia's Markdown chomping off the `\n`
println("\n==Soft line breaks (JMD CHOMP  LR)==\n")
f = check(645:646)

# ---------------------------------------------------------
