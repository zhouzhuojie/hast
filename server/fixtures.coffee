demoContent =
"""
Welcome to HackyNote
====================
Presentations made by Hackers
-----------------

//// <!-- Page Divider, '////' -->

A Second Level Header
---------------------

Now is the time for all good men to come to
the aid of their country. This is just a
regular paragraph.

The quick brown fox jumped over the lazy
dog's back.

### Header 3

> This is a blockquote.
>
> This is the second paragraph in the blockquote.

////

Phrase Emphasis
---------------------

Some of these words *are emphasized*.
Some of these words _are emphasized also_.

Use two asterisks for **strong emphasis**.
Or, if you prefer, __use two underscores instead__.

////

Math Tex
------------

* The probability of getting k heads when flipping n coins is

$$P(E)   = {n \\choose k} p^k (1-p)^{ n-k} $$

* A Rogers-Ramanujan Identity

$$1 +  \\frac{q^2}{(1-q)}+\\frac{q^6}{(1-q)(1-q^2)}+\\cdots =
\\prod_{j=0}^{\\infty}\\frac{1}{(1-q^{5j+2})(1-q^{5j+3})},
\\quad\\quad \\text{for $|q|&lt;1$}. $$

* A Rogers-Ramanujan Identity

$$\\frac{1}{\\Bigl(\\sqrt{\\phi \\sqrt{5}}-\\phi\\Bigr) e^{\\frac25 \\pi}} =
1+\\frac{e^{-2\\pi}} {1+\\frac{e^{-4\\pi}} {1+\\frac{e^{-6\\pi}}
{1+\\frac{e^{-8\\pi}} {1+\\ldots} } } }$$

////

Lists
---------------------

Unordered (bulleted) lists use asterisks,
pluses, and hyphens (*, +, and -) as list markers.
These three markers are interchangable;

**using** *:

*   Candy.
*   Gum.

**and using** -:

-   Candy.
-   Gum.

Ordered (numbered) lists use regular numbers,
followed by periods, as list markers:

1.  Red
2.  Green
3.  Blue

////

Links
---------------------

Markdown supports two styles for creating links: inline and reference.
With both styles, you use square brackets to delimit the text you want
to turn into a link.

Inline-style links use parentheses immediately after the link text. For example:

This is an [example link](http://example.com/).

Optionally, you may include a title attribute in the parentheses:

This is an [example link](http://example.com/ "With a Title").

Reference-style links allow you to refer to your links by names,
which you define elsewhere in your document:

I get 10 times more traffic from [Google][1] than from
[Yahoo][2] or [MSN][3].

[1]: http://google.com/        "Google"
[2]: http://search.yahoo.com/  "Yahoo Search"
[3]: http://search.msn.com/    "MSN Search"

The title attribute is optional. Link names may contain letters,
numbers and spaces, but are not case sensitive:

I start my morning with a cup of coffee and
[The New York Times][NY Times].

[ny times]: http://www.nytimes.com/

////

Images
---------------------
Image syntax is very much like link syntax.

Inline (titles are optional):

![alt text](http://alturl.com/qx45f "I feel nice coding my presentations \o/o")

////

End
====================

Start you next
---------------------
Hack Presentation
---------------------
"""

if Files.find().count() is 0
  testFile =
    content: demoContent
    type  : 'public'
    test  : true
    userId: ''
    author: 'Hast'
    submitted: new Date().getTime()
    title : 'Welcome'
  Files.insert testFile
