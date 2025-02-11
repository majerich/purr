# Purr

Purr is a mirror list management tool for Arch Linux based systems.

## Dependencies

* rate-mirrors
* jq (for JSON processing)
* sudo privileges
* systemd (for service checks)

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

* Backup Path: `/var/cache/rate-mirror`
* Log File: `/var/log/rate-mirror.log`
* Mirror Path: `/etc/pacman.d``
* Maximum Backups: 5

## License

MIT

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request
