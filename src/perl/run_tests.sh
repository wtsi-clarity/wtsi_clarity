#! /bin/bash

set -ev

cd $TRAVIS_BUILD_DIR
perl Build.PL

if [ "$TRAVIS_PULL_REQUEST" = false ] ; then
  ./Build test
else
  ./Build testcover
fi