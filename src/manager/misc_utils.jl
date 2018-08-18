"""
    change_ext(fname)

Convenience function to replace the extension of a filename with another.
"""
change_ext(fname, ext=".html") = splitext(fname)[1] * ext


"""
    time_it_took(start)

Convenience function to display a time since `start`.
"""
function time_it_took(start)
    comp_time = time() - start
    mess = comp_time > 60 ? "$(round(comp_time/60; digits=1))m" :
           comp_time > 1 ? "$(round(comp_time; digits=1))s" :
           "$(round(comp_time*1000; digits=1))ms"
    mess = "[done $mess]"
    println(mess)
end
