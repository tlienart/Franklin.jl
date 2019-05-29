# This is a test file to make codecov happy, technically all of the
# tests here are already done / integrated within other tests.

@testset "strings" begin
    st = "blah"

    @test J.str(st) == "blah"

    sst = SubString("blahblah", 1:4)
    @test sst == "blah"
    @test J.str(sst) == "blahblah"

    sst = SubString("blah✅💕and etcσ⭒ but ∃⫙∀ done", 1:27)
    @test J.to(sst) == 27

    s = "aabccabcdefabcg"
    for m ∈ eachmatch(r"abc", s)
        @test s[J.matchrange(m)] == "abc"
    end
end


@testset "ocblock" begin
    st = "This is a block <!--comment--> and done"
    τ = J.find_tokens(st, J.MD_TOKENS, J.MD_1C_TOKENS)
    ocb = J.OCBlock(:COMMENT, (τ[1]=>τ[2]))
    @test J.otok(ocb) == τ[1]
    @test J.ctok(ocb) == τ[2]
end


@testset "isexactly" begin
    steps, b, λ = J.isexactly("<!--")
    @test steps == length("<!--") - 1 # minus start char
    @test b == false
    @test λ("<!--") == true
    @test λ("<--") == false

    steps, b, λ = J.isexactly("\$", ['\$'])
    @test steps == 1
    @test b == true
    @test λ("\$\$") == true
    @test λ("\$a") == false
    @test λ("a\$") == false

    rs = "\$"
    steps, b, λ = J.isexactly(rs, ['\$'], false)
    @test steps == nextind(rs, prevind(rs, lastindex(rs)))
    @test b == true
    @test λ("\$\$") == false
    @test λ("\$a") == true
    @test λ("a\$") == false

    steps, b, λ = J.incrlook(isletter)
    @test steps == 0
    @test b == false
    @test λ('c') == true
    @test λ('[') == false
end


@testset "timeittook" begin
    start = time()
    sleep(0.5)

    d = mktempdir()
    f = joinpath(d, "a.txt")
    open(f, "w") do outf
        redirect_stdout(outf) do
            J.time_it_took(start)
        end
    end
    r = read(f, String)
    m = match(r"\[done\s*(.*?)ms\]", r)
    @test parse(Float64, m.captures[1]) ≥ 500
end


@testset "refstring" begin
    @test J.refstring("aa  bb") == "aa-bb"
    @test J.refstring("aa  bb !") == "aa-bb"
    @test J.refstring("aa-bb-!") == "aa-bb-"
    @test J.refstring("aa 🔺 bb") == "aa-bb"
    @test J.refstring("aaa 0 bb s:2  df") == "aaa-0-bb-s2-df"
    @test J.refstring("🔺🔺") == string(hash("🔺🔺"))
    @test J.refstring("blah&#33;") == "blah"
end
