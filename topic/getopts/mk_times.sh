#!/bin/bash
#
# SCRIPT
#   mk_times.sh
# DESCRIPTION
# ARGUMENTS
#   None.
# RETURN
#   0: success.
# DEPENDENCIES
# FAILURE
# AUTHORS
#   Date strings made with 'date +"\%Y-\%m-\%d \%H:\%M"'.
#   Allard Berends (AB), 2018-09-09 17:28
# HISTORY
#   2018-09-09 17:28, AB start.
# LICENSE
#   Copyright (C) 2018 Allard Berends
#
#   mk_times.sh is free software; you can redistribute it
#   and/or modify it under the terms of the GNU General
#   Public License as published by the Free Software
#   Foundation; either version 3 of the License, or (at your
#   option) any later version.
#
#   mk_times.sh is distributed in the hope that it will be
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
  echo "Usage: $PNAME -s 2010-02-27 -e 2019-09-20 -i 10 DIR_PATH"
  echo
  echo " -e <end time>, e.g. 2019-09-20"
  echo " -i <in between steps>, e.g. 10, >1 and <21"
  echo " -s <start time>, e.g. 2010-02-27"
  echo " -u <uid>, e.g. 1000"
  echo " -h : this help message"
  echo " DIR_PATH must be a writable directory"
  echo
  echo " The given example creates 11 files, varying in timestamp from 2010-02-27 through 2019-09-20"
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
    e)  END_TIME=$OPTARG ;;
    i)  IN_BETWEEN_STEPS=$OPTARG ;;
    s)  START_TIME=$OPTARG ;;
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
  # Verify END_TIME
  E_ERROR=0
  if [ -z "$END_TIME" ]; then
    E_ERROR=1
  elif [ -z "$(echo $END_TIME | grep '^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}$')" ]; then
    E_ERROR=2
  fi
  if [ $E_ERROR -ne 0 ]; then
    echo "The -e option is required and must be yyyy-mm-dd" >&2
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

  # Verify START_TIME
  S_ERROR=0
  if [ -z "$START_TIME" ]; then
    S_ERROR=1
  elif [ -z "$(echo $START_TIME | grep '^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}$')" ]; then
    S_ERROR=2
  fi
  if [ $S_ERROR -ne 0 ]; then
    echo "The -e option is required and must be yyyy-mm-dd" >&2
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
#   mk_time
# DESCRIPTION
#   Given a file path, create it with specified timestamp.
# PARAMETERS
#   1: file path
#   2: timestamp
#   3: uid
# EXIT CODE
#   1: error
#
mk_time() {
  touch -d $2 $1
  chown $3:$3 $1
} # end mk_time

#
# FUNCTION
#   mk_times_in_dir
# DESCRIPTION
#   Given a directory path, make the specified number of
#   files in it.
# PARAMETERS
#   1: directory path
#   2: start time
#   3: end time
#   4: steps
#   5: uid
# EXIT CODE
#   1: error
#
mk_times_in_dir() {
  # AB: protect higher level, use local!
  local s=$(date --date $2 +%s)
  local e=$(date --date $3 +%s)
  if [ $s -gt $e ]; then
    local save=$s
    s=$e
    e=$save
  fi
  local difference=$(($e - $s))
  local stepsize
  if [ $difference -eq 0 ]; then
    stepsize=1
  else
    stepsize=$(($difference / $4))
  fi
  local template="file%s"
  local i=$s
  while [ $i -le $e ]
  do
    timestamp=$(date -d "@$i" +"%Y-%m-%d")
    mk_time $1/$(printf 'file%s' $timestamp) $timestamp $5
    i=$(($i + $stepsize))
  done
} # end mk_times_in_dir

# Get command line options.
options $*

# Verify command line options.
verify

# Run.
mk_times_in_dir $DIR_PATH $START_TIME $END_TIME $IN_BETWEEN_STEPS $USER_ID
