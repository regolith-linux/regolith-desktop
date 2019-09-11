# regolith-desktop

This is the meta-package for Regolith Linux that bundles all custom packages into a common root.  The package is just a container, and contains no files or logic itself.

# How to build this package

This guide assumes you wish to make changes to a Regolith package and host those changes in a new version.  It also assumes you'll be building from an Ubuntu-based system like Regolith and you already have setup the Debian package tools.  See [this concise guide](https://wiki.debian.org/BuildingTutorial) to install the tools and get a familiar with the workflow.

## Check out the package

This step will pull the Regolith package metadata down from GitHub.  The debian metadata is on a branch called `debian`, due to conflicts that this README presents to the build tool.

```
mkdir workspace

git clone -b debian https://github.com/regolith-linux/regolith-desktop

```

## Build the package

Now we will build the package locally and generate the Debian package metadata required for hosting in a Private Package Archive (PPA).

```
cd regolith-desktop

debuild -S -sa
```

There should now be a number of files generated in the parent directory, such as `regolith-desktop_2.07-1ubuntu1_source.changes`.

## Bump the package version

It's necessary to update the version of the package so that the local package manager will be able to determine that an update is available.  The Debian packaging tools provide the program `dch` for this task.  `dch` modifies the `debian/changelog` file.  This file contains the package versioning metadata and is organized by stanzas of three elements: version, change info, and author of change.  It's similiar in a way to a git commit log + release tags, but managed in a file rather than the git index.  Run `dch` and update the version string, change UNRELEASED to your intended Ubuntu version target (probably `bionic`) and then below add a description of your change.  The rest should be done automatically by the `dch` program.  Verify that your change follows the pattern of entries below it.

## Upload the package to your PPA

<sub>You may wish to change the package version in the `debian\changelog` file to avoid conflicts, but that is optional and up to you.</sub>

```
dput ppa://<username>/<ppa name> ../regolith-desktop_2.07-1ubuntu1_source.changes
```

## Verification

After uploading the package to your PPA, you should get an email from Launchpad.net regarding if the package was accepted or rejected.  Then, some time later the package should have been build and available for installation.  Assuming you have already added your PPA via `add-apt-repository`, `sudo apt update` and `sudo apt upgrade` should cause the new package to be installed on your local system.

# LiveCD / ISO Release Instructions

1. Install and run Cubic
2. Specify a directory for installation files.
3. Specify Ubuntu ISO for base (currently 19.04).
4. Set versioning info.  Releases beging w/ 'R' followed by major.minor version.  Ex "R1.2".
5. Select Next in the wizard comes the terminal session.
6. Copy whatever login backdrop image needed into the Cubic terminal, and move it to `/usr/share/backgrounds/warty-final-ubuntu.png`
7. Add the Ubuntu "Universe" repo: `add-apt-repository universe`
8. Add the Regolith repo: `add-apt-repository ppa:kgilmer/regolith-stable`
9. Install Regolith: `apt install regolith-desktop`
10. Install the Regolith gdm3 theme: `apt install regolith-gdm3-theme`
11. Go to next, remove libreoffice* and rythmbox* from the Package Manifest
12. In ISO boot configurations, replace "Ubuntu" with "Regolith" on all tabs.
13. Click 'Generate' to make the ISO image.
