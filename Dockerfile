# Clean-room Linux environment for running binstubs. See bin/in-docker.
ARG RUBY_VERSION=4.0
FROM ruby:${RUBY_VERSION}-slim

# Debian 11 (bullseye, used by old Rubies) is end of life and its packages moved to the archive.
RUN if grep -q bullseye /etc/os-release; then \
      sed -i -e 's|deb.debian.org/debian-security|archive.debian.org/debian-security|' \
             -e 's|deb.debian.org/debian|archive.debian.org/debian|' \
             -e '/bullseye-updates/d' /etc/apt/sources.list.d/* /etc/apt/sources.list 2>/dev/null || true; \
    fi && \
    apt-get update -qq && \
    apt-get install -yqq --no-install-recommends \
      build-essential git libyaml-dev pkg-config \
      libvips-tools imagemagick libheif1 libopenjp2-7 && \
    # Newer Debian splits the HEIC/AVIF encoders into plugins; older releases bundle them.
    if apt-cache show libheif-plugin-x265 > /dev/null 2>&1; then \
      apt-get install -yqq --no-install-recommends libheif-plugin-x265 libheif-plugin-aomenc; \
    fi && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Gemfile.lock is deliberately not copied (see .dockerignore): it is resolved for
# the host's Ruby and would not install on older Rubies.
COPY Gemfile derived_images.gemspec ./
COPY lib/derived_images/version.rb lib/derived_images/version.rb
RUN bundle install

COPY . .
