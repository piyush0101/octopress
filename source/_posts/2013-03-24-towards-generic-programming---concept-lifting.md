---
layout: post
title: "Towards Generic Programming - Concept Lifting"
description: ""
category: 
tags: [generic programming, concept lifting]
---

It is almost invariably the case that I have seen developers caught too much in making the solution 'generic' and be able to handle different kinds of data, data types, concepts etc. I strongly feel this is a wrong approach to coming up with generic solutions. There is a very strong emphasis in the software development community for DRY (Do not replicate yourself). Colleague [Kevin Hickey][Kevin] has an excellent [post][KDRY] on why DRY is important. I have no issues with DRY but I feel premature generifying/drying does not let you see the [concepts that can be lifted][lifting]. You may come up with a generic solution which may seem generic but in reality is missing a lot. It is very important to be able to visualize concepts before lifting them. While I have read authors describing evils of premature optimization, I have not seen a lot written on the cons of premature generalization. 

[KDRY]: http://kevinmhickey.github.com/2013/01/12/why--dry/
[Kevin]: http://kevinmhickey.github.com
[lifting]: http://www.generic-programming.org/about/intro/lifting.php

I may blabber without justifying myself and the best way to justify is to justify with code! I have worked quite a bit with legacy codebases in the Java programming language. Though this blog is not about legacy code, I have definitely seen patterns that have led me to a few discoveries regarding generic programming. One of the anti-pattern that I have seen over and over again is the over use of `if else` and `switch case` conditionals. They significantly increase the [cyclomatic complexity][cyclomatic] of your code and the complexity goes on increasing as the number of branches increase and results in hard to maintain, highy [temporally coupled][temporal], difficult to test code. The question that comes to mind is how did we even end up in such a place. The answer is simple, we did not think hard enough to model our problem in an object oriented way or I would rather take a different perspective on that. We started off well, doing the minimum thing that needed to be done but when we started seeing the patterns repeated over and over again, we did not try to extract them into their own concepts which resulted in an ugly 1000 line long class with a huge cascade of *if elses* or *switch cases*. Here is an example.

[temporal]: http://blog.ploeh.dk/2011/05/24/DesignSmellTemporalCoupling/
[cyclomatic]: http://en.wikipedia.org/wiki/Cyclomatic_complexity

{% highlight java %}

public class ShipmentTableModel extends AbstractTableModel {
    
    private String[] names = {"Shipment Origin", "Shipment Destination", "Tax"};
    private int[] width = {40, 40, 40};
    private boolean[] editable = {false, false, true};
    
    public String getName(int columnIndex) {
        return names[columnIndex];
    }
    
    public int getWidth(int columnIndex) {
        return width[columnIndex];
    }
    
    public boolean isEditable(int columnIndex) {
        return editable[columnIndex];
    }
    
    public Class getColumnClass(int columnIndex) {
        switch (columnIndex) {
            case 0 : return String.class;
            case 1 : return Integer.class;
            case 2 : return Boolean.class;
            default : return Object.class;
        }                           
    }
    
    public boolean validate(int columnIndex, Object value) {
        switch (columnIndex) {
            case 0 : 
                 String aValue = (String) value;
                 return aValue != null && !aValue.equals("");
            case 1 :
                Integer intValue = (Integer) value;
                return intValue != 0;
            case 3:
            default: return true;
        }
    }
}

{% endhighlight %}

This class for sure violates the single responsibility principle. The name of the class says that it is a model class but it is doing a lot more than that. Our TableModel class feeds in data to a few other classes in the system. It is easy to figure of what kind of data those other classes are looking for. Looks like dependent classes are mainly concerned about properties of individual columns in this model. Do we see any concepts in this class which are repeated and can be extracted out? Yes, all the methods in this class take in a column index and give data back for that index. I think there is a `Column` class hiding somewhere. Let us start with something simple. We can extract out properties of a column in an interface and have our concrete columns implement that interface. I personally do not like use of interfaces for such needs but we will slowly move in the right direction. We do not want to get caught up in generalizing everything all at once. 

{% highlight java %}

public interface Column {
    String getName(int columnIndex);
    
    int getWidth(int columnIndex);
    
    Class getColumnClass(int columnIndex);
    
    boolean validate(int columnIndex, boolean value);
}

{% endhighlight %}

and our model class can now just take a list of columns and operate on them and can be possibly renamed to be `TableModel` instead of `ShipmentTableModel` since it is generic enough to take different kinds of columns and delegate the tasks to concrete column classes.

{% highlight java %}
public class TableModel {

    private List<Column> columns;

    public TableModel(List<Column> columns) {
        this.columns = columns;
    }

    public String getName(int columnIndex) {
        return columns.get(columnIndex).getName();
    }

    public int getWidth(int columnIndex) {
        return columns.get(columnIndex).getWidth();
    }

    public boolean isEditable(int columnIndex) {
        return columns.get(columnIndex).isEditable();
    }

    public Class getColumnClass(int columnIndex) {
        return columns.get(columnIndex).getColumnClass();
    }

    public boolean validate(int columnIndex, Object value) {
        return columns.get(columnIndex).validate(value);
    }
}
{% endhighlight %}
 
That looks much cleaner with clear separation of responsibilities. Model is no longer responsible for creating Column concepts and doing anything but delegating work to the actual column classes. More importantly, if we have a need to create a new table for some other purpose, no new model needs to be created. This `TableModel` class can be reused after constructing the appropriate columns from column factories. Separation of concerns in this case is also allowing us to see other possibilities which we will have a look in the coming blogs. Thanks :)
