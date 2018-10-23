#!/bin/bash


# displays usage
function _option_usage {
  cat <<HEREDOC
##############################################################################
#   Title: bashito.sh
#  Author: Mike Stine
#    Date: 170130  
# Version: 0.1 
# Description:  This little bash helper script is a tool for developers.  
#          Inspired by boilerplates, best practices, and writing the same 
#          functions over and over again.  I set out to write a helper script, 
#          that can be easily included and removed from the script you are 
#          writing, to give you your script additional functionality, 
#          ultimately aiding you while developing.  To use, add "source 
#          bashito.sh" under the #!/bin/bash in <yourscript.sh>. Additional 
#          functionality is evoked through options.  
#   Usage:
#          <yourscript.sh> [<arguments>]
#          <yourscript.sh> -h | --help
# Options:
#          -h —-help,      Prints usage.
#          -l --lock,      Ensure only one instance of script can run without
#                          using flock.  
#          -r --runtime,   Calculate and display runtime when script is done 
#                          running.  
#          -s --strict,    For development and good practice,  will turn on
#                          bash "strict" mode.
#          -t --timestamp, Adds timestamp to echo
#          -v —-verbose,   For development, an alternative to echo, Prints 
#                          strings passed to “_verbose” function
#          -x —-xtrace,    For development, print command traces before 
#                          executing command
#          -d --dev,       Shortcut for -rstv
##############################################################################
HEREDOC
}


##############################################################################
# Default Options
_OPT_LOCK=false
_OPT_RUNTIME=false
_OPT_STRICT=false
_OPT_TIMESTAMP=false 
_OPT_VERBOSE=false

##############################################################################
# Overwrite Echo
# Adds timestamp and script name to echo if timestamp option is true
function echo {
  if [ "$_OPT_TIMESTAMP" = true ] ; then
    printf "[${_SCRIPT_NAME}]($(date "+%Y-%m-%d %H:%M:%S")) $@\n"
  else
    builtin echo "$@"
  fi
}

##############################################################################
# Displays programmers debugging messages
function _verbose {
  if [ "$_OPT_VERBOSE" = true ] ; then
    echo "$@"
  fi
}

##############################################################################
# Get and parse options
# Because of "getopts" inconsistant implementations and lack of portability, 
# to achieve long options with built in "getopt", the long options are replaced
# by short options. Credit to Cyril Martin, 2015
function _get_options {

  # Replace long options with short options
  for arg in "$@"; do
    shift
    case "$arg" in
      "--help")      set -- "$@" "-h" ;;
      "--lock")      set -- "$@" "-l" ;;
      "--runtime")   set -- "$@" "-r" ;;
      "--strict")    set -- "$@" "-s" ;;
      "--timestamp") set -- "$@" "-t" ;;
      "--verbose")   set -- "$@" "-v" ;;
      "--xtrace")    set -- "$@" "-x" ;;
      "--dev")       set -- "$@" "-d" ;;
      *)             set -- "$@" "$arg"
    esac
  done

  #parse short options
  OPTIND=1
  while getopts "hlrstvxd" opt
  do
    case "$opt" in
      "h") _option_usage; exit 0 ;;
      "l") _OPT_LOCK=true ;;
      "r") _OPT_RUNTIME=true ;;
      "s") _OPT_STRICT=true ;;
      "t") _OPT_TIMESTAMP=true ;;
      "v") _OPT_VERBOSE=true ;;
      "x") set -o xtrace  ;;
      "d") _OPT_RUNTIME=true; _OPT_STRICT=true; _OPT_TIMESTAMP=true; _OPT_VERBOSE=true  ;;
      "?") _option_usage >&2; exit 1 ;;
    esac
  done
  shift "$((OPTIND-1))" # Shift off the options and optional --.
  
}

##############################################################################
# Init bashito
# This should be executed before anything else
function _init { 

  # Script Environment
  _SCRIPT_NAME=$(basename "${0}")
  _SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
  _START_TIME=$(date +"%s")
  
  # Get and Parse Options
  _get_options "$@"

  _verbose "_init: $@"
 
  # Option Strict
  if [ "$_OPT_STRICT" = true ] ; then
    _verbose "Turning On Strict Mode"
    set -o errexit  # -e, Exit immediately if a command exits with a non-zero status.
    set -o errtrace # -E, any trap on ERR is inherited by shell function, command substitutions, and commands executed in a sub‐shell environment
    set -o pipefail # Causes a pipeline to return the exit status of the last command in the pipe that returned a non-zero return value.
    set -o nounset  # -u, Attempt to use undefined variable outputs error message, and forces an exit
  
    # change default IFS from space to newline, allows spaces in array entries
    DEFAULT_IFS="${IFS}"
    SAFER_IFS=$'\n\t'
    IFS="${SAFER_IFS}"
  fi

  # Set Traps
  _verbose "Setting Traps"
  trap _trap_err ERR
  trap _cleanup HUP INT QUIT TERM EXIT

  # Option Lock
  # if locked, test for parallel process 
  if [ "$_OPT_LOCK" = true ] && [  "$(ps -ef | grep "[/]bin/bash ${_SCRIPT_DIR}/${_SCRIPT_NAME}"| wc -l)" -gt 2 ]; then
    echo "Exiting - This script is and already running."
    exit 1
  fi

}

##############################################################################
# Trap signal err
function _trap_err {
  _verbose "_trap_err"
  echo "${_SCRIPT_NAME} Aborting due to errexit on line $LINENO. Exit code: $?" >&2
}

##############################################################################
# Cleanup Function, called by exit trap
function _cleanup {
  _verbose "_cleanup"
  
  if [ "$_OPT_RUNTIME" = true ] ; then
    # calculate runtime
    local runtime_in_seconds=$(($(date +"%s")-${_START_TIME}))
    echo "RUNTIME: ${runtime_in_seconds}s"
  fi
}

##############################################################################
# And away we go

_init "$@"
