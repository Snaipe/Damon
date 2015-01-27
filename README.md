
Damon
=====

Bringing functional programming to D.

## What this is:

Damon is a tentative to spice up the D programming language with functional
programming concepts.

## Features:

### Currying:

```d
auto square_and_add = (long x, int y) => x * x + y;
auto partial = curry!square_and_add;
assert (partial(3)(2) == square_and_add(3, 2));
```
