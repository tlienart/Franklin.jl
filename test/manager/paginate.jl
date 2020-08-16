@testset "Paginate" begin
    gotd()
    write(joinpath(td, "config.md"), "")
    mkpath(joinpath(td, "_css"))
    mkpath(joinpath(td, "_layout"))
    write(joinpath(td, "_layout", "head.html"), "HEAD\n")
    write(joinpath(td, "_layout", "foot.html"), "\nFOOT\n")
    write(joinpath(td, "_layout", "page_foot.html"), "\nPG_FOOT\n")
    write(joinpath(td, "index.md"), raw"""
        @def el = ("a", "b", "c", "d")
        ~~~<ul>~~~
        {{paginate el 2}}
        ~~~</ul>~~~
        """)
    write(joinpath(td, "foo.md"), raw"""
        @def a = ["<li>Item $i</li>" for i in 1:10]
        Some content
        ~~~<ul>~~~
        {{paginate a 4}}
        ~~~</ul>~~~
        """)
    serve(single=true, cleanup=false)
    # expected outputs for index
    @test isfile(joinpath("__site", "index.html"))
    @test isfile(joinpath("__site", "1", "index.html"))
    @test isfile(joinpath("__site", "2", "index.html"))
    @test isfile(joinpath("__site", "foo", "index.html"))
    @test isfile(joinpath("__site", "foo", "1", "index.html"))
    @test isfile(joinpath("__site", "foo", "2", "index.html"))
    @test isfile(joinpath("__site", "foo", "3", "index.html"))
    # expected content
    @test read(joinpath("__site", "index.html"), String) // """
        HEAD
        <div class=\"franklin-content\"><p><ul> ab </ul></p>

        PG_FOOT
        </div>
        FOOT"""
    @test read(joinpath("__site", "2", "index.html"), String) // """
        HEAD
        <div class=\"franklin-content\"><p><ul> cd </ul></p>

        PG_FOOT
        </div>
        FOOT"""
    @test read(joinpath("__site", "foo", "1", "index.html"), String) // """
        HEAD
        <div class=\"franklin-content\"><p>Some content <ul> <li>Item 1</li><li>Item 2</li><li>Item 3</li><li>Item 4</li> </ul></p>

        PG_FOOT
        </div>
        FOOT"""
    @test read(joinpath("__site", "foo", "3", "index.html"), String) // """
        HEAD
        <div class=\"franklin-content\"><p>Some content <ul> <li>Item 9</li><li>Item 10</li> </ul></p>

        PG_FOOT
        </div>
        FOOT"""
end
