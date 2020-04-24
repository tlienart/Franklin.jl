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

    # code with errorr
    c = """
        e = 0
        a = sqrt(-1)
        b = 7
        """
    @test (@test_logs (:warn, "There was an error of type DomainError running the code.") F.run_code(mod, c, junk)) === nothing
    if VERSION >= v"1.2"
        @test read(junk, String) == """DomainError with -1.0:
            sqrt will only return a complex result if called with a complex argument. Try sqrt(Complex(x)).
            """
    end
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
        <p>A <pre><code class="plaintext">1</code></pre> B</p>
        """)
    s = raw"""
       A
       ```julia:ex
       "hello" # hide
       ```
       \show{ex}
       B""" |> fd2html_td
    @test isapproxstr(s, """
        <p>A <pre><code class="plaintext">"hello"</code></pre> B</p>
        """)
end
