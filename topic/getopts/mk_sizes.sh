#!/bin/bash
#
# SCRIPT
#   mk_sizes.sh
# DESCRIPTION
# ARGUMENTS
#   None.
# RETURN
#   0: success.
# DEPENDENCIES
# FAILURE
# AUTHORS
#   Date strings made with 'date +"\%Y-\%m-\%d \%H:\%M"'.
#   Allard Berends (AB), 2018-08-22 23:17
# HISTORY
#   2018-08-30 23:39, AB start.
# LICENSE
#   Copyright (C) 2018 Allard Berends
#
#   mk_sizes.sh is free software; you can redistribute it
#   and/or modify it under the terms of the GNU General
#   Public License as published by the Free Software
#   Foundation; either version 3 of the License, or (at your
#   option) any later version.
#
#   mk_sizes.sh is distributed in the hope that it will be
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
  echo "Usage: $PNAME -s 0 -e 60000000 -i 10 DIR_PATH"
  echo
  echo " -e <end size in bytes>, e.g. 1000000, < 1000000001 (1GB)"
  echo " -i <in between steps>, e.g. 10, >1 and <21"
  echo " -s <start size in bytes>, e.g. 0, < 1000000001 (1GB)"
  echo " -u <uid>, e.g. 1000"
  echo " -h : this help message"
  echo " DIR_PATH must be a writable directory"
  echo
  echo " The given example creates 11 files, varying is size of 0 bytes to 600 MB:"
  echo " Note that given integer arithmetic, the number of files might be more than you expect"
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

  while getopts "e:i:s:u:h" Option 2>/dev/null
  do
    case $Option in
    e)  END_SIZE=$OPTARG ;;
    i)  IN_BETWEEN_STEPS=$OPTARG ;;
    s)  START_SIZE=$OPTARG ;;
    u)  USER_ID=$OPTARG ;;
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
  # Verify END_SIZE
  E_ERROR=0
  if [ -z "$END_SIZE" ]; then
    E_ERROR=1
  elif [ $END_SIZE -lt 0 ] || [ $END_SIZE -gt 1000000000 ]; then
    E_ERROR=2
  fi
  if [ $E_ERROR -ne 0 ]; then
    echo "The -e option is required and -1 < option < 1000000001" >&2
    echo
    usage
    exit 1
  fi

  # Verify IN_BETWEEN_STEPS
  I_ERROR=0
  if [ -z "$IN_BETWEEN_STEPS" ]; then
    I_ERROR=1
  elif [ $IN_BETWEEN_STEPS -lt 1 ] || [ $IN_BETWEEN_STEPS -gt 20 ]; then
    I_ERROR=2
  fi
  if [ $I_ERROR -ne 0 ]; then
    echo "The -i option is required and must be between 1 and 20." >&2
    echo
    usage
    exit 1
  fi

  # Verify START_SIZE
  S_ERROR=0
  if [ -z "$START_SIZE" ]; then
    E_ERROR=1
  elif [ $START_SIZE -lt 0 ] || [ $START_SIZE -gt 1000000000 ]; then
    E_ERROR=2
  fi
  if [ $E_ERROR -ne 0 ]; then
    echo "The -e option is required and -1 < option < 1000000001" >&2
    echo
    usage
    exit 1
  fi

  # Verify USER_ID
  U_ERROR=0
  if [ -z "$USER_ID" ]; then
    USER_ID=$UID
  elif [ $USER_ID -lt 0 ] || [ $USER_ID -gt 10000 ]; then
    E_ERROR=2
  fi
  if [ $E_ERROR -ne 0 ]; then
    echo "If given, -e option -1 < option < 10000" >&2
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
    mkdir -p $DIR_PATH 2>/dev/null
    RC=$?
    if [ $RC -ne 0 ]; then
      ERROR=2
    fi
  fi
  if [ $ERROR -ne 0 ]; then
    echo "The first argument must be a writable directory or non-existent path" >&2
    echo
    usage
    exit 1
  fi
} # end verify

#
# FUNCTION
#   mk_size
# DESCRIPTION
#   Given a file path, create it with specified size. If
#   specified size is 0 or smaller, the size is set to 0.
# PARAMETERS
#   1: file path
#   2: size in bytes
#   3: uid
# EXIT CODE
#   1: error
#
mk_size() {
  truncate -s 0 $1
  chown $3:$3 $1
  if [ $2 -le 0 ]; then
    return
  fi
  fallocate -l $2 $1
} # end mk_size

#
# FUNCTION
#   mk_sizes_in_dir
# DESCRIPTION
#   Given a directory path, make the specified number of
#   files in it.
# PARAMETERS
#   1: directory path
#   2: start size
#   3: end size
#   4: steps
#   5: uid
# EXIT CODE
#   1: error
#
mk_sizes_in_dir() {
  # AB: protect higher level, use local!
  local difference=$(($3 - $2))
  local stepsize
  if [ $difference -eq 0 ]; then
    stepsize=1
  else
    stepsize=$(($difference / $4))
  fi
  local len=${#3}
  local template="file%0${len}d"
  local i=$2
  while [ $i -le $3 ]
  do
    mk_size $1/$(printf $template $i) $i $5
    i=$(($i + $stepsize))
  done
} # end mk_sizes_in_dir

# Get command line options.
options $*

# Verify command line options.
verify

# Run.
mk_sizes_in_dir $DIR_PATH $START_SIZE $END_SIZE $IN_BETWEEN_STEPS $USER_ID
