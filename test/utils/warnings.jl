@testset "warn-pv" begin
    resource()
    d = F.PageVars(
    	"a" => 0.5 => (Real,),
    	"b" => "hello" => (String, Nothing))
    s = @capture_out F.set_vars!(d, ["a"=>"\"blah\""])
    @test occursin("Franklin Warning: in <unknown>", s)
    @test occursin("Page var 'a' (type(s): (Real,)) cannot", s)
    @test occursin("assignment will be ignored",  s)
end

@testset "warn-config" begin
    resource(); gotd()
    s = @capture_out F.process_config()
    @test occursin("Warning: in <config.md>", s)
    @test occursin("No 'config.md' file found", s)
end

@testset "warn-rss" begin
    resource(); gotd()
    empty!(F.RSS_DICT)
    F.set_var!(F.GLOBAL_VARS, "website_title", "Website title")
    F.set_var!(F.GLOBAL_VARS, "website_descr", "Website descr")
    F.set_var!(F.GLOBAL_VARS, "website_url", "https://github.com/tlienart/Franklin.jl/")
    F.def_LOCAL_VARS!()
    set_curpath("hey/ho.md")
    F.set_var!(F.LOCAL_VARS, "rss_title", "")
    s = @capture_out F.add_rss_item()
    @test occursin("Warning: in <unknown>", s)
    @test occursin("An RSS description was found but without title", s)
    @test occursin("for page '/hey/ho/index.html'.", s)
end

@testset "warn-paginate" begin
    resource(); gotd()
    write(joinpath(td, "config.md"), "@def aa = 5")
    mkpath(joinpath(td, "_css"))
    mkpath(joinpath(td, "_layout"))
    write(joinpath(td, "_layout", "head.html"), "HEAD\n")
    write(joinpath(td, "_layout", "foot.html"), "\nFOOT\n")
    write(joinpath(td, "_layout", "page_foot.html"), "\nPG_FOOT\n")
    write(joinpath(td, "index.md"), "INDEX")
    write(joinpath(td, "foo.md"), raw"""
        @def a = ["<li>Item $i</li>" for i in 1:10]
        Some content
        {{paginate abc 4}}
        """)
    s = @capture_out serve(single=true)
    @test occursin("Franklin Warning: in <foo.md>", s)
    @test occursin("A h-function call '{{paginate ...}}' has some", s)
    @test occursin("The page variable 'abc' does not match", s)

    write(joinpath(td, "foo.md"), raw"""
        @def a = ["<li>Item $i</li>" for i in 1:10]
        Some content
        {{paginate a iehva}}
        """)
    s = @capture_out serve(single=true)
    @test occursin("Failed to parse", s)
    @test occursin("(given: 'iehva')", s)
    @test occursin("Setting to", s)

    write(joinpath(td, "foo.md"), raw"""
        @def a = ["<li>Item $i</li>" for i in 1:10]
        Some content
        {{paginate a -5}}
        """)
    s = @capture_out serve(single=true)
    @test occursin("Non-positive number", s)
    @test occursin("('-5' read from -5)", s)
    @test occursin("Setting to", s)

    write(joinpath(td, "foo.md"), raw"""
        @def a = ["<li>Item $i</li>" for i in 1:10]
        Some content
        ~~~<ul>~~~
        {{paginate a 4}}
        ~~~</ul>~~~
        ~~~<ul>~~~
        {{paginate a 4}}
        ~~~</ul>~~~
        """)
    s = @capture_out serve(single=true)
    @test occursin("Multiple calls to", s)
end
