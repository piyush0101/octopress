---
layout: post
title: "Easy refactoring with Mockito"
description: 
tagline: "being careful doesn't help if you don't have necessary tools and techniques"

category: 
tags: [mockito, refactoring, legacy code, dependency injection]
---

I aim to provide here a few insights into dealing with difficult to test code. Most of the time, when dealing with [legacy 
code][legacy code], you come across wildly tangled code. Dependencies are not well defined which results in tightly coupled, difficult 
to test code. Legacy systems which are running since a decade, have evolved in a strictly deadline driven, its-ugly-but-it-works 
kind of environment are usually not very easy to fix overnight.

The best kind of system that is easily testable is the one which follows good inversion of control/dependency 
injection patterns. Here are a couple of good articles about [Inversion of Control][IOC] and [Dependency Injection][DI] from 
Paul Hammant and Martin Fowler.

[IOC]: http://paulhammant.com/blog/what-brought-me-to-inversion-of-control-in-the-first-place.html
[DI]: http://martinfowler.com/articles/injection.html
[legacy code]: http://hackerboss.com/legacy-code/

So, as I said, systems which evolve over the course of many years have to be dealt with care and made testable while 
taking small steps at a time. This blog focusses on some hard to test patterns that I have seen myself/others struggling 
to make testable over the course of 
last year or so. Examples here are very simple and may not show the real trouble you have to go through when 
presented with a legacy system but that's the intention. I have tried to extract out those patterns in small examples so 
that you may get the idea which probably gives you a hint to go in a direction which is more feasible at a given point in 
time/refactoring.

As we know that tests are really important and unit tests should be the most number of tests in your [Test Pyramid][Test Pyramid] 
Working with Legacy Code is not easy, you never know what you are changing and more importantly what you are breaking. 
It is very important to have a safety net when modifying Legacy Code. To get that safety net, you need to write tests and 
for writing tests, you need to break dependencies. Michael Feathers' excellent book Working Effectively with Legacy Code
explains various dependency breaking techniques in detail. If you are really curious about the challenges with Legacy Code,
I would highly recommend reading that book.

[Test Pyramid]: http://martinfowler.com/bliki/TestPyramid.html

I am taking a slightly lighter, basic route with basic dependency breaking techniques explained with [Mockito][Mockito]. Mockito is a
wonderful mocking/stubbing library which helps you test your refactoring very easily. Dependencies that I describe here are
classified in following categories:

[Mockito]: http://code.google.com/p/mockito/

* **Inherited Dependency**
* **ThinAir Dependency**
* **Static Dependency**
* **Inverted/Injected Dependency**

The last one is the ideal case and the rest are a few we can refactor in incremental steps to reach the final goal of 
dependency injection. Refactoring from the worst kind of dependency tangle (inherited dependency) to Dependency Injection
may (and is often not) not be a one step process. First goal is to make code testable and then continuously improve.

Now, let's get take a deep dive into these problems and a few possible solutions.
{% highlight java %}
	public class AbstractTweetService {
 
		protected List<Tweet> tweets;
 
		public AbstractTweetService() {
			tweets = TweetDownloader.downloadTweets();
		}
 
		public void persistTweets(String user, int numberOfTweets) {
			TweetPersister.persistTweets();
		} 
	}
 

	public class TweetCountService extends AbstractTweetService {
 
		public TweetCountService() {
			super();
		}
 
		public int countTweetsFrom(String user) {
			int numberOfTweets = 0;
			for (Tweet tweet : tweets) {
				if (tweet.getUser().equals(user)) {
					numberOfTweets++;
				}
			}
			return numberOfTweets;
		}
	}
{% endhighlight %}
Note that there are several things going wrong here other than just inheritance. Inheritance is just making the matters
worse. Couple of things I really don't like with this kind of code (with inheritance) is that it hides dependencies, 
and hides details. There's no way of just reading the TweetCountService class and figuring out where is it getting the 
tweets from. And anyways, there's no clear contract of what this class is supposed to do. Ideal way of solving this 
problem would be to replace inheritance with composition but that may not always be possible due to a lot of factors 
like time, deadlines, deeply tangled code etc. What we need to do in those cases is to make the minimum changes that help 
us in making the code testable. We can take a faster route and get some tests in place and then make more pervasive 
changes. Michael Feathers has done an amazing job in conveying the idea of taking small steps at a time while refactoring
and writing tests in legacy code.

Here's the code after minimal amount of refactoring. Just enough to make the code testable.
{% highlight java %}
	public class AbstractTweetService {

		protected List<Tweet> tweets;
 
		public AbstractTweetService(TweetDownloaderHelper downloaderHelper) {
			tweets = downloaderHelper.downloadTweets();
		}
 
		public void persistTweets(String user, int numberOfTweets) {
			TweetPersister.persistTweets();
		}
	}
 
	public class TweetCountService extends AbstractTweetService {
 
		public TweetCountService(TweetDownloaderHelper downloaderHelper) {
			super(downloaderHelper);
		}
 
		public int countTweetsFrom(String user) {
			int numberOfTweets = 0;
			for (Tweet tweet : tweets) {
				if (tweet.getUser().equals(user)) {
					numberOfTweets++;
				}
			}	
			return numberOfTweets;
		}
	}
{% endhighlight %}
We did not get rid of the inheritance hierarchy, since that would have been a pervasive change and we did not have any 
tests to start with. Michael Feathers has a good section about constructors doing too much work and how to parameterize
constructors to break the dependencies. This is a similar technique that we use here. We create a TweetDownloaderHelper 
and pass it into the newly created constructor for AbstractTweetService. Since the constructor is parameterized, we can 
now easily mock the dependency on TweetDownloaderHelper. Mockito uses [asm][asm] and [cglib][cglib] libraries to generate byte code at 
runtime. It subclasses the mocked class on which you can then set expectations. This is an object [seam][seam] that we identified 
but we need not Extract Interface and implement that interface with a fake object since mockito can do that work for us.
However, if your development strategy is such that you want to identify link/object seams in the system which probably
are dependent on external services, it would be really useful to extract interfaces and provide their stubbed/test 
implementations in your CI builds. Seams are really powerful! [Spring][Spring]can also help you in this strategy with its context 
based bean lookups. You can run your build with a production context (with all the required services) / test context 
(with fake implementations of all the services) / partial contexts (with some of the services mocked). I recently used 
Spring to do this at one of our clients. We were integrating with an external service which we did not care for most of
our tests. I could easily separate out the JNDI lookup implementation and a fake implementation with Spring and created
separate contexts for both of them. Rest everything worked like magic! Again, while working with legacy code, always keep
an eye out for [seams][seams]. 

[seam]: http://www.informit.com/articles/article.aspx?p=359417&seqNum=3
[seams]: http://www.informit.com/articles/article.aspx?p=359417&seqNum=3
[Spring]: http://www.springsource.org/
[CI]: http://en.wikipedia.org/wiki/Continuous_integration
[asm]: http://asm.ow2.org/
[cglib]: http://cglib.sourceforge.net/

And, here's a test for our refactoring. Uses mockito to mock the dependency.
{% highlight java %}
	public class TweetCountServiceInheritanceTest {

		@Test
		public void shouldReturnZeroTweetsForAUserWithNoTweets() {
			TweetDownloaderHelper downloadHelper = mock(TweetDownloaderHelper.class);
			TweetCountService tweetCountService = new TweetCountService(downloadHelper);

			Tweet tweet1 = new Tweet("piyush", "mockito is awesome!");
			Tweet tweet2 = new Tweet("piyush", "coding is my favorite stress buster!");
			Tweet tweet3 = new Tweet("kate", "i love spying with mockito)");

			when(downloadHelper.downloadTweets()).thenReturn(asList(tweet1, tweet2, tweet3));

			int numberOfTweets = tweetCountService.countTweetsFrom("cece");

			assertEquals(0, numberOfTweets);
		}
	}
{% endhighlight %}
Other kinds of dependencies which infiltrate the code and make it really hard to test are static dependencies and thin air
dependencies. Static dependencies for me are static method calls to a util/service class within some method. Static 
dependencies can come as global references, singletons or just plain static method calls. I generally use extract method 
and override refactoring to make this code more testable. One good thing about mockito is its support for partial mocks. 
You can 'spy' on objects and mock only certain methods of the class. This is really powerful in the sense that in your test
class you do not need to write boiler plate code of creating a class and overriding the methods that you need. I had 
wished for this convenience while testing with [EasyMock][EasyMock] and [Unitils][Unitils]. Again, if you 
have to make methods protected instead of private, it may be worth looking back at the class to see how much work it is
doing. It may be taking more responsibilities than it should. But remember, we are dealing with legacy code and improving 
legacy code overnight is not the easiest thing to do. Have a look at the test classes in the code for getting an idea on 
how to spy / partial mock classes. 

[EasyMock]: http://www.easymock.org/EasyMock2_2_2_ClassExtension_Documentation.html
[Unitils]: http://www.unitils.org/

ThinAir dependencies as I like to call them are the dependencies grabbed out of thin air in a constructor/method call 
usually by creating a new instance of a collaborator class. These again are hard to mock and hence hard to test. We use
parameterize constructor/adapt parameter refactoring to break these dependencies. If you come across code like the following,
you know you have this kind of problem:
{% highlight java %}
	void m1() {
		...
		TweetDownloader = new TweetDownloader(); // thin air dependency
		...
	}

	void m2() {
		...
		List<Tweet> tweets = TweetDownloader.downloadTweets(); // static dependency
		...
	}
{% endhighlight %}
Its like grabbing a dependency out of thin air! Ideal solution would be to inject dependencies, but tests first and then 
more pervasive refactoring is an implied rule in legacy.

Please look at the example code to get an idea of how to use mockito with these kinds of problems. Code below is code 
after refactoring.  
{% highlight java %}
	public class TweetCountService {

		public int countTweetsFrom(String user) {
			TweetDownloader downloader = createTweetDownloader();
			TweetPersister persister = createTweetPersister();
			List<Tweet> tweets = downloader.downloadData();
			int numberOfTweets = 0;
			for (Tweet tweet : tweets) {
				if (tweet.getUser().equals(user)) {
					numberOfTweets++;
				}
			}
			persister.persistTweets(user, numberOfTweets);
			return numberOfTweets;
		}

		protected TweetPersister createTweetPersister() {
			return new TweetPersister();
		}

		protected TweetDownloader createTweetDownloader() {
			return new TweetDownloader();
		}
	}


	public class TweetCountServiceTestThinAir {

		@Test
		public void shouldReturnZeroTweetsForAPersonWithoutAnyTweets() {
			TweetCountService tweetCountService = spy(new TweetCountService());
			TweetDownloader downloader = mock(TweetDownloader.class);
			TweetPersister persister = mock(TweetPersister.class);

			Tweet tweet1 = new Tweet("piyush", "mockito is awesome!");
			Tweet tweet2 = new Tweet("kate", "i love spying with mockito ;)");

			doReturn(downloader).when(tweetCountService).createTweetDownloader();
			doReturn(persister).when(tweetCountService).createTweetPersister();

			when(downloader.downloadData()).thenReturn(asList(tweet1, tweet2));

			int numberOfTweets = tweetCountService.countTweetsFrom("cece");

			assertEquals(0, numberOfTweets);
		}
	}
{% endhighlight %}
This was a very simple approach showing very simple examples of some not so good patterns you find in code. Even when
starting on a green field project, make sure the system evolves in a non legacy manner. Write tests, follow TDD and see
the results. Code evolves a lot better!

Enjoy!

