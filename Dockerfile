#
# Copyright (c) 2011-present Sonatype, Inc. All rights reserved.
# Includes the third-party code listed at http://links.sonatype.com/products/clm/attributions.
# "Sonatype" is a trademark of Sonatype, Inc.
#

ARG OPENJDK_TAG=11.0.13
FROM openjdk:${OPENJDK_TAG}

ARG SBT_VERSION=1.6.2
ARG MAVEN_VERSION=3.6.3
ARG MAVEN_URL=https://apache.osuosl.org/maven/maven-3/${MAVEN_VERSION}/binaries

# prevent this error: java.lang.IllegalStateException: cannot run sbt from root directory without -Dsbt.rootdir=true; see sbt/sbt#1458
WORKDIR /app

# Install sbt
RUN \
  mkdir /working/ && \
  cd /working/ && \
  curl -L -o sbt-$SBT_VERSION.deb https://repo.scala-sbt.org/scalasbt/debian/sbt-$SBT_VERSION.deb && \
  dpkg -i sbt-$SBT_VERSION.deb && \
  rm sbt-$SBT_VERSION.deb && \
  apt-get update && \
  apt-get install sbt && \
  cd && \
  rm -r /working/ && \
  sbt sbtVersion

# Install git
RUN \
  apt-get install git && \
  git --version

#install mvn
RUN mkdir -p /usr/share/maven /usr/share/maven/ref \
 && curl -fsSL -o /tmp/apache-maven.tar.gz ${MAVEN_URL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
 && tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1 \
 && rm -f /tmp/apache-maven.tar.gz \
 && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

ENV MAVEN_HOME /usr/share/maven
ENV MAVEN_CONFIG "$USER_HOME_DIR/.m2"
RUN mvn --version
#install clm-maven-plugin
RUN mvn org.apache.maven.plugins:maven-dependency-plugin:3.3.0:get -DartifactId=clm-maven-plugin -DgroupId=com.sonatype.clm -Dversion=2.30.6-01

COPY ./nexus-iq-sbt.sh /app/nexus-iq-sbt.sh
RUN chmod +x nexus-iq-sbt.sh

CMD ["mvn", "--version"]
