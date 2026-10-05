# Clean-room Linux environment for running binstubs. See bin/in-docker.
ARG RUBY_VERSION=4.0
FROM ruby:${RUBY_VERSION}-slim

RUN . /etc/os-release && \
    # Rubies old enough to be on EOL Debian (bullseye and earlier) have lost their mirror packages.
    if [ "$VERSION_CODENAME" = bullseye ] || [ "$VERSION_CODENAME" = buster ]; then \
      sed -i -e 's|deb.debian.org|archive.debian.org|' -e '/-updates/d' /etc/apt/sources.list; \
      echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99archive; \
    fi && \
    apt-get update -qq && \
    apt-get install -yqq --no-install-recommends \
      build-essential git libyaml-dev pkg-config \
      libvips-tools imagemagick libheif1 libopenjp2-7 && \
    # Debian 13+ splits the HEIC/AVIF encoders into plugins; older releases bundle them.
    if apt-cache show libheif-plugin-x265 > /dev/null 2>&1; then \
      apt-get install -yqq --no-install-recommends libheif-plugin-x265 libheif-plugin-aomenc; \
    fi && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Gemfile.lock is deliberately not copied (see .dockerignore): it is resolved for
# the host's Ruby and may not install on other Rubies.
# Kept as an ENV so the Gemfile resolves identically at build time and when running the tests.
ARG RAILS_VERSION=
ENV RAILS_VERSION=${RAILS_VERSION}
COPY Gemfile derived_images.gemspec ./
COPY lib/derived_images/version.rb lib/derived_images/version.rb
RUN bundle install

COPY . .
