# This script does the following:
#     1. Ensures correct version information in the CMake configuration-file
#        and the texinfo(1) version file;
#     2. Updates the release number.
#     3. Commits to the local repository if appropriate;
#     4. Tags the HEAD revision with the current version; and
#     5. Pushes to the remote repository
#     6. Updates the package version of the previous release.

set -e  # exit upon error

#
# Get the package version information from the CHANGE_LOG file.
#
versionId=`awk '{print $1;exit}' CHANGE_LOG`
majorId=`echo $versionId | cut -d . -f 1`
minorId=`echo $versionId | cut -d . -f 2`
patchId=`echo $versionId | cut -d . -f 3`

test "$majorId"
test "$minorId"
test "$patchId"

#
# Set the package version in the CMake configuration-file.
#
sed "
/^[ \t]*[Ss][Ee][Tt][ \t]*(VERSION_MAJOR[ \t]/cSET(VERSION_MAJOR $majorId)
/^[ \t]*[Ss][Ee][Tt][ \t]*(VERSION_MINOR[ \t]/cSET(VERSION_MINOR $minorId)
/^[ \t]*[Ss][Ee][Tt][ \t]*(VERSION_PATCH[ \t]/cSET(VERSION_PATCH $patchId)" \
    CMakeLists.txt >CMakeLists.txt.tmp
mv CMakeLists.txt.tmp CMakeLists.txt 

#
# Set the package version in the texinfo(1) version file.
#
sed "
/^@set EDITION/c@set EDITION $versionId
/^@set VERSION/c@set VERSION $versionId" \
    version.texi >version.texi.tmp
mv version.texi.tmp version.texi

#
# If the current package version differs from that of the previous release
# (i.e., the previous invocation of this script),
#
if ! test $versionId = `cat previousVersionId`; then
    #
    # A new package version is being released. Reset the release number.
    #
    echo 1 >releaseNo
elif
    #
    # The same package version is being released. Increment the release number.
    #
    releaseNo=$((`cat releaseNo` + 1))
    echo $releaseNo >releaseNo
fi

#
# Commit, tag, and push the package.
#
git commit -a || true
git tag -f v$versionId
git push

#
# Set the package version of the prevous release.
#
echo $versionId >previousVersionId
