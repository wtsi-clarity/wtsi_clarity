#!/bin/bash

set -ev

if [ "$TRAVIS_PULL_REQUEST" = false ] ; then
  echo 'Not a Pull Request. No need to upload test coverage artifacts.'
  exit 0
fi

$TRAVIS_BUILD_DIR/src/perl/Build testcover

git clone --branch=gh-pages git://github.com/wtsi-clarity/wtsi_clarity.git /var/tmp/wtsi_clarity
cp -r $TRAVIS_BUILD_DIR/src/perl/cover_db /var/tmp/wtsi_clarity/results/$TRAVIS_COMMIT

cd /var/tmp/wtsi_clarity

mv index.html index_tmp.html
touch index_new

GH_REPO="@github.com/wtsi-clarity/wtsi_clarity.git"
FULL_REPO="https://$GH_TOKEN$GH_REPO"

DATE=$(date +%Y-%m-%d %H:%M:%S)
BASE='https://github.com/wtsi-clarity/wtsi_clarity'

PULL_REQUEST_LINE="<p>Pull Request <a href='$BASE/pull/$TRAVIS_PULL_REQUEST'>$TRAVIS_PULL_REQUEST</a></p>"
COMMIT_LINE="<p>Commit <a href='$BASE/commit/$TRAVIS_COMMIT'>$TRAVIS_COMMIT</a> - $DATE - <a href='results/$TRAVIS_COMMIT/coverage.html'>Results</a></p>"

echo $PULL_REQUEST_LINE >> index_new
echo $COMMIT_LINE >> index_new
echo '<br />' >> index_new

cat index_new index_tmp.html > index.html

rm /var/tmp/wtsi_clarity/index_new
rm /var/tmp/wtsi_clarity/index_tmp.html

git config user.name "wtsi_clarity-travis"
git config user.email "travis"

git add .
git commit -m "deployed coverage for commit $TRAVIS_COMMIT"

git push --force $FULL_REPO gh-pages