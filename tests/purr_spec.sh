#!/usr/bin/env shellspec

Describe 'purr'
Include /usr/local/lib/purr/backup.sh
Include /usr/local/lib/purr/mirrors.sh
Include /usr/local/lib/purr/permissions.sh
Include /usr/local/lib/purr/logging.sh
Include /usr/local/lib/purr/utils.sh

Describe 'CLI Options'
It 'handles quiet mode'
When run purr -q
The status should be success
The stdout should be blank
End

It 'handles logging mode'
When run purr -l
The status should be success
The path '/var/log/rate-mirror.log' should be file
End

It 'shows help'
When run purr -h
The status should be success
The stdout should include 'Usage:'
End
End

Describe 'Backup Operations'
It 'creates backup directory'
When call backup
The path "${BACKUP_PATH}" should be directory
End

It 'generates valid metadata'
When call generate_metadata
The file "${METADATA_FILE}" should be exist
The file "${METADATA_FILE}" should include '"backup":'
The file "${METADATA_FILE}" should include '"timestamp":'
End

It 'verifies backup checksums'
backup_file="${BACKUP_PATH}/test_backup.tar.gz"
When call verify_backup "${backup_file}"
The status should be success
End

It 'maintains maximum backup count'
When call backup
The command "find ${BACKUP_PATH} -name '*.tar.gz' | wc -l" output should be le 5
End
End

Describe 'Mirror Management'
It 'detects repository lists'
When call detect_repos
The variable FOUND_REPOS should not be empty
End

It 'validates mirror handlers'
When call check_mirror_handler
The status should be success
End

It 'generates new mirrors'
temp_file="$(mktemp)"
When call generate_mirrors "${temp_file}" "core"
The status should be success
The file "${temp_file}" should be exist
The file "${temp_file}" should include 'Server'
End

It 'updates mirror files'
source_file="test-mirrorlist"
target_file="$(mktemp)"
When call update_files "${source_file}" "${target_file}"
The status should be success
End
End

Describe 'Permission Management'
It 'verifies read permissions'
When call verify_permissions "/etc/pacman.conf" "r"
The status should be success
End

It 'verifies write permissions'
When call verify_permissions "${BACKUP_PATH}" "w"
The status should be success
End

It 'handles missing files'
When call verify_permissions "/nonexistent" "r"
The status should be failure
End

It 'verifies checksums'
test_file="$(mktemp)"
echo "test" >"${test_file}"
checksum="$(sha256sum "${test_file}" | cut -d' ' -f1)"
When call verify_checksum "${test_file}" "${checksum}"
The status should be success
End
End

Describe 'Logging'
It 'logs messages'
When call log "6" "test message"
The status should be success
End

It 'formats output messages'
When call output "34" "test message" "→"
The status should be success
End

It 'handles debug messages'
DEBUG=1
When call debug "test debug"
The status should be success
End

It 'handles error messages'
When call err "test error"
The stderr should include "test error"
End
End

Describe 'Utility Functions'
It 'cleans up temporary files'
temp_file="$(mktemp)"
When call cleanup "${temp_file}"
The path "${temp_file}" should not be exist
End

It 'parses valid options'
When call parse_options "-q" "-l"
The status should be success
The variable QUIET should eq 1
The variable FILE_LOG should eq 1
End

It 'handles invalid options'
When call parse_options "-z"
The status should be failure
End
End
End

Describe 'Environment Variables'
It 'respects path overrides'
When call echo "${PURR_LIB_PATH}"
The output should not be blank
When call echo "${PURR_BACKUP_PATH}"
The output should not be blank
When call echo "${PURR_LOG_FILE}"
The output should not be blank
When call echo "${PURR_MIRROR_PATH}"
The output should not be blank
End

It 'respects value overrides'
When call echo "${PURR_MAX_BACKUPS}"
The output should not be blank
End
End

# vim: fenc=utf-8:ts=2:sw=2:sta:et:sts=2:fdm=marker:ai:tw=80:
# vim: cc=80:commentstring=#%s:
