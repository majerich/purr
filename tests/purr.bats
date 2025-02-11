#!/usr/bin/env bats

load '/usr/lib/bats-support/load.bash'
load '/usr/lib/bats-assert/load.bash'
load '/usr/lib/bats-file/load.bash'

# Load function to test
source "${BATS_TEST_DIRNAME}/../src/purr.sh"

# Setup test environment
setup() {
  export TMPDIR="$(mktemp -d)"
  mkdir -p "${TMPDIR}/etc/pacman.d"
  export BACKUP_PATH="${TMPDIR}/backups"
  export MIRROR_PATH="${TMPDIR}/etc/pacman.d"
}

teardown() {
  rm -rf "${TMPDIR}"
}

# Basic functionality tests
@test "purr shows usage when no arguments provided" {
  run purr
  assert_success
}

@test "purr detects missing rate-mirrors" {
  PATH=""
  run purr
  assert_failure
  assert_output --partial "rate-mirrors not found"
}

@test "purr creates backup directory" {
  run purr -c
  assert_success
  assert [ -d "${BACKUP_PATH}" ]
}

@test "purr handles backup rotation" {
  for i in {1..6}; do
    purr -c
    sleep 1
  done

  count=$(find "${BACKUP_PATH}" -name "*.tar.gz" | wc -l)
  [ "$count" -eq 5 ]
}

@test "purr shows available backups" {
  purr -c
  run purr -s
  assert_success
  assert_output --partial "Available backups:"
}

@test "purr restores from backup" {
  # Create initial backup
  echo "test" >"${MIRROR_PATH}/mirrorlist"
  purr -c
  local backup_date=$(find "${BACKUP_PATH}" -name "*.tar.gz" | head -n1 | xargs basename | sed 's/\.tar\.gz//')

  # Modify file
  echo "modified" >"${MIRROR_PATH}/mirrorlist"

  # Restore backup
  run purr -r "${backup_date}"
  assert_success

  # Verify content
  run cat "${MIRROR_PATH}/mirrorlist"
  assert_output "test"
}

@test "purr handles undo operation" {
  # Create initial state
  echo "original" >"${MIRROR_PATH}/mirrorlist"
  purr -c

  # Modify file
  echo "modified" >"${MIRROR_PATH}/mirrorlist"
  purr -c

  # Undo
  run purr -u
  assert_success

  # Verify content
  run cat "${MIRROR_PATH}/mirrorlist"
  assert_output "original"
}

@test "purr checks for active mirror handlers" {
  # Mock systemctl for ghostmirror
  function systemctl() {
    if [[ "$*" == "--user is-active ghostmirror.timer" ]]; then
      return 0
    fi
    return 1
  }
  export -f systemctl

  run purr
  assert_failure
  assert_output --partial "managed by 'ghostmirror'"
}

@test "purr handles quiet mode" {
  run purr -q -c
  assert_success
  refute_output
}

@test "purr creates metadata in backup" {
  run purr -c
  assert_success

  latest_backup=$(find "${BACKUP_PATH}" -name "*.tar.gz" | sort | tail -n1)
  run tar tzf "${latest_backup}"
  assert_output --partial "metadata.json"
}

@test "purr validates backup date format" {
  run purr -r "invalid_date"
  assert_failure
  assert_output --partial "Backup not found"
}

@test "purr handles missing mirrorlists" {
  rm -f "${MIRROR_PATH}"/*mirrorlist
  run purr
  assert_failure
  assert_output --partial "No repository mirrorlists found"
}

# ---
# vim: fenc=utf-8:ts=2:sw=2:sta:et:sts=2:fdm=marker:ai:ft=sh:tw=80:
# vim: cc=80:commentstring=#%s:
