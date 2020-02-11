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

## Contributors

### Code Contributors

This project exists thanks to all the people who contribute. [[Contribute](CONTRIBUTING.md)].
<a href="https://github.com/regolith-linux/regolith-desktop/graphs/contributors"><img src="https://opencollective.com/regolith/contributors.svg?width=890&button=false" /></a>

### Financial Contributors

Become a financial contributor and help us sustain our community. [[Contribute](https://opencollective.com/regolith/contribute)]

#### Individuals

<a href="https://opencollective.com/regolith"><img src="https://opencollective.com/regolith/individuals.svg?width=890"></a>

#### Organizations

Support this project with your organization. Your logo will show up here with a link to your website. [[Contribute](https://opencollective.com/regolith/contribute)]

<a href="https://opencollective.com/regolith/organization/0/website"><img src="https://opencollective.com/regolith/organization/0/avatar.svg"></a>
<a href="https://opencollective.com/regolith/organization/1/website"><img src="https://opencollective.com/regolith/organization/1/avatar.svg"></a>
<a href="https://opencollective.com/regolith/organization/2/website"><img src="https://opencollective.com/regolith/organization/2/avatar.svg"></a>
<a href="https://opencollective.com/regolith/organization/3/website"><img src="https://opencollective.com/regolith/organization/3/avatar.svg"></a>
<a href="https://opencollective.com/regolith/organization/4/website"><img src="https://opencollective.com/regolith/organization/4/avatar.svg"></a>
<a href="https://opencollective.com/regolith/organization/5/website"><img src="https://opencollective.com/regolith/organization/5/avatar.svg"></a>
<a href="https://opencollective.com/regolith/organization/6/website"><img src="https://opencollective.com/regolith/organization/6/avatar.svg"></a>
<a href="https://opencollective.com/regolith/organization/7/website"><img src="https://opencollective.com/regolith/organization/7/avatar.svg"></a>
<a href="https://opencollective.com/regolith/organization/8/website"><img src="https://opencollective.com/regolith/organization/8/avatar.svg"></a>
<a href="https://opencollective.com/regolith/organization/9/website"><img src="https://opencollective.com/regolith/organization/9/avatar.svg"></a>
