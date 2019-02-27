FROM ruby:2.5-slim
LABEL maintainer="Thiago Trentin <trentin@compasso.com.br>"

# INSTALL JAVA
# FROM https://github.com/docker-library/openjdk/blob/c3023e4da10d10e9c9775eabe2d7baac146e7ae1/8/jdk/slim/Dockerfile
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  bzip2 unzip xz-utils \
  && rm -rf /var/lib/apt/lists/*

# Default to UTF-8 file.encoding
ENV LANG C.UTF-8

# add a simple script that can auto-detect the appropriate JAVA_HOME value
# based on whether the JDK or only the JRE is installed
RUN { \
    echo '#!/bin/sh'; \
    echo 'set -e'; \
    echo; \
    echo 'dirname "$(dirname "$(readlink -f "$(which javac || which java)")")"'; \
  } > /usr/local/bin/docker-java-home \
  && chmod +x /usr/local/bin/docker-java-home

# do some fancy footwork to create a JAVA_HOME that's cross-architecture-safe
RUN ln -svT "/usr/lib/jvm/java-8-openjdk-$(dpkg --print-architecture)" /docker-java-home
ENV JAVA_HOME /docker-java-home

ENV JAVA_VERSION 8u181
ENV JAVA_DEBIAN_VERSION 8u181-b13-2~deb9u1

RUN set -ex; \
# deal with slim variants not having man page directories (which causes "update-alternatives" to fail)
  if [ ! -d /usr/share/man/man1 ]; then \
    mkdir -p /usr/share/man/man1; \
  fi; \
  apt-get update; \
  apt-get install -y --no-install-recommends \
    openjdk-8-jdk-headless="$JAVA_DEBIAN_VERSION" \
  ; \
  rm -rf /var/lib/apt/lists/*; \
# verify that "docker-java-home" returns what we expect
  [ "$(readlink -f "$JAVA_HOME")" = "$(docker-java-home)" ]; \
# update-alternatives so that future installs of other OpenJDK versions don't change /usr/bin/java
  update-alternatives --get-selections | awk -v home="$(readlink -f "$JAVA_HOME")" 'index($3, home) == 1 { $2 = "manual"; print | "update-alternatives --set-selections" }'; \
# ... and verify that it actually worked for one of the alternatives we care about
  update-alternatives --query java | grep -q 'Status: manual'

# Enviroment variables
ENV ORACLE_HOME=/usr/lib/oracle/18.3/client64
ENV LD_LIBRARY_PATH=/usr/lib/oracle/18.3/client64/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}

# JENKINS CONFIGURATION
# Enviroment variables
RUN export JAVA_HOME
ARG JENKINS_AGENT_HOME=/root/jenkins
ENV JENKINS_AGENT_HOME ${JENKINS_AGENT_HOME}
VOLUME "${JENKINS_AGENT_HOME}" "/tmp" "/run" "/var/run"
WORKDIR "${JENKINS_AGENT_HOME}"
ENV GEM_HOME="/usr/local/bundle"
ENV PATH=$GEM_HOME/bin:$GEM_HOME/gems/bin:$PATH
