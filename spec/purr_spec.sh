#!/usr/bin/env shellspec

Describe 'purr'
Include "${PURR_LIB_PATH:-/usr/local/lib/purr}/backup.sh"
Include "${PURR_LIB_PATH:-/usr/local/lib/purr}/mirrors.sh"
Include "${PURR_LIB_PATH:-/usr/local/lib/purr}/permissions.sh"
Include "${PURR_LIB_PATH:-/usr/local/lib/purr}/logging.sh"
Include "${PURR_LIB_PATH:-/usr/local/lib/purr}/utils.sh"

Describe 'Backup Operations'
backup_path="${PURR_BACKUP_PATH:-/var/cache/rate-mirror}"

It 'creates backup directory'
When call backup
The path "${backup_path}" should be directory
End

It 'maintains maximum backup count'
When call backup
The command "find ${backup_path} -name '*.tar.gz' | wc -l" output should be le "${PURR_MAX_BACKUPS:-5}"
End
End

Describe 'Mirror Management'
mirror_path="${PURR_MIRROR_PATH:-/etc/pacman.d}"

It 'detects repository lists'
When call detect_repos
The path "${mirror_path}" should be directory
End

It 'updates mirror files'
When call update_files "test-mirrorlist" "$(mktemp)"
The status should be success
End
End

Describe 'Logging'
log_file="${PURR_LOG_FILE:-/var/log/rate-mirror.log}"

It 'writes to log file when enabled'
FILE_LOG=1
When call log "6" "test message"
The path "${log_file}" should be file
End
End
End

# vim: fenc=utf-8:ts=2:sw=2:sta:et:sts=2:fdm=marker:ai:ft=sh:tw=80:
# vim: cc=80:commentstring=#%s:
