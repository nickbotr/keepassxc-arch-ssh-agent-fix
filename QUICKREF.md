# KeePassXC SSH Agent - Quick Reference

## Installation

```bash
chmod +x keepassxc-ssh-setup.sh
./keepassxc-ssh-setup.sh
```

Choose option 1, restart terminal, restart KeePassXC.

## Essential Commands

### Service Management
```bash
# Check if running
systemctl --user status ssh-agent.service

# Start service
systemctl --user start ssh-agent.service

# Restart service
systemctl --user restart ssh-agent.service

# Enable autostart
systemctl --user enable ssh-agent.service

# View logs
journalctl --user -u ssh-agent.service -f
```

### Agent Operations
```bash
# Check environment variable
echo $SSH_AUTH_SOCK

# List loaded keys
ssh-add -l

# Remove all keys from agent
ssh-add -D

# Test SSH connection (with verbose output)
ssh -vvv user@host
```

### Troubleshooting
```bash
# Kill all ssh-agent processes
pkill ssh-agent

# Restart service
systemctl --user restart ssh-agent.service

# Reload shell config
source ~/.bashrc  # or ~/.zshrc

# Check if socket exists
ls -l $SSH_AUTH_SOCK
```

## KeePassXC Setup

### Enable SSH Agent
1. Tools → Settings (Ctrl+,)
2. SSH Agent → ✓ Enable SSH Agent integration
3. OK

### Add SSH Key to Entry
1. Edit entry → Advanced tab
2. Add attachment (your private key file)
3. SSH Agent tab
4. Private key → Attachment → Select your key
5. Save

### Load Key
- Right-click entry → SSH Agent → Add key to agent
- Or: Ctrl+H

## File Locations

```
~/.config/systemd/user/ssh-agent.service    # Service definition
~/.bashrc or ~/.zshrc                       # SSH_AUTH_SOCK export
$XDG_RUNTIME_DIR/ssh-agent.socket           # Socket (usually /run/user/1000/ssh-agent.socket)
```

## Expected Output

### Working Setup
```bash
$ echo $SSH_AUTH_SOCK
/run/user/1000/ssh-agent.socket

$ systemctl --user status ssh-agent.service
● ssh-agent.service - SSH key agent
   Active: active (running)

$ ssh-add -l
256 SHA256:abc123... user@host (ED25519)
```

### Common Errors
```bash
# Error: Could not open a connection to your authentication agent
# Fix: Start the service
systemctl --user start ssh-agent.service

# Error: SSH_AUTH_SOCK not set
# Fix: Source shell config or restart terminal
source ~/.bashrc
```

## Security Best Practices

- ✅ Use strong KeePassXC master password
- ✅ Enable "Require user confirmation" for sensitive keys
- ✅ Set key lifetime limits in KeePassXC
- ✅ Lock KeePassXC when not in use
- ✅ Keep private keys only in encrypted database
- ❌ Don't leave unencrypted private keys on disk
- ❌ Don't share your KeePassXC database

## Uninstall

```bash
systemctl --user stop ssh-agent.service
systemctl --user disable ssh-agent.service
rm ~/.config/systemd/user/ssh-agent.service
systemctl --user daemon-reload

# Edit ~/.bashrc or ~/.zshrc and remove SSH_AUTH_SOCK lines
```

## Quick Diagnosis

```bash
# Run all checks
echo "=== Environment ==="
echo "SSH_AUTH_SOCK: $SSH_AUTH_SOCK"
echo ""
echo "=== Socket ==="
ls -l $SSH_AUTH_SOCK
echo ""
echo "=== Service ==="
systemctl --user status ssh-agent.service --no-pager
echo ""
echo "=== Keys ==="
ssh-add -l
```

## Links

- Script: `./keepassxc-ssh-setup.sh`
- README: `./README.md`
- Docs: `./DOCUMENTATION.md`
- KeePassXC: https://keepassxc.org/
