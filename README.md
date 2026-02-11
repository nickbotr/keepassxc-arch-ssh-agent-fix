# KeePassXC SSH Agent Setup for Arch Linux

A simple interactive script to configure SSH agent integration with KeePassXC on Arch-based distributions (Arch, CachyOS, Manjaro, EndeavourOS, etc.).

## The Problem

KeePassXC can manage your SSH keys, but setting it up properly requires:
- Configuring an SSH agent with a consistent socket path
- Setting the `SSH_AUTH_SOCK` environment variable correctly
- Preventing multiple agent instances from conflicting
- Ensuring the agent starts automatically on login

This script automates all of that.

## Features

✨ **Automated Setup** - Interactive menu guides you through configuration  
🔒 **Single Agent Instance** - Prevents multiple ssh-agent processes from conflicting  
🚀 **Auto-start on Login** - Systemd service starts automatically  
🔧 **Multiple Setup Options** - Choose systemd service, GNOME Keyring, or manual setup  
✅ **System Verification** - Checks current SSH agent status before setup  

## Requirements

- Arch Linux or Arch-based distribution
- KeePassXC installed
- systemd (standard on Arch)
- Bash shell

## Quick Start

```bash
# Download the script
curl -O https://raw.githubusercontent.com/YOUR_USERNAME/keepassxc-ssh-setup/main/keepassxc-ssh-setup.sh

# Make it executable
chmod +x keepassxc-ssh-setup.sh

# Run it
./keepassxc-ssh-setup.sh
```

## Usage

Run the script and choose option 1 (recommended):

```bash
./keepassxc-ssh-setup.sh
```

**Option 1: Systemd User Service (Recommended)**
- Creates `~/.config/systemd/user/ssh-agent.service`
- Configures automatic startup
- Sets `SSH_AUTH_SOCK` in your shell config
- Ensures only one agent runs at a time

**Option 2: GNOME Keyring**
- For GNOME desktop users
- Uses existing GNOME Keyring SSH agent

**Option 3: Manual Setup**
- Shows step-by-step instructions
- For those who prefer to configure manually

**Option 4: KeePassXC Configuration Guide**
- Instructions for enabling SSH agent in KeePassXC
- How to add SSH keys to your database

## After Running the Script

1. **Restart your terminal** or run:
   ```bash
   source ~/.bashrc  # or ~/.zshrc
   ```

2. **Restart KeePassXC**

3. **Enable SSH Agent in KeePassXC:**
   - Open KeePassXC
   - Go to: Tools → Settings (Ctrl+,)
   - Click "SSH Agent" in left sidebar
   - Check ✓ "Enable SSH Agent integration"
   - Click OK

4. **Add SSH keys to your database:**
   - Create or edit an entry
   - Go to "Advanced" tab → Attach your private key file
   - Go to "SSH Agent" tab
   - Under "Private key", select "Attachment" and choose your key
   - Save the entry
   - Right-click entry → SSH Agent → Add key to agent (Ctrl+H)

## Verification

Check if everything is working:

```bash
# Check if SSH_AUTH_SOCK is set
echo $SSH_AUTH_SOCK
# Should show: /run/user/1000/ssh-agent.socket

# Check systemd service status
systemctl --user status ssh-agent.service
# Should show: active (running)

# List loaded SSH keys
ssh-add -l
# Should list keys from KeePassXC
```

## How It Works

The script:
1. Creates a systemd user service that runs `ssh-agent` persistently
2. Sets up a consistent socket path at `$XDG_RUNTIME_DIR/ssh-agent.socket`
3. Exports `SSH_AUTH_SOCK` in your shell config
4. Prevents multiple agent instances through systemd and socket cleanup
5. Enables automatic startup via systemd's `default.target`

KeePassXC then connects to this agent via the `SSH_AUTH_SOCK` environment variable.

## Troubleshooting

**KeePassXC says "SSH Agent integration is not available"**
- Make sure `SSH_AUTH_SOCK` is set: `echo $SSH_AUTH_SOCK`
- Restart your terminal and KeePassXC
- Check service status: `systemctl --user status ssh-agent.service`

**ssh-add -l shows "Could not open a connection to your authentication agent"**
- Verify SSH_AUTH_SOCK: `echo $SSH_AUTH_SOCK`
- Check if socket exists: `ls -l $SSH_AUTH_SOCK`
- Restart the service: `systemctl --user restart ssh-agent.service`

**Multiple ssh-agent processes running**
- Stop all agents: `pkill ssh-agent`
- Restart the systemd service: `systemctl --user restart ssh-agent.service`

**Keys not loading from KeePassXC**
- Ensure SSH Agent is enabled in KeePassXC settings
- Check that your key is attached to the database entry
- Verify the "SSH Agent" tab is configured correctly in the entry

## Uninstall

To remove the setup:

```bash
# Stop and disable the service
systemctl --user stop ssh-agent.service
systemctl --user disable ssh-agent.service

# Remove the service file
rm ~/.config/systemd/user/ssh-agent.service

# Remove from shell config (edit manually)
nano ~/.bashrc  # or ~/.zshrc
# Delete the SSH_AUTH_SOCK lines

# Reload systemd
systemctl --user daemon-reload
```

## Contributing

Issues and pull requests welcome! If you encounter problems on specific distributions, please open an issue.

## License

MIT License - feel free to use and modify as needed.

## Credits

Inspired by the need for better SSH key management with KeePassXC on Arch Linux.

## See Also

- [KeePassXC Documentation](https://keepassxc.org/docs/)
- [KeePassXC SSH Agent Guide](https://keepassxc.org/docs/KeePassXC_GettingStarted.html#_ssh_agent)
- [Arch Wiki: SSH Keys](https://wiki.archlinux.org/title/SSH_keys)
- [Arch Wiki: KeePassXC](https://wiki.archlinux.org/title/KeePassXC)
