#!/usr/bin/env bash
#
# Creates a tarball for LArSoft job submission with stripped libraries.
# Run with `--help` for usage instructions.
# 
# Author:  Gianluca Petrillo (petrillo@slac.stanford.edu)
# Date:    February 1, 2023
#

# ------------------------------------------------------------------------------
SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPTDIR="$(dirname "${BASH_SOURCE[0]}")"
SCRIPTVERSION="1.0"

# ------------------------------------------------------------------------------
declare -ar StripOpt=( '-d' )


# ------------------------------------------------------------------------------
function printHelp() {
  cat <<EOH
Compresses a MRB working area, stripping debug symbols from the libraries.

Usage:  ${SCRIPTNAME}  [options] TarballFile

will create a file TarballFile from the install directory.

Options:
--source=SOURCEDIR
    use SOURCEDIR instead of the default from \${MRB_INSTALL}
    ('${MRB_INSTALL}' right now).
--tempdir=TEMPDIR
    use the specified path as temporary directory; it needs to have space enough
    for a full copy of the source area.
    THE EXISTING CONTENT OF THE DIRECTORY WILL BE LOST.
    By default, system temporary directory is used.
--version , -V
    prints the version number and exits.
--help , -h , -?
    print these usage instructions.

EOH
} # printHelp()


function printVersion() {
  echo "${SCRIPTNAME} v${SCRIPTVERSION}."
}


function STDERR() { echo "$*" >&2 ; }
function FATAL() {
  local Code="$1"
  shift
  STDERR "FATAL (${Code}): $*"
  exit "$Code"
} # FATAL()

function IFFATAL() { [[ "$1" == 0 ]] || FATAL "$@" ; }
function LASTFATAL() { IFFATAL $? "$@" ; }


function CleanTemp() {
  [[ -d "$TempDir" ]] && rm -Rf "$TempDir"
}


# ------------------------------------------------------------------------------
# parameter parsing

declare -i NoMoreOptions=0
declare -i DoHelp DoVersion KeepTempDir
declare DestFile
declare SourceDir="$MRB_INSTALL"

for (( iParam = 1 ; iParam <= $# ; ++iParam )); do
  Param="${!iParam}"
  if [[ "${Param:0:1}" == '-' ]] && [[ "$NoMoreOptions" == 0 ]]; then
    case "$Param" in
      ( '--source='* ) SourceDir="${Param#--*=}" ;;
      ( '--tempdir='* ) TempDir="${Param#--*=}" ;;
      ( '--keeptemp' ) KeepTempDir=1 ;;
      ( '--version' | '-V' ) DoVersion=1 ;;
      ( '--help' | '-h' | '-?' ) DoHelp=1 ;;
      ( '-' | '--' ) NoMoreOptions=1 ;;
      ( * )
        FATAL 1 "unknown option #${iParam} - '${Param}'. Use \`--help\` for usage instructions."
    esac
  else
    if [[ -z "$DestFile" ]]; then
      DestFile="$Param"
    else
      FATAL 1 "spurious argument - '${Param}'. Use \`--help\` for usage instructions."
    fi
  fi
  
done

if [[ "${DoHelp:-0}" != 0 ]]; then
  printHelp
  exit 0
fi

if [[ "${DoVersion:-0}" != 0 ]]; then
  printVersion
  exit 0
fi


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# create a temporary area
#

[[ -n "$DestFile" ]] || FATAL 1 "You need to specify the path of the tarball to be created."

[[ -d "$SourceDir" ]] || FATAL 2 "Source directory '${SourceDir}' not found!"

if [[ -n "$TempDir" ]]; then
  mkdir -p "$TempDir" || FATAL $? "Can't create temporary directory '${TempDir}'."
else
  TempDir="$(mktemp --tmpdir -d "${SCRIPTNAME%.sh}-tempInstallDir.XXX")"
fi

if [[ "${KeepTempDir:-0}" == 0 ]]; then
  trap CleanTemp EXIT
else
  echo "The temporary directory '${TempDir}' will be left behind as requested."
fi

echo "Copying the installation area from '${SourceDir}'..."
rsync -auv "${SourceDir}/" "$TempDir" || exit $?

echo "Stripping the debugging symbols..."
find "$TempDir" -name "lib*.so" | xargs --no-run-if-empty strip "${StripOpt[@]}"
declare -a pipeRes=( "${PIPESTATUS[@]}" )
IFFATAL "${pipeRes[1]}" "error stripping library symbols."
IFFATAL "${pipeRes[0]}" "error searching for libraries."

#
# compress it into a tar ball
#
echo "Creating '${DestFile}'..."
make_tarball.sh -d "$TempDir" "$DestFile" || FATAL $? "error creating the tarball."
[[ "${KeepTempDir:-0}" != 0 ]] && echo "The temporary directory '${TempDir}' is left behind as requested."

echo "Done."
