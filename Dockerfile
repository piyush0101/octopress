FROM ubuntu
RUN apt-get update
RUN apt-get install -y --force-yes git curl build-essential
RUN apt-get install -y --force-yes zlib1g-dev libssl-dev libreadline-dev libyaml-dev libxml2-dev libxslt-dev
RUN apt-get install nodejs python nginx -y --force-yes
RUN apt-get clean

# Install rbenv and ruby-build
RUN git clone https://github.com/sstephenson/rbenv.git /root/.rbenv
RUN git clone https://github.com/sstephenson/ruby-build.git /root/.rbenv/plugins/ruby-build
RUN ./root/.rbenv/plugins/ruby-build/install.sh
ENV PATH /root/.rbenv/bin:$PATH
RUN echo 'eval "$(rbenv init -)"' >> /etc/profile.d/rbenv.sh # or /etc/profile
RUN echo 'eval "$(rbenv init -)"' >> .bashrc

# Install ruby
ENV CONFIGURE_OPTS --disable-install-doc
RUN rbenv install 1.9.3-p392
ENV PATH /root/.rbenv/versions/1.9.3-p392/bin/:$PATH

# Install Bundler
RUN echo 'gem: --no-rdoc --no-ri' >> /.gemrc
RUN bash -l -c 'rbenv global 1.9.3-p392; gem install bundler;'

# Clone blog repository
RUN git clone https://github.com/piyush0101/octopress

# Initial setup
WORKDIR ./octopress
RUN bundle install
RUN rake generate

# Copy nginx configuration
RUN /etc/init.d/nginx stop
COPY config/nginx.conf /etc/nginx/sites-available/default

# Copy generated files to /var/www/
RUN mkdir -p /var/www/blog/public
RUN cp -R public/* /var/www/blog/public/
