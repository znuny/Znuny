#!/bin/sh
# --
# auto_build.sh - build automatically OTRS tar, rpm and src-rpm
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021 Znuny GmbH, https://znuny.org/
# --
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

echo "auto_build.sh - build OTRS release files"
echo "Copyright (C) 2001-2021 OTRS AG, https://otrs.com/";
echo "Copyright (C) 2012-2021 Znuny GmbH, https://znuny.com/";

PATH_TO_CVS_SRC=$1
PRODUCT="Znuny"
VERSION=$2
MAJOR_VERSION="$(echo "$VERSION" | cut -d. -f1)"
MINOR_VERSION="$(echo "$VERSION" | cut -d. -f2)"
LATEST_VERSION=false
RELEASE=$3
ARCHIVE_DIR="znuny-$VERSION"
PACKAGE=znuny
PACKAGE_BUILD_DIR="${CI_PROJECT_DIR}/../$PACKAGE-build"
PACKAGE_DEST_DIR="${CI_PROJECT_DIR}/../$PACKAGE-buildpackages"
PACKAGE_TMP_SPEC="${CI_PROJECT_DIR}/../$PACKAGE.spec"
RPM_BUILD="rpmbuild"



if ! test $PATH_TO_CVS_SRC || ! test $VERSION || ! test $RELEASE; then
    # --
    # build src needed
    # --
    echo ""
    echo "Usage: auto_build.sh <PATH_TO_CVS_SRC> <VERSION> <BUILD>"
    echo ""
    echo "  Try: auto_build.sh /home/ernie/src/otrs 3.1.0.beta1 01"
    echo ""
    exit 1;
else
    # --
    # check dir
    # --
    if ! test -e $PATH_TO_CVS_SRC/RELEASE; then
        echo "Error: $PATH_TO_CVS_SRC is not OTRS CVS directory!"
        exit 1;
    fi
fi


SYSTEM_RPM_DIR="${CI_PROJECT_DIR}/../rpmbuild/RPMS"
SYSTEM_SRPM_DIR="${CI_PROJECT_DIR}/../rpmbuild/SRPMS"
SYSTEM_SOURCE_DIR="${CI_PROJECT_DIR}/../rpmbuild/SOURCES"

mkdir -p "$SYSTEM_RPM_DIR" "$SYSTEM_SRPM_DIR" "$SYSTEM_SOURCE_DIR"
mkdir -p "${CI_PROJECT_DIR}"/../rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}

# --
# cleanup system dirs
# --
rm -rf $SYSTEM_RPM_DIR/*/$PACKAGE*$VERSION*$RELEASE*.rpm
rm -rf $SYSTEM_SRPM_DIR/$PACKAGE*$VERSION*$RELEASE*.src.rpm

# --
# RPM and SRPM dir
# --
rm -rf $PACKAGE_DEST_DIR
mkdir $PACKAGE_DEST_DIR

# --
# build
# --
rm -rf $PACKAGE_BUILD_DIR || exit 1;
mkdir -p $PACKAGE_BUILD_DIR/$ARCHIVE_DIR/ || exit 1;

cp -a $PATH_TO_CVS_SRC/.*rc.dist $PACKAGE_BUILD_DIR/$ARCHIVE_DIR/ || exit 1;
cp -a $PATH_TO_CVS_SRC/.mailfilter.dist $PACKAGE_BUILD_DIR/$ARCHIVE_DIR/ || exit 1;
cp -a $PATH_TO_CVS_SRC/.bash_completion $PACKAGE_BUILD_DIR/$ARCHIVE_DIR/ || exit 1;
cp -a $PATH_TO_CVS_SRC/* $PACKAGE_BUILD_DIR/$ARCHIVE_DIR/ || exit 1;

# --
# update RELEASE
# --
COMMIT_ID=$( cd $(dirname "$0")/../..; git rev-parse HEAD)
if ! test $COMMIT_ID
then
    echo "Error: could not determine git commit id."
    exit 1
fi

RELEASEFILE=$PACKAGE_BUILD_DIR/$ARCHIVE_DIR/RELEASE
echo "PRODUCT = $PRODUCT" > $RELEASEFILE
echo "VERSION = $VERSION" >> $RELEASEFILE
echo "BUILDDATE = `date`" >> $RELEASEFILE
echo "BUILDHOST = $CI_RUNNER_DESCRIPTION" >> $RELEASEFILE
echo "COMMIT_ID = $COMMIT_ID" >> $RELEASEFILE

# --
# cleanup
# --
cd $PACKAGE_BUILD_DIR/$ARCHIVE_DIR/ || exit 1;

# remove old sessions, articles and spool and other stuff
# (remainders of a running system, should not really happen)
rm -rf .gitignore var/sessions/* var/article/* var/spool/* Kernel/Config.pm
# remove development content
rm -rf development
# remove swap/temp stuff
find -name ".#*" | xargs rm -rf
find -name ".keep" | xargs rm -f

# mk ARCHIVE
bin/otrs.CheckSum.pl -a create
# Create needed directories
mkdir -p var/tmp var/article var/log

function CreateArchive() {
    SUFFIX=$1
    COMMANDLINE=$2

    cd $PACKAGE_BUILD_DIR/ || exit 1;
    SOURCE_LOCATION=$SYSTEM_SOURCE_DIR/$PACKAGE-$VERSION.$SUFFIX
    test -f "$SOURCE_LOCATION" && rm -f "$SOURCE_LOCATION"
    echo "Building $SOURCE_LOCATION..."
    $COMMANDLINE $SOURCE_LOCATION $ARCHIVE_DIR/ > /dev/null || exit 1;
    cp $SOURCE_LOCATION $PACKAGE_DEST_DIR/
}

CreateArchive "tar.gz"  "tar -czf"
CreateArchive "tar.bz2" "tar -cjf"
CreateArchive "zip"     "zip -r"

# --
# create rpm spec files
# --
DESCRIPTION=$PATH_TO_CVS_SRC/scripts/auto_build/description.txt
FILES=$PATH_TO_CVS_SRC/scripts/auto_build/files.txt

function CreateRPM() {
    DistroName=$1
    SpecfileName=$2
    TargetPath=$3

    echo "Building $DistroName rpm..."

    specfile=$PACKAGE_TMP_SPEC
    # replace version and release
    cat $ARCHIVE_DIR/scripts/auto_build/spec/$SpecfileName | sed "s/^Version:.*/Version:      $VERSION/" | sed "s/^Release:.*/Release:      $RELEASE/" > $specfile
    $RPM_BUILD --define "_topdir ${CI_PROJECT_DIR}/../rpmbuild/" -ba --clean $specfile || exit 1;
    rm $specfile || exit 1;

    mkdir -p $PACKAGE_DEST_DIR/RPMS/$TargetPath
    mv $SYSTEM_RPM_DIR/*/$PACKAGE*$VERSION*$RELEASE*.rpm $PACKAGE_DEST_DIR/RPMS/$TargetPath
    mkdir -p $PACKAGE_DEST_DIR/SRPMS/$TargetPath
    mv $SYSTEM_SRPM_DIR/$PACKAGE*$VERSION*$RELEASE*.src.rpm $PACKAGE_DEST_DIR/SRPMS/$TargetPath
}

CreateRPM "RHEL 7"    "rhel7-otrs.spec"    "rhel/7"
CreateRPM "SuSE 12"   "suse12-otrs.spec"   "suse/12/"
CreateRPM "SuSE 13"   "suse13-otrs.spec"   "suse/13/"
CreateRPM "Fedora 25" "fedora25-otrs.spec" "fedora/25/"
CreateRPM "Fedora 26" "fedora26-otrs.spec" "fedora/26/"

echo "-----------------------------------------------------------------";
echo "You will find your tar.gz, RPMs and SRPMs in $PACKAGE_DEST_DIR";
cd "$PACKAGE_DEST_DIR"
find . -name "*$PACKAGE*" | xargs ls -lo
echo "-----------------------------------------------------------------";
if which md5sum >> /dev/null; then
    echo "MD5 message digest (128-bit) checksums and download URLs in markdown table format";
    echo "| Typ / URL| MD5 Summe |
| ---- | ------- |"
    for p in $(find . -name "*$PACKAGE*")
    do
        md5_complete="$(md5sum "$p"| sed -e "s/\.\//https:\/\/download.znuny.org\/releases\//" )"
        md5=$(echo "$md5_complete" | awk {'print $1'})
        url=$(echo "$md5_complete" | awk {'print $NF'})
        label="Unknown"
        echo "$url" | grep -q ".gz" && label="Source .tar.gz"
        echo "$url" | grep -q ".bz2" && label="Source .bz2"
        echo "$url" | grep -q ".zip" && label="Source .zip"
        echo "$url" | grep -q "/RPMS/rhel/7" && label="RPM RHEL 7 / CentOS 7"
        echo "$url" | grep -q "/RPMS/suse/12/" && label="RPM SuSE 12"
        echo "$url" | grep -q "/RPMS/suse/13/" && label="RPM SuSE 13 "
        echo "$url" | grep -q "/RPMS/fedora/25/" && label="RPM Fedora 25 "
        echo "$url" | grep -q "/RPMS/fedora/26/" && label="RPM Fedora 26 "
        echo "$url" | grep -q "/SRPMS/rhel/7" && label="SRPM RHEL 7 / CentOS 7"
        echo "$url" | grep -q "/SRPMS/suse/12/" && label="SRPM SuSE 12"
        echo "$url" | grep -q "/SRPMS/suse/13/" && label="SRPM SuSE 13 "
        echo "$url" | grep -q "/SRPMS/fedora/25/" && label="SRPM Fedora 25 "
        echo "$url" | grep -q "/SRPMS/fedora/26/" && label="SRPM Fedora 26 "

        echo "| [$label]($url) | $md5 |"
    done
else
    echo "No md5sum found in \$PATH!"
fi
prerelease=$(echo "$VERSION" | egrep -e '[a-zA-Z]')
if [ -z "$prerelease" ]; then 
    ln -s $PACKAGE-$VERSION.tar.gz $PACKAGE-$MAJOR_VERSION.$MINOR_VERSION.tar.gz
    ln -s $PACKAGE-$VERSION.tar.gz $PACKAGE-latest-$MAJOR_VERSION.$MINOR_VERSION.tar.gz
    if [ $LATEST_VERSION  = "true" ]; then
        ln -s $PACKAGE-$VERSION.tar.gz $PACKAGE-latest.tar.gz
    fi
fi
echo "--------------------------------------------------------------------------";
echo "Note: You may have to tag your git tree: git tag rel-6_x_x -a -m \"6.x.x\"";
echo "--------------------------------------------------------------------------";

# --
# cleanup
# --
rm -rf $PACKAGE_BUILD_DIR
rm -rf $PACKAGE_TMP_SPEC
