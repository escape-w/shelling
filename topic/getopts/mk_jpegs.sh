#!/bin/bash
#
# SCRIPT
#   mk_jpegs.sh
# DESCRIPTION
# ARGUMENTS
#   None.
# RETURN
#   0: success.
# DEPENDENCIES
# FAILURE
# AUTHORS
#   Date strings made with 'date +"\%Y-\%m-\%d \%H:\%M"'.
#   Allard Berends (AB), 2018-07-30 21:17
# HISTORY
#   2018-07-30 21:39, AB start.
# LICENSE
#   Copyright (C) 2018 Allard Berends
#
#   mk_jpegs.sh is free software; you can redistribute it
#   and/or modify it under the terms of the GNU General
#   Public License as published by the Free Software
#   Foundation; either version 3 of the License, or (at your
#   option) any later version.
#
#   mk_jpegs.sh is distributed in the hope that it will be
#   useful, but WITHOUT ANY WARRANTY; without even the
#   implied warranty of MERCHANTABILITY or FITNESS FOR A
#   PARTICULAR PURPOSE. See the GNU General Public License
#   for more details.
#
#   You should have received a copy of the GNU General
#   Public License along with this program; if not, write to
#   the Free Software Foundation, Inc., 59 Temple Place -
#   Suite 330, Boston, MA 02111-1307, USA.
# DESIGN
#
PNAME=$(basename $0)
DATETIME_SED="s/\(....\):\(..\):\(..\)-/\1-\2-\3 /"

#
# FUNCTION
#   usage
# DESCRIPTION
#   This function explains how this script should be called
#   on the command line.
# RETURN CODE
#   Nothing
#
usage() {
  echo "Usage: $PNAME -d 3 -j 99 -s 2016:01:01-00:20:20 -e 2017:02:01-00:20:20 pictures"
  echo
  echo " -d <directories with jpegs>, between 1 and 5"
  echo " -e <end datetime yyyy:mm:dd-hh:mm:ss>, e.g. 2017:02:01-00:20:20"
  echo " -j <jpegs per directory>, between 1 and 999"
  echo " -s <start datetime yyyy:mm:dd-hh:mm:ss>, e.g. 2017:01:01-00:20:20"
  echo " -h : this help message"
  echo " DIR_PATH must be a writable directory"
  echo
} # end usage

#
# FUNCTION
#   options
# DESCRIPTION
#   This function parses the command line options.
#   If an option requires a parameter and it is not
#   given, this function exits with error code 1, otherwise
#   it succeeds. Parameter checking is done later.
# EXIT CODE
#   0: success, only whith asking help with -h
#   1: error
#
options() {
  # Assume correct processing
  RC=0

  while getopts "d:e:j:s:h" Option 2>/dev/null
  do
    case $Option in
    d)  DIRS_WITH_JPEGS=$OPTARG ;;
    e)  END_DATETIME=$OPTARG ;;
    j)  JPEGS_PER_DIR=$OPTARG ;;
    s)  START_DATETIME=$OPTARG ;;
    ?|h|-h|-help)  usage
        exit 0 ;;
    *)  usage
        exit 1 ;;
    esac
  done

  shift $(($OPTIND-1))
  ARGS=$@
} # end options

#
# FUNCTION
#   verify
# DESCRIPTION
#   This function verifies the parameters obtained from
#   the command line.
# EXIT CODE
#   1: error
#
verify() {
  # Verify DIRS_WITH_JPEGS
  D_ERROR=0
  if [ -z "$DIRS_WITH_JPEGS" ]; then
    D_ERROR=1
  elif [ $DIRS_WITH_JPEGS -lt 1 ] || [ $DIRS_WITH_JPEGS -gt 5 ]; then
    D_ERROR=2
  fi
  if [ $D_ERROR -ne 0 ]; then
    echo "The -d option is required and must be between 1 and 5." >&2
    echo
    usage
    exit 1
  fi

  # Verify END_DATETIME
  E_ERROR=0
  if [ -z "$END_DATETIME" ]; then
    E_ERROR=1
  else
    END_DATETIME=$(echo $END_DATETIME | sed "$DATETIME_SED")
    date --date "$END_DATETIME" >/dev/null 2>&1
    E_ERROR=$?
  fi
  if [ $E_ERROR -ne 0 ]; then
    echo "The -e option is required and must be in the format yyyy:mm:dd-hh:mm:ss." >&2
    echo
    usage
    exit 1
  fi

  # Verify JPEGS_PER_DIR
  J_ERROR=0
  if [ -z "$JPEGS_PER_DIR" ]; then
    J_ERROR=1
  elif [ $JPEGS_PER_DIR -lt 1 ] || [ $JPEGS_PER_DIR -gt 999 ]; then
    J_ERROR=2
  fi
  if [ $J_ERROR -ne 0 ]; then
    echo "The -j option is required and must be between 1 and 999." >&2
    echo
    usage
    exit 1
  fi

  # Verify START_DATETIME
  S_ERROR=0
  if [ -z "$START_DATETIME" ]; then
    S_ERROR=1
  else
    START_DATETIME=$(echo $START_DATETIME | sed "$DATETIME_SED")
    date --date "$START_DATETIME" >/dev/null 2>&1
    S_ERROR=$?
  fi
  if [ $S_ERROR -ne 0 ]; then
    echo "The -s option is required and must be in the format yyyy:mm:dd-hh:mm:ss." >&2
    echo
    usage
    exit 1
  fi

  # Verify DIR_PATH argument
  DIR_PATH=${ARGS[0]}
  ERROR=0
  if [ -z "$DIR_PATH" ]; then
    ERROR=1
  elif [ ! -d $DIR_PATH ]; then
    ERROR=2
  fi
  if [ $ERROR -ne 0 ]; then
    echo "The first argument must be a writable directory" >&2
    echo
    usage
    exit 1
  fi
} # end verify

#
# FUNCTION
#   mk_jpeg
# DESCRIPTION
#   Given a file path, make an empty jpeg in it. Set the
#   datetime EXIF value.
# PARAMETERS
#   1: jpeg path
#   2: datetime in yyyy:mm:dd-hh:mm:ss
# EXIT CODE
#   1: error
#
mk_jpeg() {
  convert -size 32x32 xc:white $1
  jhead -q -mkexif $1
  jhead -q -ts$2 $1
} # end mk_jpeg

#
# FUNCTION
#   mk_jpeg_in_dir
# DESCRIPTION
#   Given a directory path, make the specified number of
#   files in it.
# PARAMETERS
#   1: directory path
#   2: number of jpegs
#   3: start datetime
#   4: end datetime
# EXIT CODE
#   1: error
#
mk_jpeg_in_dir() {
  # AB: protect higher level, use local!
  local number=$(printf "%d" $2)
  local len=${#number}
  local dt=0
  local start=$(date --date "$3" +%s)
  local end=$(date --date "$4" +%s)
  if [ $end -le $start ]; then
    echo "$3 is later than $4" >&2
    exit 1
  fi
  local step=$((($end - $start) / $2))
  if [ $step -eq 0 ]; then
    step=1
  fi
  local i=0
  while [ $i -lt $2 ]
  do
    i=$(($i + 1))
    dt=$(($start + $i * $step))
    dt_string=$(date --date @$dt +"%Y:%m:%d-%H:%M:%S")
    mk_jpeg $1/$(printf "DSC_%0${len}d.JPG" $i) $dt_string
  done
} # end mk_jpeg_in_dir

#
# FUNCTION
#   mk_dirs
# DESCRIPTION
#   Given a directory path, make the specified number of
#   directories and the specified number of files in it.
# PARAMETERS
#   1: directory path
#   2: number of directories
#   3: number of jpegs
#   4: start datetime
#   5: end datetime
# EXIT CODE
#   1: error
#
mk_dirs() {
  # AB: protect higher level i, use local!
  local i=0
  local d=""
  while [ $i -lt $2 ]
  do
    i=$(($i + 1))
    d=$1/$(printf "1%02dD3300" $i)
    mkdir $d 2>/dev/null
    mk_jpeg_in_dir $d $3 "$4" "$5"
  done
} # end mk_dirs

# Get command line options.
options $*

# Verify command line options.
verify

# Run.
mk_dirs $DIR_PATH $DIRS_WITH_JPEGS $JPEGS_PER_DIR "$START_DATETIME" "$END_DATETIME"
