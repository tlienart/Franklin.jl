<!--This file was generated, do not modify it.-->
Some **really cool** maths:

$$ \exp(i\pi) + 1 \quad = \quad 0 $$

We can show this with some code:

````julia:ex1
x = exp(im*π) + 1
````

that looks close to zero but

````julia:ex2
x ≈ 0
````

however

````julia:ex3
abs(x) < eps()
````

#### Conclusion

The equation is proven thanks to our very rigorous proof.

