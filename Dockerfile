# Clean-room Linux environment for running binstubs. See bin/in-docker.
ARG RUBY_VERSION=4.0
FROM ruby:${RUBY_VERSION}-slim

RUN apt-get update -qq && \
    apt-get install -yqq --no-install-recommends \
      build-essential git libyaml-dev pkg-config \
      libvips-tools imagemagick libheif1 libheif-plugin-x265 libheif-plugin-aomenc libopenjp2-7 && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Gemfile.lock is deliberately not copied (see .dockerignore): it is resolved for
# the host's Ruby and would not install on older Rubies.
COPY Gemfile derived_images.gemspec ./
COPY lib/derived_images/version.rb lib/derived_images/version.rb
RUN bundle install

COPY . .
