# Purr

Purr is a mirror list management tool for Arch Linux based systems.

## Dependencies

- rate-mirrors
- jq (for JSON processing)
- sudo privileges
- systemd (for service checks)

## Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/majerich/purr.git
   cd purr
   ```

2. Run the installation script:

   ```bash
   ./install.sh
   ```

3. Verify installation:

   ```bash
   purr -h
   ```

## Environment Variables

Override default paths and values:

- `PURR_LIB_PATH`: Library path (default: /usr/local/lib/purr)
- `PURR_BACKUP_PATH`: Backup storage location (default: /var/cache/rate-mirror)
- `PURR_LOG_FILE`: Log file path (default: /var/log/rate-mirror.log)
- `PURR_MIRROR_PATH`: Mirror configuration path (default: /etc/pacman.d)
- `PURR_MAX_BACKUPS`: Maximum backup retention count (default: 5)

Example development usage:

```bash
PURR_LIB_PATH="./src/lib/purr" \
PURR_BACKUP_PATH="./var/cache" \
PURR_LOG_FILE="./var/log/purr.log" \
./src/bin/purr
```

## Usage

### Basic Mirror Update

Update mirrors with default settings:

```bash
purr
```

### Backup Operations

Create a backup:

```bash
purr -c
```

Show available backups:

```bash
purr -s
```

Restore from backup:

```bash
purr -r YYYYMMDD_HHMMSS
```

### Logging

Enable file logging:

```bash
purr -l
```

Quiet mode:

```bash
purr -q
```

## Configuration

- Backup Path: `/var/cache/rate-mirror`
- Log File: `/var/log/rate-mirror.log`
- Mirror Path: `/etc/pacman.d``
- Maximum Backups: 5

## License

MIT

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request
