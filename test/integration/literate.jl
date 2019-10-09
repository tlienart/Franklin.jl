scripts = joinpath(J.PATHS[:folder], "scripts")
cd(td); J.set_paths!(); mkpath(scripts)

@testset "Literate-a" begin
    # Post processing: numbering of julia blocks
    s = raw"""
        A

        ```julia
        B
        ```

        C

        ```julia
        D
        ```
        """
    @test J.literate_post_process(s) == """
        A

        ```julia:ex1
        B
        ```

        C

        ```julia:ex2
        D
        ```
        """
end

@testset "Literate-b" begin
    # Literate to JuDoc
    s = raw"""
        # # Rational numbers
        #
        # In julia rational numbers can be constructed with the `//` operator.
        # Lets define two rational numbers, `x` and `y`:

        ## Define variable x and y
        x = 1//3
        y = 2//5

        # When adding `x` and `y` together we obtain a new rational number:

        z = x + y
        """
    path = joinpath(scripts, "tutorial.jl")
    write(path, s)
    opath = J.literate_to_judoc(path)
    @test endswith(opath, joinpath(J.PATHS[:assets], "literate", "tutorial.md"))
    out = read(opath, String)
    @test out == """
        # Rational numbers

        In julia rational numbers can be constructed with the `//` operator.
        Lets define two rational numbers, `x` and `y`:

        ```julia:ex1
        # Define variable x and y
        x = 1//3
        y = 2//5
        ```

        When adding `x` and `y` together we obtain a new rational number:

        ```julia:ex2
        z = x + y
        ```

        """
end
