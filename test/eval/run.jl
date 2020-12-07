@testset "parse_code" begin
    c = """
    a = 7
    println(a); a^2
    """
    exs = F.parse_code(c)
    @test exs[1] == :(a=7)
    @test exs[2].args[1] == :(println(a))
    @test exs[2].args[2] == :(a ^ 2)
    # invalid code is fine
    c = """
    a = 7
    f = foo(a = 3
    """
    exs = F.parse_code(c)
    @test exs[1] == :(a = 7)
    @test exs[2].head == :incomplete
    @test exs[2].args[1] == "incomplete: premature end of input"
    # empty code
    c = ""
    exs = F.parse_code(c)
    @test isempty(exs)
end

@testset "run_code" begin
    mn  = F.modulename("foo/path.md")
    mod = F.newmodule(mn)
    junk = tempname()

    # empty code
    c = ""
    @test isnothing(F.run_code(mod, c, junk))

    # code with no print
    c = """
        const a = 5
        a^2
        """
    r = F.run_code(mod, c, junk)
    @test r == 25
    @test isempty(read(junk, String))

    # code with print
    c = """
        using Random
        Random.seed!(555)
        println("hello")
        b = randn()
        b > 0
        """
    r = F.run_code(mod, c, junk)

    @test r == false
    @test read(junk, String) == "hello\n"

    # code with show
    c = """
        x = 5
        @show x
        y = 7;
        """
    r = F.run_code(mod, c, junk)
    @test isnothing(r)
    @test read(junk, String) == "x = 5\n"

    stacktrace = """
        DomainError with -1.0:
        sqrt will only return a complex result if called with a complex argument. Try sqrt(Complex(x)).
        Stacktrace:
         [1] throw_complex_domainerror(::Symbol, ::Float64) at ./math.jl:33
         [2] sqrt at ./math.jl:573 [inlined]
         [3] sqrt(::Int64) at ./math.jl:599
         [4] top-level scope at none:1
         [5] eval at ./boot.jl:331 [inlined]
         [6] (::Franklin.var"#96#98"{Module,Array{Any,1},Int64})() at /home/rik/git/FR/src/eval/run.jl:71
         [7] redirect_stdout(::Franklin.var"#96#98"{Module,Array{Any,1},Int64}, ::IOStream) at ./stream.jl:1150
         [8] (::Franklin.var"#95#97"{Module,String,Array{Any,1},Int64})(::IOStream) at /home/rik/git/FR/src/eval/run.jl:67
         [9] open(::Franklin.var"#95#97"{Module,String,Array{Any,1},Int64}, ::String, ::Vararg{String,N} where N; kwargs::Base.Iterators.Pairs{Union{},Union{},Tuple{},NamedTuple{(),Tuple{}}}) at ./io.jl:325
        """
    @test !occursin("redirect_stdout", F.trim_stacktrace(stacktrace))

    # code with error
    c = """
        e = 0
        a = sqrt(-1)
        b = 7
        """

    s = @capture_out F.run_code(mod, c, junk)
    @test occursin("Warning: in <input string>", s)
    @test occursin("error of type 'DomainError'", s)
    @test occursin("Checking the output files", s)
    @test occursin("throw_complex_domainerror(::Symbol, ::Float64) at", s)
    @test !occursin("redirect_stdout", s)
end

@testset "i462" begin
    s = raw"""
       A
       ```julia:ex
       1 # hide
       ```
       \show{ex}

       B""" |> fd2html_td
    @test isapproxstr(s, """
        <p>A</p>
        <pre><code class="plaintext">1</code></pre>
        <p>B</p>
        """)
    s = raw"""
       A
       ```julia:ex
       "hello" # hide
       ```
       \show{ex}

       B""" |> fd2html_td
    @test isapproxstr(s, """
        <p>A</p>
        <pre><code class="plaintext">"hello"</code></pre>
        <p>B</p>
        """)
end
