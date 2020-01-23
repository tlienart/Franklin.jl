s = """Veggies es bonus vobis, proinde vos postulo essum magis kohlrabi welsh onion daikon amaranth tatsoi tomatillo melon azuki bean garlic.

Gumbo beet greens corn soko endive gumbo gourd. Parsley shallot courgette tatsoi pea sprouts fava bean collard greens dandelion okra wakame tomato. Dandelion cucumber earthnut pea peanut soko zucchini.

Turnip greens yarrow ricebean rutabaga endive cauliflower sea lettuce kohlrabi amaranth water spinach avocado daikon napa cabbage asparagus winter purslane kale.
Celery potato scallion desert raisin horseradish spinach carrot soko. Lotus root water spinach fennel kombu maize bamboo shoot green bean swiss chard seakale pumpkin onion chickpea gram corn pea. Brussels sprout coriander water chestnut gourd swiss chard wakame kohlrabi beetroot carrot watercress.
Corn amaranth salsify bunya nuts nori azuki bean chickweed potato bell pepper artichoke.
"""

@testset "context" begin
    mess = F.context(s, 101)
    @test s[101] == 't'
    # println(mess)
    @test mess == "Context:\n\t...ikon amaranth tatsoi tomatillo melon azuki ... (near line 1)\n	                        ^---\n"

    mess = F.context(s, 211)
    @test s[211] == 't'
    # println(mess)
    @test mess == "Context:\n\t...ey shallot courgette tatsoi pea sprouts fav... (near line 2)\n	                        ^---\n"

    mess = F.context(s, 10)
    # println(mess)
    @test mess == "Context:\n\tVeggies es bonus vobis, proinde... (near line 1)\n	         ^---\n"

    mess = F.context(s, 880)
    # println(mess)
    @test mess == "Context:\n\t... potato bell pepper artichoke. (near line 5)\n	                        ^---\n"
end
