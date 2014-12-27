---
layout: post
title: "My Blog With Docker and Octopress"
date: 2014-12-26 20:17:29 -0600
comments: true
categories: 
---

This is a blog about how I setup this blog to run with [Octopress][Octopress] and [Docker][Docker]. How meta!

One of my fun projects for the Christmas week this year was migrating my blog away from [Github Pages][GH] and host it on my own. I chose Docker with Octopress. I wanted an easy way to migrate my existing blog which is entirely based in Jekyll. Octopress seemed to be an obvious choice given my constraints.

Here’s the tech stack that I ended up using:

* Octopress
* Docker
* CoreOS
* nginx
* DigitalOcean
* SnapCI

## Octopress Development Environment

First step was to setup a repeatable development environment where I could setup the blog using Octopress, make changes and get quick feedback. Since I was migrating my old blog to a new one, this was really important for me to check if the migration from old to new was working fine. Since I was ultimately going to host this blog inside a Docker container, I decided to setup a container with all the dependencies installed which I could take all the way to production. This worked out well but I would not recommend taking this approach. I will explain that a bit later in this article. My Docker container is based on an Ubuntu base box in which I am installing libraries required to run Octopress along with a few packages that I would use to serve blog content. 

![vagrant coreos][vagrantcoreos]

[vagrantcoreos]: /images/vagrant-coreos.png

Here’s the [Dockerfile][Dockerfile] for the same. Setting up a container in which I could clone my blog repository (which I forked from [Octopress’ Github repo][OctoGH]) and generate html content using a few `rake` commands proved to be extremely useful. For the development environment I used [Vagrant][Vagrant] to spin up a single node [CoreOS][CoreOS] VM. CoreOS is a very minimalist linux distro which comes pre loaded with Docker. This was pretty smooth, I could get a docker container with octopress setup running on my CoreOS VM in just a couple of hours. After that it was mostly fixing some minor issues in my old blog which were preventing it from migrating to octopress.

        docker run -t -i piyush0101/octopress /bin/bash

This launches the container for a given image with a bash shell. Having a bash shell handy was very helpful in doing small incremental changes to the container and making sure everything was running fine. For example, after building the container with my octopress blog setup, I wanted to check if it compiled fine with `rake generate`. Having a command prompt to get that kind of feedback and make corrections was really helpul. My feedback cycle looked like `docker build > container /bin/bash > test > repeat`. I found it to be a good enough feedback loop for a docker beginner.

## Build Pipeline

My blog is a fork of the original Github repo for octopress. As with other systems I have worked in the past, I wanted a good build pipeline infrastructure for my blog. Something that is lightweight and still achieves the purpose. Stages that I needed in my pipeline are:

* `rake generate` which compiles the markdown source and generates html files. Basically it generates a public folder with static content which can be served over http. Throws exceptions if there are errors during compilation.
* Build a docker container with the latest blog changes.
* Push docker container to dockerhub.
* Deploy the container on my hosting site.


![blog pipeline][pipeline]

[pipeline]: /images/blog-pipeline.png

I used [SnapCI][SnapCI] to configure the pipeline. Some of the pain points that I faced was SnapCI's lack of support for running docker builds. Luckily you can setup an [Automated Build][AutomatedBuild] repository at [Dockerhub][Dockerhub] on which builds can be triggered using a trigger URL. As of now I am just triggering a build from Snap with [curl][curl]. 

        curl --data "build=true" -X POST https://registry.hub.docker.com/u/piyush0101/octopress/trigger/token

Problem with this is that this trigger is asynchronous. Trigger and Forget. I need to keep monitoring the build status on Dockerhub to see the status of the build. There is no status endpoint on Dockerhub which I can poll to get the status of the current build. Perhaps an endpoint that could return a json blob showing the status of a build would be useful. I can then hack a bash/python script to poll it every few seconds. Pipeline stage which triggers the Docker build finishes off in just a few seconds if the trigger alone is successful which is not enough to achieve a completely automated solution. I have also been thinking of perhaps executing a build over http and streaming the console output of the build to the client over a websocket. Client (SnapCI) should not return until the build finishes. This means that the Pipeline Stage which builds the docker container does not finish until the docker build finishes. This is exactly what I need.

Well, instead of going in that complicated direction, I just ran a few commands over ssh from SnapCI for running docker builds. Docker builds are running on a DigitalOcean CoreOS droplet.

        ssh -i my_private_key user@host.com rm -Rf octopress
        ssh -i my_private_key user@host.com git clone https://github.com/piyush0101/octopress
        ssh -i my_private_key user@host.com 'cd octopress && sudo docker build piyush0101/octopress .'


## Hosting

I have a CoreOS droplet on DigitalOcean on which I am running a Docker container to publish my blog. This is the same container that was built by a trigger from SnapCI. That’s the beauty of containers. I can take the same container and run it anywhere else. Right now, my container is a little fat since am using the same container that I built for the development environment. That means that the container has ruby and all the libraries (rake, bundle, pygments, jekyll) installed within. For serving blog content alone, they are not required. I can just create a container which has the `public` folder generated by `rake` and serve it with [nginx][nginx]. I am still serving it with nginx but all the bulk that I have right now is not required. If I can run a docker build on SnapCI and copy the artifacts (public folder) from `rake generate`, it would be trivial. It is a bit tricky without it.

After the build finishes on docker hub, I pull the latest repository from docker hub, kill the old container and start again. Quite straight forward.

        docker pull piyush0101/octopress:latest
        docker run -d -p 80:80 piyush0101/octopress /etc/init.d/nginx start

Setting up nginx to serve static blog content was also trivial. Perhaps I will explain that in another blog post.

[Docker]: https://www.docker.com/
[Octopress]: http://octopress.org/docs/setup/
[OctoGH]: https://github.com/imathis/octopress
[nginx]: http://nginx.org/en/
[GH]: https://pages.github.com/
[Dockerfile]: https://github.com/piyush0101/octopress/blob/master/Dockerfile
[Vagrant]: https://www.vagrantup.com/
[CoreOS]: https://coreos.com/
[SnapCI]: https://snap-ci.com/
[AutomatedBuild]: http://docs.docker.com/docker-hub/builds/
[curl]: http://curl.haxx.se/
[Dockerhub]: https://hub.docker.com
