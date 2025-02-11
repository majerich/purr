#!/usr/bin/env bash
#
# Utility functions for purr

# Function: execute_operation
# Description: Executes the requested operation based on CLI flags
# Returns: Operation status code
function execute_operation() {
  if ((RESTORE_MODE)); then
    restore_backup "${RESTORE_DATE}"
    return $?
  fi

  if ((CONFIG_BACKUP)); then
    backup
    return $?
  fi

  if ((UNDO_MODE)); then
    undo_changes
    return $?
  fi

  # Default operation: update mirrors
  update_mirrors
  return $?
}

# Function: cleanup_handler
# Description: Handles cleanup on script exit
# Returns: Original exit code
function cleanup_handler() {
  local exit_code=$?
  cleanup "${METADATA_FILE}" "${TMP_FILES[@]}"
  exit "${exit_code}"
}

# Function: cleanup
# Description: Removes temporary files
# Arguments:
#   $@ - Files to remove
function cleanup() {
  local file
  for file in "$@"; do
    [[ -f "${file}" ]] && rm -f "${file}"
  done
}

# Function: parse_options
# Description: Parses command line options
# Arguments:
#   $@ - Command line arguments
# Returns: 0 on success, E_GENERAL on error
function parse_options() {
  local opt

  QUIET=0
  FILE_LOG=0
  SHOW_BACKUPS=0
  RESTORE_MODE=0
  CONFIG_BACKUP=0
  UNDO_MODE=0
  DEBUG=0
  RESTORE_DATE=""

  while getopts "qlsr:cudh" opt; do
    case "${opt}" in
    q) QUIET=1 ;;
    l) FILE_LOG=1 ;;
    s) SHOW_BACKUPS=1 ;;
    r)
      RESTORE_MODE=1
      RESTORE_DATE="${OPTARG}"
      ;;
    c) CONFIG_BACKUP=1 ;;
    u) UNDO_MODE=1 ;;
    d) DEBUG=1 ;;
    h)
      show_help
      exit 0
      ;;
    *)
      show_help >&2
      return "${E_GENERAL}"
      ;;
    esac
  done
}

# Function: show_help
# Description: Displays usage information
function show_help() {
  cat <<EOF
Usage: purr [options]

Options:
  -q        Quiet mode, suppress stdout
  -l        Enable additional file logging
  -s        Show available backups
  -r DATE   Restore backup from specified date
  -c        Create backup of system mirrors and configuration
  -u        Undo last mirror update
  -d        Enable debug output
  -h        Display this help message
EOF
}

# vim: fenc=utf-8:ts=2:sw=2:sta:et:sts=2:fdm=marker:ai:ft=sh:tw=80:
# vim: cc=80:commentstring=#%s:
