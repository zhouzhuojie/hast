@demoContent =
"""
//Hast
=========

Presentation On the Fly
---------------

////
How it works
-------------------

<iframe src="http://www.screenr.com/embed/oThH" width="800" height="500" frameborder="0"></iframe>

//// <!-- Page Divider -->

Introduction
---------------------

Hast.me is a WYSIWYG markdown flavor presentation tool made for everyone! We love markdown, did I mention [it](http://daringfireball.net/projects/markdown/)? It uses [github style markdown](https://help.github.com/articles/github-flavored-markdown).


> ##### Big Thanks to these great open source projects: 
> ##### 
[Hackynote](https://github.com/thiagofelix/hackynote)
[DeckJS](https://github.com/imakewebthings/deck.js)
[Marked](https://github.com/chjj/marked)
[aceEditor](https://github.com/ajaxorg/ace)
[Meteor](http://meteor.com/)
[PrismJS](http://prismjs.com/)

////

Sync between the editor and presentation
---------------------

![](http://i1336.photobucket.com/albums/o641/00zzj/Hast/Screenshot_062313_121713_AM_zps1001580f.jpg)

////

Broadcast to your audience
---------------
![](http://i1336.photobucket.com/albums/o641/00zzj/Hast/Screenshot_062313_123238_AM_zps1acb06bb.jpg)

###### Control the slides and hot push your changes
////

Guess you love Maths
------------
* Inline math $S = \\sum_{i=1}^nx_i$.

* The probability of getting k heads when flipping n coins is

$$P(E)   = {n \\choose k} p^k (1-p)^{ n-k} $$

* A Rogers-Ramanujan Identity

$$1 +  \\frac{q^2}{(1-q)}+\\frac{q^6}{(1-q)(1-q^2)}+\\cdots =
\\prod_{j=0}^{\\infty}\\frac{1}{(1-q^{5j+2})(1-q^{5j+3})} $$

* A Rogers-Ramanujan Identity

$$\\frac{1}{\\Bigl(\\sqrt{\\phi \\sqrt{5}}-\\phi\\Bigr) e^{\\frac25 \\pi}} =
1+\\frac{e^{-2\\pi}} {1+\\frac{e^{-4\\pi}} {1+\\frac{e^{-6\\pi}}
{1+\\frac{e^{-8\\pi}} {1+\\ldots} } } }$$

////

And coding? (cont'd.)
---------------------
#### Python sample code
```python
def qsort1(list):
    if list == []:
        return []
    else:
        pivot = list[0]
        lesser = qsort1([x for x in list[1:] if x < pivot])
        greater = qsort1([x for x in list[1:] if x >= pivot])
        return lesser + [pivot] + greater

```
////

And coding?
---------------
#### Javascript sample code
```javascript
function qsort(array, begin, end)
{
  if(end-1>begin) {
    var pivot=begin+Math.floor(Math.random()*(end-begin));

    pivot=partition(array, begin, end, pivot);

    qsort(array, begin, pivot);
    qsort(array, pivot+1, end);
  }
}

```
////

Image?
----------

![](http://neeleshb.github.io/ghyd-html5/images/html5_sticker.png)


////
Features
-----------

* #### Save as you type...
* #### Share public presentations
* #### Sync everything
* #### Use iframe to include anything you want in your hast, including PDFs, D3 visualization, videos etc.
* #### Easy user privacy control
////

End
====================

Let's get started! [Hast.me]()
-------------------
"""
