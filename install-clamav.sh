#!/bin/bash

set -e

echo "Installing ClamAV..."
dnf install -y clamav\* clamd

echo "Updating virus definitions..."
freshclam

echo "Enabling services..."
systemctl enable clamd@scan
systemctl enable freshclam

echo "Fixing clamd configuration..."

CONFIG="/etc/clamd.d/scan.conf"

# Step 2: Comment out Example line
sed -i 's/^Example/#Example/' "$CONFIG"

# Ensure LocalSocket is set
if ! grep -q "^LocalSocket " "$CONFIG"; then
    echo "LocalSocket /run/clamd.scan/clamd.sock" >> "$CONFIG"
else
    sed -i 's|^#\?LocalSocket .*|LocalSocket /run/clamd.scan/clamd.sock|' "$CONFIG"
fi

# Step 3: Set socket mode
if ! grep -q "^LocalSocketMode" "$CONFIG"; then
    echo "LocalSocketMode 666" >> "$CONFIG"
else
    sed -i 's/^#\?LocalSocketMode.*/LocalSocketMode 666/' "$CONFIG"
fi

# Step 4: Create runtime directory
mkdir -p /run/clamd.scan
chown clamscan:clamscan /run/clamd.scan

# Create log directory BEFORE cron
mkdir -p /var/log/clamav
chown clamscan:clamscan /var/log/clamav
chmod 755 /var/log/clamav

# Step 5: Reload + restart
systemctl daemon-reexec
systemctl restart clamd@scan

echo "Setting up cron job safely..."

CRON_JOB='0 2 * * * clamscan -r /home --log=/var/log/clamav/daily.log'

# Preserve existing crontab and append only if not already present
(crontab -l 2>/dev/null | grep -F "$CRON_JOB") || \
(crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -

echo "Final service status:"
systemctl status clamd@scan --no-pager

echo "Done."
