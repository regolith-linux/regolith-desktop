#!/bin/bash
# This script can be used to generate Debian packages of Regolith in a user-specified PPA.
# By doing this, anyone can create their own variants of the DE and/or distro.

# Input Parameters
if [ "$#" -ne 3 ]; then
    echo "Usage: build.sh <package model> <user PPA> <build dir>"
    exit 1
fi

PACKAGE_MODEL_FILE=$( realpath $1 )
PPA_URL=$2
BUILD_DIR=$3

print_banner() {
    echo "***********************************************************"
    echo "** $1"
    echo "***********************************************************"
}

# Checkout
checkout() {
    repo_url=${packageModel[gitRepoUrl]}
    repo_path=${repo_url##*/}
    repo_name=${repo_path%%.*}
    if [ -d $BUILD_DIR/$repo_name ]; then
        echo "Skipping checkout, $repo_name already exists."
        return 0
    fi

    print_banner "Checking out ${packageModel[gitRepoUrl]}"

    cd $BUILD_DIR
    git clone ${packageModel[gitRepoUrl]} -b ${packageModel[packageBranch]}
    cd -
}

# Package 
package() {
    print_banner "Preparing source for ${packageModel[packageName]}"
    cd $BUILD_DIR/${packageModel[buildPath]}
    debian_version=`dpkg-parsechangelog --show-field Version | cut -d'-' -f1`
    cd $BUILD_DIR

    if [ "${packageModel[upstreamTarball]}" != "" ]; then
        echo "Downloading source from ${packageModel[upstreamTarball]}..."
        wget ${packageModel[upstreamTarball]} -O ${packageModel[buildPath]}/../${packageModel[packageName]}\_$debian_version.orig.tar.gz
    else
        echo "Generating source tarball from git repo."
        tar cfzv ${packageModel[packageName]}\_$debian_version.orig.tar.gz --exclude .git\* --exclude debian ${packageModel[buildPath]}/../${packageModel[packageName]}
    fi
}

# Build
build() {
    print_banner "Building ${packageModel[packageName]}"
    cd $BUILD_DIR/${packageModel[buildPath]}
    debuild -S -sa
    cd $BUILD_DIR
}

# Publish
publish() {
    print_banner "Publishing source package ${packageModel[packageName]}"
    cd $BUILD_DIR/${packageModel[buildPath]}
    version=`dpkg-parsechangelog --show-field Version`
    cd $BUILD_DIR

    dput -f $PPA_URL ${packageModel[buildPath]}/../${packageModel[packageName]}\_$version\_source.changes
}

# Verify execution environment
hash git 2>/dev/null || { echo >&2 "Required command git is not found on this system. Please install it. Aborting."; exit 1; }
hash debuild 2>/dev/null || { echo >&2 "Required command debuild is not found on this system. Please install it. Aborting."; exit 1; }
hash jq 2>/dev/null || { echo >&2 "Required command jq is not found on this system. Please install it. Aborting."; exit 1; }
hash wget 2>/dev/null || { echo >&2 "Required command wget is not found on this system. Please install it. Aborting."; exit 1; }
hash dpkg-parsechangelog 2>/dev/null || { echo >&2 "Required command dpkg-parsechangelog is not found on this system. Please install it. Aborting."; exit 1; }
hash realpath 2>/dev/null || { echo >&2 "Required command realpath is not found on this system. Please install it. Aborting."; exit 1; }

# Main
set -e
if [ ! -d $BUILD_DIR ]; then
    mkdir -p $BUILD_DIR
fi

print_banner "Generating packages in $BUILD_DIR"

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
