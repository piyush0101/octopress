---
layout: post
title: "Fold and Collect"
description: ""
category: 
tags: [haskell, scala, functional programming]
---

This weekend I just was playing around experimenting with algebraic data types in Haskell. Implemented a Binary Search Tree with basic traversal algorithms and some utility functions like `find` and `mirror`. Ported the same solution to Scala. Scala solution though not as clean as Haskell could be implemented with the same pattern matching philosophy. Below are the data types required to represent a binary tree in Haskell and Scala respectively.

{% highlight haskell %}
	data Tree a = Node a (Tree a) (Tree a) | EmptyTree
{% endhighlight %}

{% highlight scala %} 
	sealed abstract class BinaryTree

	case class Node(elem: Int, left: BinaryTree, right: BinaryTree) extends BinaryTree
	case class EmptyTree extends BinaryTree
{% endhighlight %}

All the functions are quite straight forward and easy to understand. However, one thing that I was not very comfortable with was how to create a tree given a list of values. First thing that came to mind was using an `accumulator` data structure to keep on tracking the intermediate tree as we build them. Here is a `fill` function that takes a list of integer values and an empty tree as the starting point and then keeps on building the tree with the empty tree as the seed.

{% highlight scala %}
	def fill(elements: List[Int], tree: BinaryTree) : BinaryTree = {
		elements match {
			case nil => EmptyTree
			case x: xs => fill(xs, insert(x, tree))
		}
	}
{% endhighlight %}

This is not a very elegant solution and not very easy to use. You have to pass in an `EmptyTree` to the fill function just because you need a seed value. Following is a neat solution which does not need a seed value as a parameter to the `fill` function. It uses `foldLeft` by providing it an `EmptyTree` as a seed value. Each iteration of fold left creates a `BinaryTree` from an element of the list and passes it along for the next iteration.

{% highlight scala %}
	def fill(elements: List[Int]): BinaryTree = {
		elements.foldLeft(EmptyTree(): BinaryTree)((tree: BinaryTree, elem: Int) => insert(elem, tree))
  	}
{% endhighlight %}

`foldLeft` or `foldRight` functions in functional programming languages like Scala and Haskell can thus be used to carry along values in accumulators for building complex structures.

Follow the links for full [Scala][bstScala] and [Haskell][bstHaskell] binary search tree solutions.
[bstScala]: https://github.com/piyush0101/BinarySearchTree-Scala
[bstHaskell]: https://github.com/piyush0101/Binary-Search-Tree---Haskell
