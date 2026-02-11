#!/bin/bash
# KeePassXC SSH Agent Setup for Arch/CachyOS
# Based on: https://wiki.archlinux.org/title/SSH_keys#SSH_agents

set -e

echo "=== KeePassXC SSH Agent Setup Helper ==="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check current state
echo "Step 1: Checking current SSH agent status..."
echo ""

if [ -n "$SSH_AUTH_SOCK" ]; then
    echo -e "${GREEN}✓ SSH_AUTH_SOCK is set:${NC} $SSH_AUTH_SOCK"
    if [ -S "$SSH_AUTH_SOCK" ]; then
        echo -e "${GREEN}✓ Socket exists and is valid${NC}"
    else
        echo -e "${RED}✗ Socket doesn't exist at this path${NC}"
    fi
else
    echo -e "${RED}✗ SSH_AUTH_SOCK is not set${NC}"
fi

echo ""
echo "Running ssh-add -l to check agent connection..."
if ssh-add -l 2>&1 | grep -q "Could not open"; then
    echo -e "${RED}✗ Cannot connect to SSH agent${NC}"
    NEEDS_SETUP=true
elif ssh-add -l 2>&1 | grep -q "no identities"; then
    echo -e "${YELLOW}⚠ Agent running but no keys loaded${NC}"
    NEEDS_SETUP=false
else
    echo -e "${GREEN}✓ SSH agent is working${NC}"
    ssh-add -l
    NEEDS_SETUP=false
fi

echo ""
echo "=== Setup Options ==="
echo ""
echo "KeePassXC needs SSH_AUTH_SOCK to point to a running ssh-agent."
echo "Choose your setup method:"
echo ""
echo "1) Create systemd user service (recommended - follows Arch wiki)"
echo "2) Use existing GNOME Keyring agent (if using GNOME)"
echo "3) Manual setup instructions only"
echo "4) Check KeePassXC configuration"
echo "5) Exit"
echo ""

read -p "Enter choice [1-5]: " choice

case $choice in
    1)
        echo ""
        echo "=== Setting up systemd user service for ssh-agent ==="
        echo "Following: https://wiki.archlinux.org/title/SSH_keys#Start_ssh-agent_with_systemd_user"
        echo ""
        
        # Create systemd user directory
        mkdir -p ~/.config/systemd/user
        
        # Create the service file (simple version from Arch wiki)
        cat > ~/.config/systemd/user/ssh-agent.service << 'EOF'
[Unit]
Description=SSH key agent

[Service]
Type=simple
Environment=SSH_AUTH_SOCK=%t/ssh-agent.socket
ExecStart=/usr/bin/ssh-agent -D -a $SSH_AUTH_SOCK

[Install]
WantedBy=default.target
EOF
        
        echo -e "${GREEN}✓ Created ~/.config/systemd/user/ssh-agent.service${NC}"
        
        # Create environment.d config (recommended method)
        mkdir -p ~/.config/environment.d
        cat > ~/.config/environment.d/ssh_auth_socket.conf << 'EOF'
SSH_AUTH_SOCK="${XDG_RUNTIME_DIR}/ssh-agent.socket"
EOF
        
        echo -e "${GREEN}✓ Created ~/.config/environment.d/ssh_auth_socket.conf${NC}"
        
        # Reload systemd
        systemctl --user daemon-reload
        
        # Enable and start the service
        systemctl --user enable ssh-agent.service
        systemctl --user start ssh-agent.service
        
        echo -e "${GREEN}✓ Service enabled and started${NC}"
        
        # Set for current session
        export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR}/ssh-agent.socket"
        
        echo ""
        echo -e "${GREEN}Setup complete!${NC}"
        echo ""
        echo "What this does:"
        echo "- Creates a systemd user service that starts ssh-agent automatically"
        echo "- ssh-agent runs with -D flag (stays in foreground for systemd)"
        echo "- Only ONE instance will run (systemd manages this)"
        echo "- Starts automatically on login (WantedBy=default.target)"
        echo "- SSH_AUTH_SOCK points to: \$XDG_RUNTIME_DIR/ssh-agent.socket"
        echo ""
        echo "Next steps:"
        echo "1. Log out and log back in (for environment.d to take effect)"
        echo "   OR restart your terminal and run: export SSH_AUTH_SOCK=\"\${XDG_RUNTIME_DIR}/ssh-agent.socket\""
        echo "2. Restart KeePassXC"
        echo "3. In KeePassXC: Tools → Settings → SSH Agent → Enable SSH Agent"
        echo "4. Add your SSH keys to KeePassXC database entries"
        echo ""
        echo "To verify:"
        echo "  systemctl --user status ssh-agent.service"
        echo "  echo \$SSH_AUTH_SOCK"
        echo "  ssh-add -l"
        ;;
        
    2)
        echo ""
        echo "=== Setting up GNOME Keyring SSH agent (gcr-ssh-agent) ==="
        echo ""
        
        # Enable gcr-ssh-agent socket
        systemctl --user enable gcr-ssh-agent.socket
        systemctl --user start gcr-ssh-agent.socket
        
        # Create environment.d config
        mkdir -p ~/.config/environment.d
        cat > ~/.config/environment.d/ssh_auth_socket.conf << 'EOF'
SSH_AUTH_SOCK="${XDG_RUNTIME_DIR}/gcr/ssh"
EOF
        
        echo -e "${GREEN}✓ GNOME Keyring SSH agent configured${NC}"
        echo ""
        echo "Please log out and log back in for changes to take effect."
        echo "Then restart KeePassXC and enable SSH Agent in settings."
        ;;
        
    3)
        echo ""
        echo "=== Manual Setup Instructions ==="
        echo "Reference: https://wiki.archlinux.org/title/SSH_keys#Start_ssh-agent_with_systemd_user"
        echo ""
        echo "1. Create systemd service file:"
        echo "   mkdir -p ~/.config/systemd/user"
        echo "   nano ~/.config/systemd/user/ssh-agent.service"
        echo ""
        echo "   Paste this content:"
        cat << 'EOF'
[Unit]
Description=SSH key agent

[Service]
Type=simple
Environment=SSH_AUTH_SOCK=%t/ssh-agent.socket
ExecStart=/usr/bin/ssh-agent -D -a $SSH_AUTH_SOCK

[Install]
WantedBy=default.target
EOF
        echo ""
        echo "2. Create environment variable config:"
        echo "   mkdir -p ~/.config/environment.d"
        echo "   echo 'SSH_AUTH_SOCK=\"\${XDG_RUNTIME_DIR}/ssh-agent.socket\"' > ~/.config/environment.d/ssh_auth_socket.conf"
        echo ""
        echo "3. Reload and enable:"
        echo "   systemctl --user daemon-reload"
        echo "   systemctl --user enable --now ssh-agent.service"
        echo ""
        echo "4. Log out and log back in (or restart your session)"
        echo "5. Restart KeePassXC"
        echo ""
        echo "Why this works:"
        echo "- systemd ensures only one ssh-agent runs"
        echo "- 'enable' makes it start automatically on login"
        echo "- environment.d sets SSH_AUTH_SOCK globally"
        ;;
        
    4)
        echo ""
        echo "=== KeePassXC Configuration Check ==="
        echo ""
        echo "To enable SSH Agent in KeePassXC:"
        echo "1. Open KeePassXC"
        echo "2. Go to: Tools → Settings (or press Ctrl+,)"
        echo "3. Click on 'SSH Agent' in the left sidebar"
        echo "4. Check ✓ 'Enable SSH Agent integration'"
        echo "5. Click OK and restart KeePassXC"
        echo ""
        echo "To add an SSH key to your database:"
        echo "1. Create or edit an entry"
        echo "2. Go to the 'Advanced' tab"
        echo "3. Add your private key file as an attachment"
        echo "4. Go to the 'SSH Agent' tab"
        echo "5. Under 'Private key', select 'Attachment'"
        echo "6. Choose your key file from the dropdown"
        echo "7. Optionally set 'Require user confirmation' or lifetime"
        echo "8. Save the entry"
        echo ""
        echo "To load the key:"
        echo "- Right-click the entry → SSH Agent → Add key to agent"
        echo "- Or use keyboard shortcut: Ctrl+H"
        ;;
        
    5)
        echo "Exiting..."
        exit 0
        ;;
        
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "=== Additional Info ==="
echo ""
echo "The Arch wiki approach is simple and reliable:"
echo "- systemd manages the ssh-agent process (no manual cleanup needed)"
echo "- 'enable' ensures it starts on boot automatically"
echo "- Only one instance runs (systemd handles this)"
echo "- environment.d sets SSH_AUTH_SOCK system-wide"
echo ""
echo "Reference: https://wiki.archlinux.org/title/SSH_keys#SSH_agents"
