#!/bin/bash
# This script can be used to generate Debian packages of Regolith in a user-specified PPA.
# By doing this, anyone can create their own variants of the DE and/or distro.

set -e

# Input Parameters
PACKAGE_MODEL_FILE=$( realpath $1 )
PPA_URL=$2
BUILD_DIR=$3

if [ "$PACKAGE_MODEL_FILE" == "" ]; then
    echo "Usage: build.sh <package model> <user PPA> <build dir>"
    echo "Must specify a package model file."
    exit 1
fi

if [ "$PPA_URL" == "" ]; then
    echo "Usage: build.sh <package model> <user PPA> <build dir>"
    echo "Must specify a PPA."
    exit 1
fi

if [ "$BUILD_DIR" == "" ]; then
    echo "Usage: build.sh <package model> <user PPA> <build dir>"
    echo "Must specify a build dir."
    exit 1
fi

# Checkout
function checkout {
    echo "Checking out ${packageModel[gitRepoUrl]}"

    git clone ${packageModel[gitRepoUrl]} -b ${packageModel[packageBranch]} $BUILD_DIR/${packageModel[packageName]}
}

# Package 
function package {
    cd $BUILD_DIR/${packageModel[packageName]}/${packageModel[buildPath]}
    debian_version=`dpkg-parsechangelog --show-field Version | cut -d'-' -f1`
    cd $BUILD_DIR

    if [ "${packageModel[upstreamTarball]}" != "" ]; then
        echo "Downloading source from ${packageModel[upstreamTarball]}..."
        wget ${packageModel[upstreamTarball]} -O ${packageModel[packageName]}\_$debian_version.orig.tar.gz
    else
        echo "Generating source tarball from git repo."
        tar cfzv ${packageModel[packageName]}\_$debian_version.orig.tar.gz --exclude .git\* --exclude debian ${packageModel[packageName]}
    fi
}

# Build
function build {
    echo "Building ${packageModel[packageName]}"
    cd $BUILD_DIR/${packageModel[packageName]}/${packageModel[buildPath]}
    debuild -S -sa
    cd $BUILD_DIR
}

# Publish
function publish {
    echo "Publishing source package ${packageModel[packageName]}"
    cd $BUILD_DIR/${packageModel[packageName]}/${packageModel[buildPath]}
    version=`dpkg-parsechangelog --show-field Version`
    cd $BUILD_DIR

    echo dput -f $PPA_URL ${packageModel[packageName]}\_$version\_source.changes
}

# Main
if [ ! -d $BUILD_DIR ]; then
    mkdir -p $BUILD_DIR
fi

echo "Generating Regolith packages in $BUILD_DIR"

typeset -A packageModel
cd $BUILD_DIR

cat $PACKAGE_MODEL_FILE | \
jq -rc '.packages[]' | while IFS='' read package; do
    while IFS== read -r key value; do
        packageModel["$key"]="$value"
    done < <( echo $package | jq -r 'to_entries | .[] | .key + "=" + .value')

    checkout 
    package 
    build 
    publish 
done

