#!/bin/bash
# This script can be used to generate Debian packages of Regolith in a user-specified PPA.
# By doing this, anyone can create their own variants of the DE and/or distro.

set -e

# Input Parameters
PPA_URL=$1
BUILD_DIR=$2

if [ "$PPA_URL" == "" ]; then
    echo "Usage: build.sh <user PPA> <build dir>"
    echo "Must specify a PPA."
    exit 1
fi

if [ "$BUILD_DIR" == "" ]; then
    echo "Usage: build.sh <user PPA> <build dir>"
    echo "Must specify a build dir."
    exit 1
fi

# Repositories
# package name | upstream source URL | debian branch
repos=( 
    "regolith-i3-gaps-config||master" 
    "regolith-styles||master"
    "regolith-st|https://dl.suckless.org/st/st-0.8.2.tar.gz|debian"
    "regolith-i3xrocks-config||master"
    "regolith-gnome-flashback||master"
    "regolith-desktop||debian"
    "regolith-gdm3-theme||master"
    "regolith-conky-config||master"
    "regolith-xeventbind||master"
    "regolith-assets||master"
    "regolith-rofi-config||master"
    "regolith-compton-config||master"
    )
base_url="https://github.com/regolith-linux/"

# Checkout
function checkout {
    REPO="$base_url$repo.git"

    echo "Checking out $REPO"

    git clone $REPO -b $pkg_branch
}

# Package 
function package {
    cd $repo
    debian_version=`dpkg-parsechangelog --show-field Version | cut -d'-' -f1`
    cd ..

    if [ "$src_url" != "" ]; then
        echo "Downloading source from $src_url..."
        wget $src_url -O $repo\_$debian_version.orig.tar.gz
    else
        echo "Generating source tarball from git repo."
        tar cfzv $repo\_$debian_version.orig.tar.gz --exclude .git\* --exclude debian $repo
    fi
}

# Build
function build {
    echo "Building $REPO"
    cd $repo
    debuild -S -sa
    cd ..
}

# Publish
function publish {
    echo "Publishing source package $repo"
    cd $repo
    version=`dpkg-parsechangelog --show-field Version`
    cd ..

    dput -f $PPA_URL $repo\_$version\_source.changes
}

# Main
if [ ! -d $BUILD_DIR ]; then
    mkdir -p $BUILD_DIR
fi

cd $BUILD_DIR
echo "Generating Regolith packages in $BUILD_DIR"

for package_desc in "${repos[@]}"
do
    repo=`echo $package_desc | cut -d'|' -f1`
    src_url=`echo $package_desc | cut -d'|' -f2`
    pkg_branch=`echo $package_desc | cut -d'|' -f3`
    echo "Building $repo on branch $pkg_branch from a$src_url\a"

    checkout 
    package 
    build 
    publish 
done
