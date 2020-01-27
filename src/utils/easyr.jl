function rprint(s::AS)::Nothing
    dwidth  = displaysize(stdout)[2]
    lstring = lastindex(s)
    lstring < dwidth && return rprint_under(s, dwidth)
    return rprint_over(s, lstring, dwidth)
end

function rprint_under(s::AS, dw::Int)::Nothing
    # print the string, padded to the limit
    print(rpad("\r$s", dw))
    return nothing
end


# - Make the (...) travel around so that get an idea of where we are
# - corner case

function rprint_over(s::AS, ls::Int, dw::Int)::Nothing
    # unreasonable case
    dw < 20 && return print("\r$s")
    # standard case
    fend = prevind(s, ls-7)
    eos  = s[fend:end]

    mos  = " (...) "

    fbeg = prevind(s, dw - lastindex(fend) - lastindex(mos) - 8)
    bos  = s[1:fbeg]

    # construct
    # bos (...) end
    proxy_string = bos * " (...) " * eos * " "

    return rprint_under(proxy_string, dw)
end
