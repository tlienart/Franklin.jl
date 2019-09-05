# =============================================================
# Experimenting with Stefan Karpinski's "Shelling out sucks"
# https://julialang.org/blog/2012/03/shelling-out-sucks
# =============================================================

# NOTE (quirky things that may be ok one way or the other)
# - skipping a line in a list --> in jekyll stays part of the same block; not in JuDoc (but that's the julia markdown parser) ==> would require processing lists yourself
#
# =============================================================


# t1 = process shortcuts for links

st = """
    [Perl]:     http://www.perl.org/
    [Python]:   http://python.org/

    (...) like [Perl] and [Ruby].
    """

# t2 = quadruple spaces at the start of a non-empty line indicate code (like ```) provided the
# line is preceded by an empty line

st = """
    Blah

        this is code

    end
    """

st = """
    This will fail:

        irb(main):001:0> dir="src"
        => "src"
        irb(main):002:0> `find #{dir} -type f -print0 | xargs -0 grep foo | wc -l`.to_i
        => 5

    The simple
    """
