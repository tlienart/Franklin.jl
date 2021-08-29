# Specific warning that will occur in more than one setting
# otherwise warnings that happen in only a single context just use
# `print_warning`

hfun_unknown_arg1_warn(name, argname) = """
    A h-function call '{{$name $argname}}'$(ifelse(String(name)=="fill",
    " (or '{{$argname}}')", "")) has argument '$argname' which
    doesn't match a page variable available in the current scope. It might have
    been misspelled or should be defined via a '@def $argname = ...' either
    locally on the page or globally in 'config.md'.
    \nRelevant pointers:
    $POINTER_PV
    """ |> print_warning

hfun_misc_warn(name, msg) = """
    A h-function call '{{$name ...}}' has some issue(s).
    $msg
    """ |> print_warning

mddef_warn(key, value, acc) = """
    Page var '$key' (type(s): $acc) cannot be set to value '$value' of type
    $(typeof(value)). That assignment will be ignored.
    \nRelevant pointers:
    $POINTER_PV
    """ |> print_warning

config_warn() = """
    No 'config.md' file found. It is recommended to keep one.
    \nRelevant pointers:
    $POINTER_WORKFLOW
    """ |> print_warning

external_config_warn(filepath) = """
    File '{{$filepath}}' not found. Library was not included.
    \nRelevant pointers:
    $POINTER_WORKFLOW
    """ |> print_warning

# --- utils ---

function get_source()
    # context
    source = FD_ENV[:SOURCE]
    isempty(source) || return source
    return "unknown"  # unlikely outside of testing
end

printyb(msg) = printstyled(msg, color=:yellow, bold=true)

function print_warning(msg)
    FD_ENV[:SHOW_WARNINGS] || return
    printyb("┌ Franklin Warning: ")
    print("in <$(get_source())>\n")
    for line in split(strip(msg), '\n')
        printyb("│ ")
        println(line)
    end
    printyb("└\n")
    FD_ENV[:FAIL_ON_WARNING] && throw(ErrorException("`fail_on_warning` is true, so exiting with error"))
    return
end
