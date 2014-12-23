---
layout: post
title: "Never block the UI"
description: ""
category:
tags: [swing, java, async]
---

One of the major factors in providing a good user experience is UI responsiveness. Sluggish user interfaces are always a pain to work with and drive much of users' frustrations. I remember a few years back when Facebook launched their mobile app, they had a number of issues where the app was sluggish, would lock up the UI while you were scrolling, would respond to finger taps very slowly or not respond at all. I have seen a number of enterprise [Swing][swing] (Java GUI widget toolkit) applications that are slow, lock up the UI while running computations and do not let you do anything until they are done.

There are two parts to a UI workflow - (i) Submitting a task for execution, (ii) Getting responses back and rendering them on the UI. It is very important to make sure that these two things maintain UI responsiveness. If a task is a long running computation, it should not block the user from doing other things.

Swing is single threaded. All UI events (mouse clicks, drag and drop, window resizing etc) are dispatched on the [Event Dispatching Thread (EDT)][edt]. EDT is basically a [FIFO][fifo] queue of dispatched events which are executed in order. Any synchronous computation in this queue is going to block the events that are waiting. So, if you click on a button while this blocking operation is in progress, you would not notice any response from the UI. After the blocking operation is done, UI becomes responsive again. Sometimes, even blocking operations that take milliseconds have the combined effect of making the UI difficult to work with. Therefore, its preferable to only have UI rendering stuff on the EDT. Here is a sample [clojure][clojure] code which creates a button with an asynchronous listener.

{% highlight clojure %}
(defn create-async
  [args]
  (let [button (JButton. (args :title))]
    (let [listener
          (proxy [ActionListener] []
           (actionPerformed [event]
                        (.start
                         (Thread.
                          (proxy [Runnable] []
                                    (run []
                                         (apply (args :listener) [])))))))]
    (.addActionListener button listener)
      button)))
{% endhighlight %}

The code above adds an action listener to a button and starts a new thread to execute the function body passed in. EDT is free to process other events. To an avid reader, the next question would be "how do I get the response back from the forked off thread and update the UI components?". Java provides a utility class by the name [SwingUtilities][swing-utilities] that can help us do that. `SwingUtilities` has a static method [invokeLater][invokeLater] which takes a Java `Runnable` and queues it up for execution on the EDT. What's more convenient is that `invokeLater` can be called from a thread which is not EDT. It has the smarts to find the EDT for you and queue up your computation. Another important point to note here is that execution of this `Runnable` on EDT is a blocking operation. So, the only thing that should happen on this runnable should be rendering of UI components with data that has already been generated. Here's a sample `clojure` code for rendering.

{% highlight clojure %}
(defn update
  [text-field]
  (SwingUtilities/invokeLater
   (proxy [Runnable] []
     (run []
          (.setText text-field "Hello World")))))
{% endhighlight %}

The event dispatching thread is called the [primordial worker][primordial] in Adobe Flash and the UI thread in .NET Framework and Android. Same philosophy applies to [Android][android], [iOS][ios], [.NET][net] and possibly other platforms. Create worker threads to do the computations and then update your components with data on the [UI thread][android-run-on-ui]. Android has a `runOnUIThread` method on the `Activity` class that queues actions on the UI thread.

Here's a simple Swing [application][nonblocking-swing] that follows much of what I have said.

[nonblocking-swing]: https://github.com/piyush0101/nonblocking-swing/
[swing]: http://en.wikipedia.org/wiki/Swing_(Java)
[edt]: http://en.wikipedia.org/wiki/Event_dispatching_thread
[invokeLater]: http://docs.oracle.com/javase/7/docs/api/javax/swing/SwingUtilities.html#invokeLater(java.lang.Runnable)
[swing-utilities]: http://docs.oracle.com/javase/7/docs/api/javax/swing/SwingUtilities.html
[clojure]: http://clojure.org/
[android-run-on-ui]: http://developer.android.com/reference/android/app/Activity.html#runOnUiThread(java.lang.Runnable)
[android]: http://en.wikipedia.org/wiki/Android_(operating_system)
[fifo]: http://en.wikipedia.org/wiki/FIFO
[primordial]: http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/flash/system/Worker.html
[ios]: http://en.wikipedia.org/wiki/IOS
[net]: http://en.wikipedia.org/wiki/.NET_Framework
