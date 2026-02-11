# Technical Documentation

## Architecture Overview

This setup creates a persistent SSH agent managed by systemd that KeePassXC can communicate with via the standard SSH agent protocol.

### Components

```
┌─────────────────┐
│   KeePassXC     │
│  (SSH Client)   │
└────────┬────────┘
         │
         │ Communicates via SSH_AUTH_SOCK
         │
         ▼
┌─────────────────────────────────┐
│  Unix Socket                     │
│  $XDG_RUNTIME_DIR/ssh-agent.socket│
└────────┬────────────────────────┘
         │
         ▼
┌─────────────────┐
│   ssh-agent     │
│ (systemd service)│
└─────────────────┘
```

### File Locations

- **Systemd Service**: `~/.config/systemd/user/ssh-agent.service`
- **Socket Location**: `$XDG_RUNTIME_DIR/ssh-agent.socket` (typically `/run/user/1000/ssh-agent.socket`)
- **Shell Config**: `~/.bashrc` or `~/.zshrc`

## Systemd Service Details

### Service Unit File

```ini
[Unit]
Description=SSH key agent
Documentation=man:ssh-agent(1)

[Service]
Type=simple
Environment=SSH_AUTH_SOCK=%t/ssh-agent.socket
ExecStartPre=/usr/bin/rm -f %t/ssh-agent.socket
ExecStart=/usr/bin/ssh-agent -D -a $SSH_AUTH_SOCK
ExecStartPost=/usr/bin/systemctl --user set-environment SSH_AUTH_SOCK=${SSH_AUTH_SOCK}
ExecStopPost=/usr/bin/rm -f %t/ssh-agent.socket
Restart=on-failure

[Install]
WantedBy=default.target
```

### Service Configuration Explained

- **`Type=simple`**: Service is considered started immediately after ExecStart is called
- **`Environment=SSH_AUTH_SOCK=%t/ssh-agent.socket`**: 
  - `%t` expands to `$XDG_RUNTIME_DIR` (typically `/run/user/1000`)
  - Sets the socket path for the ssh-agent
- **`ExecStartPre`**: Removes stale socket files before starting
- **`ExecStart`**: 
  - `-D` flag: Don't fork (run in foreground for systemd)
  - `-a $SSH_AUTH_SOCK`: Use specified socket path
- **`ExecStartPost`**: Makes `SSH_AUTH_SOCK` available to systemd user session
- **`ExecStopPost`**: Cleans up socket file when service stops
- **`Restart=on-failure`**: Auto-restart if the service crashes
- **`WantedBy=default.target`**: Start automatically when user session starts

### Systemd Commands

```bash
# Start the service now
systemctl --user start ssh-agent.service

# Enable autostart on login
systemctl --user enable ssh-agent.service

# Check status
systemctl --user status ssh-agent.service

# View logs
journalctl --user -u ssh-agent.service

# Restart the service
systemctl --user restart ssh-agent.service

# Stop and disable
systemctl --user stop ssh-agent.service
systemctl --user disable ssh-agent.service
```

## Environment Variable Configuration

### SSH_AUTH_SOCK

The `SSH_AUTH_SOCK` environment variable tells SSH clients where to find the authentication agent's Unix domain socket.

**Set in Shell Config** (`~/.bashrc` or `~/.zshrc`):
```bash
export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR}/ssh-agent.socket"
```

**Verified with**:
```bash
echo $SSH_AUTH_SOCK
# Expected output: /run/user/1000/ssh-agent.socket
```

### Why This Path?

- **`$XDG_RUNTIME_DIR`**: User-specific runtime directory (per-user, per-session)
- **Automatic cleanup**: systemd cleans up this directory on logout
- **Security**: Only accessible by the owning user
- **Persistence**: Survives across terminal sessions but not reboots

## KeePassXC Integration

### How KeePassXC Connects

1. KeePassXC reads the `SSH_AUTH_SOCK` environment variable
2. Connects to the Unix socket at that path
3. Uses the SSH agent protocol to:
   - List available keys
   - Request signatures for authentication
   - Add/remove keys from the agent

### SSH Agent Protocol

KeePassXC implements the standard SSH agent protocol (RFC 4251) to communicate with ssh-agent:

- `SSH2_AGENTC_REQUEST_IDENTITIES`: List loaded keys
- `SSH2_AGENTC_SIGN_REQUEST`: Sign data with a key
- `SSH2_AGENTC_ADD_IDENTITY`: Add a key to the agent
- `SSH2_AGENTC_REMOVE_IDENTITY`: Remove a key from the agent

### Key Storage in KeePassXC

SSH keys in KeePassXC are stored as:
1. **Attachment**: Private key file attached to database entry
2. **Entry Configuration**: SSH Agent tab settings (key reference, confirmation, lifetime)
3. **Encrypted**: Private key remains encrypted in the database

When you load a key:
- KeePassXC decrypts the private key from the attachment
- Loads it into the running ssh-agent via the socket
- The key remains in agent memory until removed or session ends

## Security Considerations

### Socket Permissions

The socket at `$XDG_RUNTIME_DIR/ssh-agent.socket` has restrictive permissions:
- Owner: Your user account
- Permissions: `srwx------` (socket, user read/write/execute only)
- No other users can access the socket

### Key Security

- **Private keys** remain encrypted in KeePassXC database
- **Master password** required to unlock database and access keys
- **Optional confirmation**: Can require confirmation for each key use
- **Time limits**: Keys can auto-expire from agent after set duration
- **Memory only**: Keys loaded into agent are only in RAM, not written to disk

### Process Isolation

- ssh-agent runs as user-level systemd service (not system-wide)
- Isolated per-user session
- Cannot access other users' agents or keys

## Alternative Setups

### GNOME Keyring SSH Agent

For GNOME users, the desktop environment includes its own SSH agent:

```bash
# Socket path
export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR}/gcr/ssh"

# Enable via systemd
systemctl --user enable gcr-ssh-agent.socket
```

**Pros:**
- Integrated with GNOME desktop
- Single keyring for all credentials

**Cons:**
- GNOME-specific
- May conflict with other SSH agents

### Traditional ssh-agent

Old-school approach (not recommended):

```bash
# In shell config
eval $(ssh-agent)
```

**Why not recommended:**
- Creates new agent process per shell
- Inconsistent socket paths across terminals
- No automatic cleanup
- Environment variable conflicts

## Debugging

### Check Service Status

```bash
systemctl --user status ssh-agent.service
```

Look for:
- `Active: active (running)` - service is running
- Recent log entries showing successful start

### Check Socket

```bash
# Socket should exist
ls -l $SSH_AUTH_SOCK

# Expected output:
# srwx------ 1 username username 0 Feb 10 10:30 /run/user/1000/ssh-agent.socket
```

### Test Connection

```bash
# List keys (even if empty)
ssh-add -l

# Expected output if working but empty:
# The agent has no identities.

# Error if not working:
# Could not open a connection to your authentication agent.
```

### Check Environment

```bash
# Verify SSH_AUTH_SOCK is set
env | grep SSH_AUTH_SOCK

# Should show:
# SSH_AUTH_SOCK=/run/user/1000/ssh-agent.socket
```

### View Logs

```bash
# Recent logs
journalctl --user -u ssh-agent.service -n 50

# Follow logs in real-time
journalctl --user -u ssh-agent.service -f
```

### Common Issues

**Issue**: `SSH_AUTH_SOCK` not set in new terminals
- **Cause**: Shell config not sourced
- **Fix**: Restart terminal or run `source ~/.bashrc`

**Issue**: Multiple ssh-agent processes
- **Cause**: Old agents not cleaned up
- **Fix**: `pkill ssh-agent && systemctl --user restart ssh-agent.service`

**Issue**: Socket file doesn't exist
- **Cause**: Service not running
- **Fix**: `systemctl --user start ssh-agent.service`

**Issue**: KeePassXC can't find agent
- **Cause**: `SSH_AUTH_SOCK` not visible to KeePassXC
- **Fix**: Restart KeePassXC after setting environment variable

## Performance

### Resource Usage

Typical ssh-agent resource usage:
- **Memory**: ~2-5 MB RSS
- **CPU**: 0% when idle
- **Startup time**: <100ms

### Scalability

- Can handle hundreds of keys
- Socket I/O is very fast (Unix domain sockets)
- No network overhead (local only)

## Compatibility

### Tested Distributions

- Arch Linux
- CachyOS
- Manjaro
- EndeavourOS
- Artix (with systemd)

### Requirements

- systemd user services support
- Bash 4.0+
- OpenSSH 7.0+
- KeePassXC 2.6.0+

### Desktop Environments

Works with:
- KDE Plasma
- GNOME (alternative: use GNOME Keyring)
- XFCE
- i3/Sway
- Any systemd-based DE

## References

- [SSH Agent Protocol (RFC 4251)](https://datatracker.ietf.org/doc/html/rfc4251)
- [systemd.service(5)](https://www.freedesktop.org/software/systemd/man/systemd.service.html)
- [ssh-agent(1)](https://man.openbsd.org/ssh-agent.1)
- [KeePassXC SSH Agent Documentation](https://keepassxc.org/docs/)
- [Arch Wiki: systemd/User](https://wiki.archlinux.org/title/Systemd/User)
