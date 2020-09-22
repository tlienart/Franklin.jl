const td = mktempdir()
flush_td() = (isdir(td) && rm(td; recursive=true); mkdir(td))
F.FOLDER_PATH[] = td

fd2html_td(e)  = fd2html(e; dir=td)
fd2html_tdv(e) = F.fd2html_v(e; dir=td)

F.def_GLOBAL_VARS!()
F.def_GLOBAL_LXDEFS!()

mkdir(F.PATHS[:libs])
# copying _libs/katex in the F.PATHS[:libs] so that it can be used in testing
# the js_prerender_math
cp(joinpath(dirname(dirname(pathof(Franklin))), "test", "_libs", "katex"), joinpath(F.PATHS[:libs], "katex"))

@testset "Set vars" begin
    d = F.PageVars(
    	"a" => 0.5 => (Real,),
    	"b" => "hello" => (String, Nothing))
    F.set_vars!(d, ["a"=>"5", "b"=>"nothing"])

    @test d["a"].first == 5
    @test d["b"].first === nothing

    @test_throws F.PageVariableError F.set_vars!(d, ["a"=> "sqrt(-1)"])

    # assigning new variables

    F.set_vars!(d, ["blah"=>"1"])
    @test d["blah"].first == 1
end

@testset "Def+coms" begin # see #78
    st = raw"""
        @def title = "blah" <!-- comment -->
        @def hasmath = false
        etc
        """
    m = F.convert_md(st)
    @test F.locvar("title") == "blah"
    @test F.locvar("hasmath") == false
end
