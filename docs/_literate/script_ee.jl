# Some **really cool** maths:
#
# $$ \exp(i\pi) + 1 \quad = \quad 0 $$
#
# We can show this with some code:

x = exp(im*π) + 1

# that looks close to zero but

x ≈ 0

# however

abs(x) < eps()

# #### Conclusion
#
# The equation is proven thanks to our very rigorous proof.
