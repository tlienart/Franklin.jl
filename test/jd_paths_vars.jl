const td = mktempdir()
J.JD_FOLDER_PATH[] = td

J.def_GLOB_VARS!()
J.def_GLOB_LXDEFS!()

@testset "Paths" begin
    P = J.set_paths!()

    @test J.JD_PATHS[:f]       == td
    @test J.JD_PATHS[:in]      == joinpath(td, "src")
    @test J.JD_PATHS[:in_css]  == joinpath(td, "src", "_css")
    @test J.JD_PATHS[:in_html] == joinpath(td, "src", "_html_parts")
    @test J.JD_PATHS[:libs]    == joinpath(td, "libs")
    @test J.JD_PATHS[:out]     == joinpath(td, "pub")
    @test J.JD_PATHS[:out_css] == joinpath(td, "css")

    @test P == J.JD_PATHS

    mkdir(J.JD_PATHS[:in])
    mkdir(J.JD_PATHS[:in_pages])
    mkdir(J.JD_PATHS[:libs])
    mkdir(J.JD_PATHS[:in_css])
    mkdir(J.JD_PATHS[:in_html])
    mkdir(J.JD_PATHS[:assets])
end

# copying _libs/katex in the J.JD_PATHS[:libs] so that it can be used in testing
# the js_prerender_math
cp(joinpath(dirname(dirname(pathof(JuDoc))), "test", "_libs", "katex"), joinpath(J.JD_PATHS[:libs], "katex"))

@testset "Set vars" begin
    d = J.JD_VAR_TYPE(
    	"a" => 0.5 => (Real,),
    	"b" => "hello" => (String, Nothing))
    J.set_vars!(d, ["a"=>"5", "b"=>"nothing"])

    @test d["a"].first == 5
    @test d["b"].first == nothing

    @test_logs (:warn, "Doc var 'a' (type(s): (Real,)) can't be set to value 'blah' (type: String). Assignment ignored.") J.set_vars!(d, ["a"=>"\"blah\""])
    @test_logs (:error, "I got an error (of type 'DomainError') trying to evaluate '__tmp__ = sqrt(-1)', fix the assignment.") J.set_vars!(d, ["a"=> "sqrt(-1)"])

    # assigning new variables

    J.set_vars!(d, ["blah"=>"1"])
    @test d["blah"].first == 1
end


@testset "Def+coms" begin # see #78
    st = raw"""
        @def title = "blah" <!-- comment -->
        @def hasmath = false
        etc
        """ * J.EOS
    (m, jdv) = J.convert_md(st)
    @test jdv["title"].first == "blah"
    @test jdv["hasmath"].first == false
end
