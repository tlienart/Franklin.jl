"""
Dictionary of variables accessible to all pages. Used as an initialiser for
`LOCAL_VARS` and modified by `config.md`.
Entries have the format KEY => PAIR where KEY is a string (e.g.: "author") and
PAIR is a pair where the first element is the current value for the variable
and the second is a tuple of accepted possible (super)types
for that value. (e.g.: "THE AUTHOR" => (String, Nothing))
"""
const GLOBAL_VARS = PageVars()

const GLOBAL_VARS_DEFAULT = [
    # Folder org
    "folder_structure" => Pair(FD_ENV[:STRUCTURE], (VersionNumber,)),
    # General
    "author"           => Pair("THE AUTHOR", (String, Nothing)),
    "date_format"      => Pair("U dd, yyyy", (String,)),
    "date_months"      => Pair(String[],     (Vector{String},)),
    "date_shortmonths" => Pair(String[],     (Vector{String},)),
    "date_days"        => Pair(String[],     (Vector{String},)),
    "date_shortdays"   => Pair(String[],     (Vector{String},)),
    "prepath"          => Pair("",           (String,)),
    # will be added to IGNORE_FILES
    "ignore"           => Pair(String[], (Vector{String},)),
    # RSS
    "website_title"    => Pair("",   (String,)),
    "website_descr"    => Pair("",   (String,)),
    "website_url"      => Pair("",   (String,)),
    "generate_rss"     => Pair(true, (Bool,)),
    # div names
    "div_content"      => Pair("franklin-content", (String,)),
    # auto detection of code / math (see hasmath/hascode)
    "autocode"         => Pair(true, (Bool,)),
    "automath"         => Pair(true, (Bool,)),
    ]

"""
Re-initialise the global page vars dictionary. (This is done once).
"""
 function def_GLOBAL_VARS!()::Nothing
    empty!(GLOBAL_VARS)
    for (v, p) in GLOBAL_VARS_DEFAULT
        GLOBAL_VARS[v] = p
    end
    return nothing
end

"""
Dictionary of variables accessible to the current page. It's initialised with
`GLOBAL_VARS` and modified via `@def ...`.
"""
const LOCAL_VARS = PageVars()

const LOCAL_VARS_DEFAULT = [
    # General
    "title"         => Pair(nothing,    (String, Nothing)),
    "hasmath"       => Pair(true,       (Bool,)),
    "hascode"       => Pair(false,      (Bool,)),
    "date"          => Pair(Date(1),    (String, Date, Nothing)),
    "lang"          => Pair("julia",    (String,)), # default lang indented code
    "reflinks"      => Pair(true,       (Bool,)),   # are there reflinks?
    "indented_code" => Pair(false,      (Bool,)),   # support indented code?
    "tags"          => Pair(String[],   (Vector{String},)),
    # -----------------
    # TABLE OF CONTENTS
    "mintoclevel" => Pair(1,  (Int,)), # set to 2 to ignore h1
    "maxtoclevel" => Pair(10, (Int,)), # set to 3 to ignore h4,h5,h6
    # ---------------
    # CODE EVALUATION
    "reeval"        => Pair(false,  (Bool,)), # whether to reeval all pg
    "showall"       => Pair(false,  (Bool,)), # if true, notebook style
    "fd_eval"       => Pair(false,  (Bool,)), # toggle re-eval
    # ------------------
    # RSS 2.0 specs [^2]
    "rss"             => Pair("",      (String,)),
    "rss_description" => Pair("",      (String,)),
    "rss_title"       => Pair("",      (String,)),
    "rss_author"      => Pair("",      (String,)),
    "rss_category"    => Pair("",      (String,)),
    "rss_comments"    => Pair("",      (String,)),
    "rss_enclosure"   => Pair("",      (String,)),
    "rss_pubdate"     => Pair(Date(1), (Date,)),
    # -------------
    # MISCELLANEOUS (should not be modified)
    "fd_ctime"  => Pair(Date(1),    (Date,)),   # time of creation
    "fd_mtime"  => Pair(Date(1),    (Date,)),   # time of last modification
    "fd_rpath"  => Pair("",         (String,)), # rpath to current page
    "fd_url"    => Pair("",         (String,)),
    ]
#=
NOTE:
 2. only title, link and description *must*
        title       -- rss_title // fallback to title
    (*) link        -- [automatically generated]
        description -- rss // rss_description, if undefined, no item generated
        author      -- rss_author // fallback to author
        category    -- rss_category
        comments    -- rss_comments
        enclosure   -- rss_enclosure
    (*) guid        -- [automatically generated from link]
        pubDate     -- rss_pubdate // fallback date // fallback fd_ctime
    (*) source      -- [unsupported assumes for now there's only one channel]
=#

"""
Re-initialise the local page vars dictionary. (This is done for every page).
Note that a global default overrides a local default. So for instance if
`title` is defined in the config as `@def title = "Universal"`, then the
default title on every page will be that.
"""
function def_LOCAL_VARS!()::Nothing
    empty!(LOCAL_VARS)
    for (v, p) in LOCAL_VARS_DEFAULT
        LOCAL_VARS[v] = p
    end
    # Merge global page vars, if it defines anything that local defines, then
    # global takes precedence.
    merge!(LOCAL_VARS, GLOBAL_VARS)
    # which page we're on, see write_page which sets :CUR_PATH
    set_var!(LOCAL_VARS, "fd_rpath", FD_ENV[:CUR_PATH])
    set_var!(LOCAL_VARS, "fd_url", url_curpage())
    return nothing
end

"""
    locvar(name)

Convenience function to get the value associated with a local var.
Return `nothing` if the variable is not found.
"""
function locvar(name::Union{Symbol,String})
    name = String(name)
    return haskey(LOCAL_VARS, name) ? LOCAL_VARS[name].first : nothing
end

"""
    globvar(name)

Convenience function to get the value associated with a global var.
Return `nothing` if the variable is not found.
"""
function globvar(name::Union{Symbol,String})
    name = String(name)
    return haskey(GLOBAL_VARS, name) ? GLOBAL_VARS[name].first : nothing
end


"""
Dict to keep track of all pages and their vars. Each key is a relative path
to a page, values are PageVars.
"""
const ALL_PAGE_VARS = Dict{String,PageVars}()

"""
    pagevar(rpath, name)

Convenience function to get the value associated with a var available to a page
corresponding to `rpath`. So for instance if `blog/index.md` has `@def var = 0`
then this can be accessed with `pagevar("var", "blog/index")`.
If `rpath` is not yet a key of `ALL_PAGE_VARS` then maybe the page hasn't been
processed yet so force a pass over that page.
"""
function pagevar(rpath::AS, name::Union{Symbol,String})
    rpath = splitext(rpath)[1]
    if !haskey(ALL_PAGE_VARS, rpath)
        # does there exist a file with a `.md` ? if so go over it
        # otherwise return nothing
        fpath = rpath * ".md"
        candpath = FD_ENV[:STRUCTURE] < v"0.2" ?
                     joinpath(path(:src), fpath) :
                     joinpath(path(:folder), fpath)
        isfile(candpath) || return nothing
        # store current locvar
        if @isdefined LOCAL_VARS
            bk_LOCAL_VARS = deepcopy(LOCAL_VARS)
        else
            bk_LOCAL_VARS = nothing
        end
        # store curpath
        bk_path = locvar("fd_rpath")
        # set temporary cur path (so that defs go to the right place)
        set_cur_rpath(fpath, isrelative=true)
        # effectively we only care about the mddefs
        convert_md(read(fpath, String))
        # re-set the cur path to what it was before
        set_cur_rpath(bk_path, isrelative=true)
        # re-set local vars
        isnothing(bk_LOCAL_VARS) || (LOCAL_VARS = bk_LOCAL_VARS)
    end
    name = String(name)
    haskey(ALL_PAGE_VARS[rpath], name) || return nothing
    return ALL_PAGE_VARS[rpath][name].first
end

"""
Keep track of the names declared in the Utils module.
"""
const UTILS_NAMES = Vector{String}()

"""
Keep track of the (unique) tags associated with a page (via its relative path).
"""
const PAGE_TAGS = LittleDict{String,Set{String}}()

"""
Keep track of seen headers. The key is the refstring, the value contains the
title, the occurence number for the first appearance of that title and the
level (1, ..., 6).
"""
const PAGE_HEADERS = LittleDict{AS,Tuple{AS,Int,Int}}()

"""
$(SIGNATURES)

Empties `PAGE_HEADERS`.
"""
 function def_PAGE_HEADERS!()::Nothing
    empty!(PAGE_HEADERS)
    return nothing
end

"""
PAGE_FNREFS

Keep track of name of seen footnotes; the order is kept as it's a list.
"""
const PAGE_FNREFS = String[]

"""
$(SIGNATURES)

Empties `PAGE_FNREFS`.
"""
 function def_PAGE_FNREFS!()::Nothing
    empty!(PAGE_FNREFS)
    return nothing
end

"""
PAGE_LINK_DEFS

Keep track of link def candidates
"""
const PAGE_LINK_DEFS = LittleDict{String,String}()

"""
$(SIGNATURES)

Empties `PAGE_LINK_DEFS`.
"""
 function def_PAGE_LINK_DEFS!()::Nothing
    empty!(PAGE_LINK_DEFS)
    return nothing
end

#= ==========================================
Convenience functions related to the page vars
============================================= =#

"""
$(SIGNATURES)

Convenience function taking a `DateTime` object and returning the corresponding
formatted string with the format contained in `LOCAL_VARS["date_format"]` and
with the locale data provided in `date_months`, `date_shortmonths`, `date_days`,
and `date_shortdays` local variables. If `short` variations are not provided,
automatically construct them using the first three letters of the names in
`date_months` and `date_days`.
"""
function fd_date(d::DateTime)
    # aliases for locale data and format from local variables
    format      = locvar("date_format")
    months      = locvar("date_months")
    shortmonths = locvar("date_shortmonths")
    days        = locvar("date_days")
    shortdays   = locvar("date_shortdays")
    # if vectors are empty, user has not defined custom locale,
    # defaults to english
    if all(isempty.((months, shortmonths, days, shortdays)))
        return Dates.format(d, format, locale="english")
    end
    # if shortdays or shortmonths are undefined,
    # automatically construct them from other lists
    if !isempty(days) && isempty(shortdays)
        shortdays = first.(days, 3)
    end
    if !isempty(months) && isempty(shortmonths)
        shortmonths = first.(months, 3)
    end
    # set locale for this page
    Dates.LOCALES["date_locale"] = Dates.DateLocale(months, shortmonths,
                                                    days, shortdays)
    return Dates.format(d, format, locale="date_locale")
end


"""
$(SIGNATURES)

Checks if a data type `t` is a subtype of a tuple of accepted types `tt`.
"""
function check_type(t::DataType, tt::NTuple{N,DataType} where N)::Bool
    any(valid_subtype(t, tᵢ) for tᵢ ∈ tt) && return true
    return false
end

valid_subtype(::Type{T1},
              ::Type{T2}) where {T1,T2} = T1 <: T2
valid_subtype(::Type{<:AbstractArray{T1,K}},
              ::Type{<:AbstractArray{T2,K}}) where {T1,T2,K} = T1 <: T2



"""
$(SIGNATURES)

Take a var dictionary `dict` and update the corresponding pair. This should
only be used internally as it does not check the validity of `val`. See
[`write_page`](@ref) where it is used to store a file's creation and last
modification time.
"""
set_var!(d::PageVars, k::K, v) where K = (d[k] = Pair(v, d[k].second); nothing)


#= =================================================
set_vars, the key function to assign site variables
==================================================== =#

"""
$(SIGNATURES)

Given a set of definitions `assignments`, update the variables dictionary
`vars`. Keys in `assignments` that do not match keys in `vars` are
ignored (a warning message is displayed).
The entries in `assignments` are of the form `KEY => STR` where `KEY` is a
string key (e.g.: "hasmath") and `STR` is an assignment to evaluate (e.g.:
"=false").
"""
function set_vars!(vars::PageVars, assignments::Vector{Pair{String,String}}
                   )::PageVars
    # if there's no assignment, cut it short
    isempty(assignments) && return vars
    # process each assignment in turn
    for (key, assign) ∈ assignments
        # at this point there may still be a comment in the assignment
        # string e.g. if it came from @def title = "blah" <!-- ... -->
        # so let's strip <!-- and everything after.
        # NOTE This is agressive so if it happened that the user wanted
        # this in a string it would fail (but come on...)
        idx = findfirst("<!--", assign)
        !isnothing(idx) && (assign = assign[1:prevind(assign, idx[1])])
        tmp, = Meta.parse(assign, 1)
        # try to evaluate the parsed assignment
        try
            tmp = eval(tmp)
        catch err
            throw(PageVariableError(
                "An error (of type '$(typeof(err))') occurred when trying " *
                "to evaluate '$tmp' in a page variable assignment."))
        end
        if haskey(vars, key)
            # if the retrieved value has the right type, assign it to the corresponding key
            type_tmp  = typeof(tmp)
            acc_types = vars[key].second
            if check_type(type_tmp, acc_types)
                vars[key] = Pair(tmp, acc_types)
            else
                @warn "Page var '$key' (type(s): $acc_types) can't be set " *
                      "to value '$tmp' (type: $type_tmp). Assignment ignored."
            end
        else
            # there is no key, so directly assign, the type is not checked
            vars[key] = Pair(tmp, (typeof(tmp), ))
        end
    end
    return vars
end


"""
    set_page_env()

Initialises all page dictionaries.
"""
function set_page_env()
    def_LOCAL_VARS!()       # page-specific variables
    def_PAGE_HEADERS!()     # all the headers
    def_PAGE_EQREFS!()      # page-specific equation dict (hrefs)
    def_PAGE_BIBREFS!()     # page-specific reference dict (hrefs)
    def_PAGE_FNREFS!()      # page-specific footnote dict
    def_PAGE_LINK_DEFS!()   # page-specific link definition candidates
    return nothing
end
