#!/bin/bash
# This script can be used to generate Debian packages of Regolith in a user-specified PPA.
# By doing this, anyone can create their own variants of the DE and/or distro.

# Input Parameters
if [ "$#" -lt 3 ]; then
    echo "This script builds Debian packages.  It uses a package model file that describes each package."
    echo "Each package is checked out of a git repo, source is downloaded, built, and then deployed to a PPA."
    echo "If no package name is specified from the model, all packages are built."
    echo "Usage: build.sh <package model> <user PPA> <build dir> [package]"
    exit 1
fi

PACKAGE_MODEL_FILE=$( realpath $1 )
PPA_URL=$2
BUILD_DIR=$3
PACKAGE=$4

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
        echo "Skipping clone, $repo_name already exists."
        cd $BUILD_DIR/$repo_name
        git pull
        git checkout ${packageModel[packageBranch]}
    else
        print_banner "Checking out ${packageModel[gitRepoUrl]}"

        cd $BUILD_DIR
        git clone ${packageModel[gitRepoUrl]} -b ${packageModel[packageBranch]}
    fi
    cd -
}

# Package 
package() {
    print_banner "Preparing source for ${packageModel[packageName]}"
    cd $BUILD_DIR/${packageModel[buildPath]}
    debian_version=`dpkg-parsechangelog --show-field Version | cut -d'-' -f1`
    full_version=`dpkg-parsechangelog --show-field Version`
    cd $BUILD_DIR

    echo "Checking if ${packageModel[packageName]} $full_version is in the repo..."
    url="https://launchpad.net/~$PPA_USER/+archive/ubuntu/$PPA_NAME/+sourcefiles/${packageModel[packageName]}/$full_version/${packageModel[packageName]}_$full_version.dsc"

    if curl --output /dev/null --silent --head --fail "$url"; then
        echo "** Ignoring ${packageModel[packageName]}-$full_version, already exists in target PPA."
        package_exists="true"    
    else 
        if [ "${packageModel[upstreamTarball]}" != "" ]; then
            echo "Downloading source from ${packageModel[upstreamTarball]}..."
            wget ${packageModel[upstreamTarball]} -O ${packageModel[buildPath]}/../${packageModel[packageName]}\_$debian_version.orig.tar.gz
        else
            echo "Generating source tarball from git repo."
            tar cfzv ${packageModel[packageName]}\_$debian_version.orig.tar.gz --exclude .git\* --exclude debian ${packageModel[buildPath]}/../${packageModel[packageName]}
        fi
        package_exists="false"
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
hash curl 2>/dev/null || { echo >&2 "Required command curl is not found on this system. Please install it. Aborting."; exit 1; }

# Main
set -e
if [ ! -d $BUILD_DIR ]; then
    mkdir -p $BUILD_DIR
fi

TEMP1="$(echo $PPA_URL | cut -d':' -f2)"
PPA_USER="$(echo $TEMP1 | cut -d'/' -f1)"
PPA_NAME="$(echo $TEMP1 | cut -d'/' -f2)"

print_banner "Generating packages in $BUILD_DIR"

typeset -A packageModel
cd $BUILD_DIR

cat $PACKAGE_MODEL_FILE | \
jq -rc '.packages[]' | while IFS='' read package; do
    while IFS== read -r key value; do
        packageModel["$key"]="$value"
    done < <( echo $package | jq -r 'to_entries | .[] | .key + "=" + .value')

    if [[ ! -z "$PACKAGE" && "$PACKAGE" != "${packageModel[packageName]}" ]]; then
        continue
    fi

    checkout
    package_exists="false"
    package
    if [ "$package_exists" == "false" ]; then
      build 
      publish 
    fi
done
