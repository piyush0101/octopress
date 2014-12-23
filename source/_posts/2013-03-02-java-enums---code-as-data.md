---
layout: post
title: "Java enums - Code as Data?"
description: ""
category: 
tags: [enum, code as data]
---

Smart enums in Java are a concept that probably are the closest to the concept of higher order functions in functional programming languages such as Haskell, Scala, Clojure, ML etc. One major advantage of higher order functions is that you can use them as data and pass around the system and execute them wherever you want to. They are more convenient than anonymous inner classes and less verbose. Before going further, this post is in no way to defend the shortcomings of the java programming language. Java language has started to show its age with the rise of more powerful, expressive languages like Scala and Clojure which are slowly but surely making their way into the mainstream.

There is a pattern in java which I feel is really useful but have not seen it being used a lot. The pattern of smart enums where you can easily pass executable enums around and even save them to a persistent store as immutable data. Title of the post may not justify the non [homoiconicity][HI] of the java programming language. There is no way to do that kind of meta programming stuff that you can do in homoiconic languages like lisp. However, there is an introduction of the 'code as data' philosophy on the JVM in Clojure. Anyways, coming back to the point. Anonymous inner classes are not the only way to emulate higher order functions in Java. Smart enums also make it possible in a lesser verbose manner. I will give a short example on how:

[HI]: http://en.wikipedia.org/wiki/Homoiconicity

{% highlight java %}
public enum TweetFilter {

    UPPERCASE() {
        public String filter(String tweet) {
            return tweet.toUpperCase();
        }
    },

    LOWERCASE() {
          public String filter(String tweet) {
              return tweet.toLowerCase();
          }
    },

    PROFANITY() {
        public String filter(String tweet) {
            return tweet.replaceAll("fucking", "***");
        }
    };

    public abstract String filter(String tweet);

}

{% endhighlight %}

This is a very simple smart enum which can execute different filters on a string as needed. If you look at the bytecode of an enum like this, you would see that these are essentially abstract classes. That's why if you want your enum to have some behavior, you need to declare your abstract methods and override them in individual enums. Now, you can use your filters individually or compose them to form a chain of filters.

{% highlight java %}

Filter.UPPERCASE.filter("smart enums are good!");

Filter.PROFANITY.filter(Filter.UPPERCASE.filter("smart enums are fucking awesome"))

{% endhighlight %}

Whenever you are passing data/code around, it is always advisable to keep it immutable so that it is easy to reason about. Along the same lines, stateless smart enums are easier to work with! In the above example, we have enums with pure functions with no side effects. Since the enums we created are stateless, we do not really need to worry about serializability. Java enums are serializable by default. You need not extend/implement the Serializable interface to make them serializable. However, being stateless and not worrying about serializability may not be that simple. If the parameter to your enum method is a class then you do need to have that parameter class as Serializable. Since java String class is Serializable, we did not have to worry about it. So, you can easily use your smart enums over the wire too!

There is one more pattern with enums that I feel is immensely useful. Storing enums as data and constructing them back when needed. Suppose you have a requirement of showing some enumerable data on a UI in a human readable form. That data is shown as a column in some table. Clearly, our enum names above in the Filter enum are too cryptic to be shown to the user. In those cases, we would typically have a human understandable description attached with the enum.

{% highlight java %}

public enum TweetFilter {

    UPPERCASE("Uppercase Filter") {
        public String filter(String tweet) {
            return tweet.toUpperCase();
        }
    },

    LOWERCASE("Lowercase Filter") {
          public String filter(String tweet) {
              return tweet.toLowerCase();
          }
    },

    PROFANITY("Profanity Filter") {
        public String filter(String tweet) {
            return tweet.replaceAll("fucking", "***");
        }
    };

    private String description;

    public String stringValue() {
	return description;
    }

    public abstract String filter(String tweet);

}

{% endhighlight %}

You can see the striking similarity of enums with abstract classes here. Abstract methods of the enum are overridden by each enum while the concrete method `stringValue()` is the part of the enum declaration. 

There are a couple of advantages of this approach. Representation and code are loosely coupled. If business comes back saying they want to see something else as the description, it is really easy to change the description as opposed to refactoring code if we were using the `toString()` method on the enum itself. Another advantage, very closely related with the one just mentioned, is that you can save your enums in the persistent store instead of saving the actual string representation. As we mentioned earlier, if this representation was part of a table column in a UI, you would probably need to store it somewhere to populate the table with data on demand. It is really easy to re construct your enums. If your Filter enum is saved to a persistent storage as `PROFANITY`, you can easily construct it in your code as:

{% highlight java %}
Filter.valueOf("PROFANITY");
{% endhighlight %} 

and there you have the PROFANITY filter in your hand. You can use it to display data in the table or execute behavior that is defined with the enum. Here we have an executable data!

One wise philosophy in software development is to keep **temporal coupling** really low in your code. This is kind of leaning towards that.
