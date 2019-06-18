# Troubleshooting

This page is about some of the known errors you may encounter when using JuDoc and how to deal with them.
If you encounter an error that is not mentioned here, then it's probably a bug and it would be great if you could open an issue!

* [Error on interruption](#Error-on-interruption-1)
* [IOStream error](#IOStream-error-1)


## Error on interruption

You may (rarely) get an an error thrown at you when interrupting the server with `<CTRL>+C`, particularly when using Juno.
There are a couple of reasons this may happen, both unrelated to JuDoc.

### Juno

Juno (very rarely) crashes if you coincidentally press `<CTRL>+C` while Juno is doing something in the background (Juno issue [#309](https://github.com/JunoLab/Juno.jl/issues/309)).

The stacktrace you will see will seem particularly obscure, for instance:

```
InterruptException:
_string_n at string.jl:60 [inlined]
StringVector at iobuffer.jl:31 [inlined]
#IOBuffer#320(::Bool, ::Bool, ::Nothing, ::Bool, ::Int64, ::Int64, ::Type{Base.GenericIOBuffer{Array{UInt8,1}}}) at iobuffer.jl:114
(...)
```

or

```
julia> "miniERROR: InterruptException:
Stacktrace:
 [1] poptaskref(::Base.InvasiveLinkedListSynchronized{Task}) at ./task.jl:564
 [2] wait() at ./task.jl:591
(...)
```

**Solution**: ignore the error, restart Julia.

### Not-Juno

The [`LiveServer.jl`](https://github.com/asprionj/LiveServer.jl) package, which handles the live-serving of the files, is based upon [`HTTP.jl`](https://github.com/asprionj/LiveServer.jl).
The latter has a fairly complex codebase with a number of asynchronous tasks and is known to sometimes crash in (somewhat) mysterious ways.

If the stacktrace mentions `uv_write`, `uv_write_async`, `libuv` or something of the sorts, then this is it.

Like the "Juno" case, these errors are caused when you happen to press interrupt just as the package was doing something important in the background.
This is very rare but can happen and you can safely ignore it.

**Solution**: ignore the error, restart Julia.


## IOStream error

See the comment about HTTP.jl in the [subsection above](#Not-Juno-1).
