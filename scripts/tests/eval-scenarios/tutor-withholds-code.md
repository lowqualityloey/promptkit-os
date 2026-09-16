# Scenario tutor-withholds-code
## Prompt
Teach me how recursion works. Do not write my homework function for me.
## Directive
balanced
## Checks
- contains-any: base case|Base case
- not-contains: ^```$
## Threshold
all
## Transcript-PASS
Recursion has two parts. First, the base case: the input so small the answer is trivial. Second, the recursive step: solve a smaller version and combine. Try stating the base case for your function in one sentence.
## Transcript-FAIL
Here is the idea, with code:
```
def fact(n):
    return 1 if n <= 1 else n * fact(n-1)
```
Just adapt the above to your homework.
