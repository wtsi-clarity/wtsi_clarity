#!/bin/bash

if [ "$TRAVIS_PULL_REQUEST" = false ] ; then
    exit 0
fi

git clone --branch=gh-pages git://github.com/wtsi-clarity/wtsi_clarity.git /var/tmp/wtsi_clarity
cp -r ./src/perl/cover_db /var/tmp/wtsi_clarity/results/$TRAVIS_COMMIT

cd /var/tmp/wtsi_clarity

mv index.html index_tmp.html
touch index_new

GH_REPO="@github.com/wtsi-clarity/wtsi_clarity.git"
FULL_REPO="https://$GH_TOKEN$GH_REPO"

DATE=$(date +%Y-%m-%d:%H:%M:%S)
BASE='https://github.com/wtsi-clarity/wtsi_clarity'

PULL_REQUEST_LINE="<p><a href='$BASE/pulls/$TRAVIS_PULL_REQUEST'>Pull Request $TRAVIS_PULL_REQUEST</a></p>"
COMMIT_LINE="<p><a href='$BASE/commit/$TRAVIS_COMMIT'>Commit $TRAVIS_COMMIT</a> - $DATE - <a href='results/$TRAVIS_COMMIT/coverage.html'>Results</a></p>"

echo $PULL_REQUEST_LINE >> index_new
echo $COMMIT_LINE >> index_new
echo '<br />' >> index_new

cat index_new index_tmp.html > index.html

rm /var/tmp/wtsi_clarity/index_new
rm /var/tmp/wtsi_clarity/index_tmp.html

git add .
git commit -m "deployed coverage for commit $TRAVIS_COMMIT"

git push --force $FULL_REPO gh-pages