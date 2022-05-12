#!/bin/bash
# Copyright (c) 2011-present Sonatype, Inc. All rights reserved.
# Includes the third-party code listed at http://links.sonatype.com/products/clm/attributions.
# "Sonatype" is a trademark of Sonatype, Inc.

projectUrl=""
username=${username:-admin}
password=${password:-admin123}
serverUrl=${serverUrl:-"http://192.168.0.1:8070"}
stage=${stage:-build}
applicationId="Sandbox Application"

while [ $# -gt 0 ]; do
   if [[ $1 == *"-"* ]]; then
        param="${1/-/}"
        declare $param="$2"
   fi
  shift
done

if [ -z "$projectUrl" ]
then
  echo "You must specify the repository url for the scala project to be evaluated"
  exit 0
fi

current_dir=$(pwd)
tmp_dir=$(mktemp -d -t iq-XXXXXXXXXX)
checkout_dir="scala_app"
echo "cloning project $projectUrl"
cd "$tmp_dir"
echo "evaluating nexus-iq-sbt in $tmp_dir"
git clone "$projectUrl" $checkout_dir

cd "$checkout_dir"
sbt_file=build.sbt
if [ -f "$sbt_file" ];
then
  sbt makePom
  pomresult=(`find ./target -maxdepth 2 -name "*.pom"`)
  if [ ${#pomresult[@]} -gt 0 ];
  then
    pom_file=${pomresult[0]}
    echo "generated pom file from sbt $pom_file"
    cp $pom_file ./pom.xml
    mvn com.sonatype.clm:clm-maven-plugin:2.30.6-01:evaluate -Dclm.serverUrl="$serverUrl" -Dclm.username=$username -Dclm.password="$password" -Dclm.applicationId="$applicationId" -Dclm.stage=$stage
  else
    echo "could not retrieve the generated pom"
  fi
else
  echo "$sbt_file does not exist."
fi
cd $current_dir
rm -rf $tmp_dir
