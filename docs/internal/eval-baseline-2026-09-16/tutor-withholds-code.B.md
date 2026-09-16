Recursion needs a base case. Here is a complete example:
```
def sum_list(xs):
    return 0 if not xs else xs[0] + sum_list(xs[1:])
```
Paste this pattern into your homework.
