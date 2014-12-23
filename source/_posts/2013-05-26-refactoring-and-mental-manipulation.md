---
layout: post
title: "Refactoring and Mental Manipulation"
description: ""
category: 
tags: []
---

Have you even run into a disappointing situation of spending a lot of effort refactoring legacy code only to realize other developers not using the patterns that you introduced? This is a very common problem I have seen recently. Good code remains sitting in one place being used only by a handful of people. Organizing a meeting - 'a big honking mutex' - to let other people know of places to find good code, sending emails about the good patterns that you have started do not go very well according to my experience. To mentally manipulate other developers, there has to be a better way. In my opinion, its best done with code. 

I accidentally realized this while refactoring a moderately sized badly written class taking on too many responsibilities. When you see eight `field` dependencies in the class, you know the class is doing too much. Refactoring is best done in small incremental steps. How do you make sure the incremental steps provide the most value when other developers are likely to touch the same code in a matter of days than weeks or months. It is best to discourage anyone who is coming into the same code to not use the old, existing patterns and make it easier for them to use the new ones. Developers who are not very refactoring friendly and do not want to leave the room in a cleaner state than they found it would find the easiest way to get the job done. The easiest way is following the existing pattern which usually is the pattern in majority. For a class which has evolved over many years and grown to be more and more monolithic, it requires a few tricks to refactor effectively and discourage the use of existing not so good patterns. 

If a class has many dependencies, it is very likely that a few dependencies that you are trying to extract out are used in many different places. In that case, it is most likely that you will extract those dependencies but still leave the original ones in the class to have other places in the code still use them as they are. Remember, we said that refactoring is best done in small incremental steps. Our intentions have been good in making the code more maintenable and less error prone but people who are unfamiliar with the same code would probably not realize that in this state. Look at the code below.

{% highlight java %}

public class DataImporter {
    private final DataProvider provider;
    private final A a;
    private final B b;
    private final C c;
    private final D d;
    private final E e;

    public DataImporter(DataProvider provider, A a, B b, C c, D d, E e) {
        this.provider = provider;
        this.a = a;
        this.b = b;
        this.c = c;
        this.d = d;
        this.e = e;
    }
    
    public void m1() {
        a.do();
    }
    
    public void m2() {
        b.process();
        a.do();
    }
    
    public void m3() {
        d.execute();
        b.process();
        c.run();
        a.do();
        e.execute();
    }
}
{% endhighlight %}

If you are trying to do some refactoring in method `m1` which is 100 lines long and uses the dependency `A` and you have figured out an approach which would move that dependency in a different collaborator class, you would probably go ahead with that refactoring and create a new collaborator class with a dependency `A`. Its likely that you will leave the dependency `A` in the old class since its being used in a few other difficult to refactor methods and you are do not want to refactor those methods yet. The problems with this refactoring is that since it is really easy to use the old patterns (since the old dependencies are still there), other developers would probably use that or may even end up in a different refactoring direction altogether. Our intentions have been good but not very effective. A better approach might have been to increase the size of incremental refactoring step to remove the dependency on `A` altogether from this class so that the next person who comes to this class is not even able to use it and is forced to look into the patterns that you have introduced. The key mantra here is to make your patterns easier to use than the existing ones and ofcourse making them visible enough for others to see. 

As a consultant developer,  it is not very feasible for me to rely on communication to make sure that code will evolve as I envisioned. I look out for ways to mentally manipulate other developers with code. It indeed is a very fascinating journey. I highly recommend you to try it out :).
