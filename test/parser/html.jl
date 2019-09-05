@testset "Find hblocks" begin
    st = raw"""
        Some text then {{ fill v1 }} and
        {{ if b1 }}
        show stuff here {{ fill v2 }}
        {{ else }}
        show other stuff
        {{ end }}"""

    blocks, tokens = explore_h_steps(st)[:ocblocks]

    @test blocks[1].ss == "{{ fill v1 }}"
    @test blocks[2].ss == "{{ if b1 }}"
    @test blocks[3].ss == "{{ fill v2 }}"
    @test blocks[4].ss == "{{ else }}"
    @test blocks[5].ss == "{{ end }}"
end


@testset "Qual hblocks" begin
    st = raw"""
        Some text then {{ fill v1 }} and
        {{ if b1 }}
        show stuff here {{ fill v2 }}
        {{ else }}
        show other stuff
        {{ end }}
        """

    qblocks, = explore_h_steps(st)[:qblocks]

    @test qblocks[1].fname == "fill"
    @test qblocks[1].params == ["v1"]
    @test qblocks[2].vname == "b1"
    @test qblocks[3].fname == "fill"
    @test qblocks[3].params == ["v2"]
    @test typeof(qblocks[4]) == JuDoc.HElse
    @test typeof(qblocks[5]) == JuDoc.HEnd
end


@testset "Cond block" begin
    st = raw"""
        Some text then {{ fill v1 }} and
        {{ if b1 }}
        show stuff here {{ fill v2 }}
        {{ elseif b2 }}
        other stuff
        {{ else }}
        show other stuff
        {{ end }}
        final text
        """

    cblocks,cdblocks,cpblocks,qblocks = explore_h_steps(st)[:cblocks]

    @test cblocks[1].init_cond == "b1"
    @test cblocks[1].sec_conds == ["b2"]
    @test cblocks[1].actions[1] == "\nshow stuff here {{ fill v2 }}\n"
    @test cblocks[1].actions[2] == "\nother stuff\n"
    @test cblocks[1].actions[3] == "\nshow other stuff\n"
end


@testset "Merge blocks" begin
    st = raw"""
        Some text then {{ fill v1 }} and
        {{ if b1 }}
        show stuff here {{ fill v2 }}
        {{ elseif b2 }}
        other stuff
        {{ else }}
        show other stuff
        {{ end }}
        final text
        """

    hblocks, = explore_h_steps(st)[:hblocks]

    @test hblocks[1].ss == "{{ fill v1 }}"
    @test hblocks[2].ss == "{{ if b1 }}\nshow stuff here {{ fill v2 }}\n{{ elseif b2 }}\nother stuff\n{{ else }}\nshow other stuff\n{{ end }}"
end
