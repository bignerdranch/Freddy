#!/bin/bash
# 
# Bootstraps Carthage to validate that everything builds as expected.
# thanks to abbeycode/UnzipKit for example 
#

EXIT_CODE=0

clone_project() {
  local BRANCH_NAME BUILD_DIR
  if [[ $CIRCLECI ]]; then
    BRANCH_NAME=$CIRCLE_BRANCH
    BUILD_DIR=$(pwd)
  elif [[ $TRAVIS ]]; then
    BRANCH_NAME=$TRAVIS_BRANCH
    BUILD_DIR=$TRAVIS_BUILD_DIR
  else
    BUILD_DIR="$HOME/workspace/CoreDataStack"
    BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)
    echo "=================Not Running in CI================="
  fi

  echo "=================Creating Cartfile================="
  echo "git \"$BUILD_DIR\" \"$BRANCH_NAME\"" > ./Cartfile
}

bootstrap() {
  echo "=================Bootstrapping Carthage================="
  carthage bootstrap --configuration Debug
  EXIT_CODE=$?
}

validate() {
  echo "=================Checking for build products================="

  if [ ! -d "Carthage/Build/iOS/CoreDataStack.framework" ]; then
    echo "=================iOS Library failed to build with Carthage================="
    EXIT_CODE=1
  fi

  if [ ! -d "Carthage/Build/tvOS/CoreDataStack.framework" ]; then
    echo "=================iOS Library failed to build with Carthage================="
    EXIT_CODE=1
  fi
}

clean_up() {
  echo "=================Cleaning Up================="
  rm ./Cartfile
  rm ./Cartfile.resolved
  rm -rf ./Carthage
}

clone_project
bootstrap
validate
clean_up
exit $EXIT_CODE
