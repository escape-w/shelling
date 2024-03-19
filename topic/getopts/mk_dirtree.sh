#!/bin/bash
#
# SCRIPT
#   mk_dirtree.sh
# DESCRIPTION
# ARGUMENTS
#   None.
# RETURN
#   0: success.
# DEPENDENCIES
# FAILURE
# AUTHORS
#   Date strings made with 'date +"\%Y-\%m-\%d \%H:\%M"'.
#   Allard Berends (AB), 2018-07-22 19:17
# HISTORY
#   2018-07-22 19:22, AB start.
# LICENSE
#   Copyright (C) 2018 Allard Berends
#
#   mk_dirtree.sh is free software; you can redistribute it
#   and/or modify it under the terms of the GNU General
#   Public License as published by the Free Software
#   Foundation; either version 3 of the License, or (at your
#   option) any later version.
#
#   mk_dirtree.sh is distributed in the hope that it will be
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
  echo "Usage: $PNAME -d 3 -f 4 -l 2 DIR_PATH"
  echo
  echo " -d <directories per level>, between 1 and 5"
  echo " -f <files per level>, between 1 and 5"
  echo " -l <levels of directories deep>, between 1 and 5"
  echo " -u <uid>, e.g. 1000"
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

  while getopts "d:f:l:u:h" Option 2>/dev/null
  do
    case $Option in
    d)  DIRS_PER_LEVEL=$OPTARG ;;
    f)  FILES_PER_LEVEL=$OPTARG ;;
    l)  LEVELS_DEEP=$OPTARG ;;
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
  # Verify DIRS_PER_LEVEL
  D_ERROR=0
  if [ -z "$DIRS_PER_LEVEL" ]; then
    D_ERROR=1
  elif [ $DIRS_PER_LEVEL -lt 1 ] || [ $DIRS_PER_LEVEL -gt 5 ]; then
    D_ERROR=2
  fi
  if [ $D_ERROR -ne 0 ]; then
    echo "The -d option is required and must be between 1 and 5." >&2
    echo
    usage
    exit 1
  fi

  # Verify FILES_PER_LEVEL
  F_ERROR=0
  if [ -z "$FILES_PER_LEVEL" ]; then
    F_ERROR=1
  elif [ $FILES_PER_LEVEL -lt 1 ] || [ $FILES_PER_LEVEL -gt 5 ]; then
    F_ERROR=2
  fi
  if [ $F_ERROR -ne 0 ]; then
    echo "The -f option is required and must be between 1 and 5." >&2
    echo
    usage
    exit 1
  fi

  # Verify LEVELS_DEEP
  L_ERROR=0
  if [ -z "$LEVELS_DEEP" ]; then
    L_ERROR=1
  elif [ $LEVELS_DEEP -lt 1 ] || [ $LEVELS_DEEP -gt 5 ]; then
    L_ERROR=2
  fi
  if [ $L_ERROR -ne 0 ]; then
    echo "The -l option is required and must be between 1 and 5." >&2
    echo
    usage
    exit 1
  fi

  # Verify USER_ID
  U_ERROR=0
  if [ -z "$USER_ID" ]; then
    USER_ID=$UID
  elif [ $USER_ID -lt 0 ] || [ $USER_ID -gt 10000 ]; then
    U_ERROR=2
  fi
  if [ $U_ERROR -ne 0 ]; then
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
#   mk_files_in_dir
# DESCRIPTION
#   Given a directory path, make the specified number of
#   files in it.
# PARAMETERS
#   1: directory path
#   2: number of files
#   3: uid
# EXIT CODE
#   1: error
#
mk_files_in_dir() {
  if [ ! -d $1 ]; then
    echo "Given directory $1 does not exist" >&2
    exit 1
  fi
  # AB: protect higher level i, use local!
  local i=0
  while [ $i -lt $2 ]
  do
    i=$(($i + 1))
    touch $1/file${i}
    chown $3:$3 $1/file${i}
  done
} # end mk_files_in_dir

#
# FUNCTION
#   mk_dirs_in_dir
# DESCRIPTION
#   Given a directory path, make the specified number of
#   files in it.
# PARAMETERS
#   1: directory path
#   2: number of directories
#   3: uid
# EXIT CODE
#   1: error
#
mk_dirs_in_dir() {
  if [ ! -d $1 ]; then
    echo "Given directory $1 does not exist" >&2
    exit 1
  fi
  # AB: protect higher level i, use local!
  local i=0
  while [ $i -lt $2 ]
  do
    i=$(($i + 1))
    mkdir $1/dir${i}
    chown $3:$3 $1/dir${i}
  done
} # end mk_dirs_in_dir

#
# FUNCTION
#   mk_level
# DESCRIPTION
#   Given a directory path, make the specified number of
#   directories and the specified number of files in it.
# PARAMETERS
#   1: directory path
#   2: number of directories
#   3: number of files
#   4: level
#   5: max level
#   6: uid
# EXIT CODE
#   1: error
#
mk_level() {
  # Recurse into next level.
  if [ $4 -lt $5 ]; then
    mk_dirs_in_dir $1 $2 $6
    mk_files_in_dir $1 $3 $6
    # AB: note that children of this code, with respect to
    # the stack tree, have access to local variables. Hence
    # the called code must also declare i and l as local
    # variables! Otherwise things go horribly wrong.
    local i=0
    local l=$(($4 + 1))
    while [ $i -lt $2 ]
    do
      i=$(($i + 1))
      mk_level $1/dir${i} $2 $3 $l $5
    done
  fi
} # end mk_level

# Get command line options.
options $*

# Verify command line options.
verify

# Run.
mk_level $DIR_PATH $DIRS_PER_LEVEL $FILES_PER_LEVEL 0 $LEVELS_DEEP $USER_ID
