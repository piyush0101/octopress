---
layout: post
title: "Interfaces as Types"
description: ""
category: 
tags: []
---

In my previous [blog][generic], I said that I did not like the idea of having an interface for declaring a `Column` type. I kind of wanted to take a step back and think more about it. I wondered how this kind of abstractness is represented in some other paradigms like logic/functional. Started reading this wonderful [Haskell][haskell] [book][book] by Miran Lipovaca. Haskell is a pure functional language, Java is an object oriented language. Haskell has a very strong type system and does allow you to declare your own types as abstract interfaces and then have their concrete implemenations. Few of the abstract type classes in Haskell are `Eq`, `Ord`, `Show`, `Read` etc. All of these abstract type classes define some beahvior and the instances of these type classes implement that behavior. For instance, 

	ghci> :t (==)
	(==) :: (Eq a) => a -> a -> a

checking the type of `==` operator in [Haskell][haskell] gives you its type signature as above. Type signature tells that the `==` operator is a function that operates on instances of type `Eq`.

Now, coming to java which is an object oriented language with a mix of primitive types and Objects. Java 5 tried to make java a pure object oriented language by having classes for primitive types such as Integer, Boolean, Float etc. To define your own types in an object oriented language you are probably better off defining them as abstract classes or interfaces. I do not know the original motivation of java interfaces but I would not hesitate using them for defining abstract type classes as in [Haskell][haskell] with some behavior, as well as using them as an abstraction for certain system components. In my previous [blog][generic], I have used them as a type class for a new custom type `Column` which is perfectly fine in my opinion. Abstract classes and interfaces can be used interchangeably for defining custom type classes.

[generic]: http://piyush0101.github.com/2013/03/24/towards-generic-programming---concept-lifting/
[book]: http://www.amazon.com/Learn-You-Haskell-Great-Good/dp/1593272839/ref=sr_1_1?ie=UTF8&qid=1364686937&sr=8-1&keywords=haskell
[haskell]: http://www.haskell.org/haskellwiki/Haskell

**PS: This is not a rant about any shortcomings of Java.** 
