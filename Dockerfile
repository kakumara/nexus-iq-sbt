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

RUN printf "#!/bin/bash \
    \n# Copyright (c) 2011-present Sonatype, Inc. All rights reserved. \
    \n# Includes the third-party code listed at http://links.sonatype.com/products/clm/attributions. \
    \n# \"Sonatype\" is a trademark of Sonatype, Inc. \
    \nPROJECT_URL=\$1 \
    \nIQ_URL=\$2 \
    \nIQ_APP=\$3 \
    \nIQ_USER=\${4:-admin} \
    \nIQ_PASSWORD=\${5:-admin123} \
    \nIQ_STAGE=\${5:-build} \
    \ncurrent_dir=\$(pwd) \
    \ntmp_dir=\$(mktemp -d -t iq-XXXXXXXXXX) \
    \ncheckout_dir=\"scala_app\" \
    \necho \"cloning project \$PROJECT_URL\" \
    \ncd \$tmp_dir \
    \necho \"evaluating nexus-iq-sbt in \$tmp_dir\" \
    \ngit clone \"\$PROJECT_URL\" \$checkout_dir \
    \ncd \$checkout_dir \
    \nsbt_file=build.sbt \
    \nif [ -f \"\$sbt_file\" ]; then \
          \nsbt makePom \
          \npomresult=(\`find ./target -maxdepth 2 -name \"*.pom\"\`) \
          \nif [ \${#pomresult[@]} -gt 0 ]; then \
              \npom_file=\${pomresult[0]} \
              \necho \"generated pom file from sbt \$pom_file\" \
              \ncp \$pom_file ./pom.xml \
              \nmvn com.sonatype.clm:clm-maven-plugin:evaluate -Dclm.serverUrl=\"\$IQ_URL\" -Dclm.username=\$IQ_USER -Dclm.password=\$IQ_PASSWORD -Dclm.applicationId=\$IQ_APP -Dclm.stage=\$IQ_STAGE \
          \nelse \
              \necho \"could not retrieve the generated pom\" \
          \nfi \
      \nelse \
          \necho \"\$sbt_file does not exist.\" \
    \nfi \
    \ncd \$current_dir \
    \nrm -rf \$tmp_dir" > nexus-iq-sbt.sh

RUN chmod +x nexus-iq-sbt.sh

CMD ["mvn", "--version"]
