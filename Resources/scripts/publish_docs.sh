#!/bin/bash

if [ "$TRAVIS_PULL_REQUEST" == "false" ] && [ "$TRAVIS_BRANCH" == "master" ]; then
    echo -e "Generating Jazzy output \n"
    jazzy --swift-version 3.0 -m Freddy -g "https://github.com/bignerdranch/Freddy" -a "Big Nerd Ranch" -u "https://github.com/bignerdranch" --module-version=3.0.0 -r "http://bignerdranch.github.io/Freddy/"

    echo -e "Moving into docs directory \n"
    pushd docs

    echo -e "Creating gh-pages repo \n"
    git init
    git config user.email "travis@travis-ci.org"
    git config user.name "travis-ci"

    echo -e "Adding new docs \n"
    git add -A
    git commit -m "Publish docs from successful Travis build of $TRAVIS_COMMIT"
    git push --force --quiet "https://${GITHUB_ACCESS_TOKEN}@github.com/bignerdranch/Freddy" master:gh-pages > /dev/null 2>&1
    echo -e "Published latest docs.\n"

    echo -e "Moving out of docs clone and cleaning up"
    popd
fi
