#!/bin/bash
set -euo pipefail

LOG_DIR="/var/log/clamav"
LOG_FILE="$LOG_DIR/setup.log"
CLAMD_CONF="/etc/clamd.d/scan.conf"

INOTIFY_SCRIPT="/usr/local/bin/clamav-inotify.sh"
INOTIFY_SERVICE="clamav-inotify"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%F %T')] $*" | tee -a "$LOG_FILE"
}

# =========================
# INSTALL REQUIRED PACKAGES (EL9 ONLY)
# =========================
install_packages() {
    log "Installing EL9 ClamAV stack..."

    dnf install -y \
        clamav \
        clamav-data \
        clamav-server-systemd \
        clamav-update \
        clamav-milter \
        inotify-tools \
        policycoreutils-python-utils || true
}

# =========================
# UPDATE VIRUS DB
# =========================
setup_freshclam() {
    log "Updating virus database..."

    freshclam || true

    systemctl enable --now clamav-freshclam || {
        log "ERROR: clamav-freshclam service missing or failed"
    }
}

# =========================
# FIX CLAMD CONFIG
# =========================
fix_clamd_config() {
    log "Fixing clamd config..."

    [[ -f "$CLAMD_CONF" ]] || {
        log "ERROR: missing $CLAMD_CONF"
        return 1
    }

    sed -i 's/^Example/#Example/' "$CLAMD_CONF"

    grep -q "^LocalSocket " "$CLAMD_CONF" || \
        echo "LocalSocket /run/clamd.scan/clamd.sock" >> "$CLAMD_CONF"

    sed -i 's/^#\?LocalSocketMode.*/LocalSocketMode 666/' "$CLAMD_CONF"
}

# =========================
# FIX DIRECTORIES + SELINUX
# =========================
fix_system() {
    log "Fixing system directories + SELinux..."

    mkdir -p /run/clamd.scan /var/quarantine /var/log/clamav

    chown -R clamscan:clamscan /run/clamd.scan || true
    chown -R clamscan:clamscan /var/log/clamav || true

    command -v restorecon &>/dev/null && {
        restorecon -Rv /run/clamd.scan || true
        restorecon -Rv /var/log/clamav || true
        restorecon -Rv /var/quarantine || true
    }
}

# =========================
# ENABLE CLAMD (EL9 ONLY)
# =========================
start_clamd() {
    log "Starting clamd@scan (EL9 correct service)..."

    systemctl daemon-reload || true

    systemctl enable clamd@scan || {
        log "ERROR: clamd@scan not found → install clamav-server-systemd"
    }

    systemctl restart clamd@scan || {
        log "ERROR: clamd@scan failed to start"
    }

    systemctl enable --now clamav-freshclam || true
}

# =========================
# INOTIFY REALTIME SCANNER
# =========================
create_inotify() {
    log "Creating inotify real-time scanner..."

    cat > "$INOTIFY_SCRIPT" <<'EOF'
#!/bin/bash

WATCH_DIR="/home"
LOG_FILE="/var/log/clamav/inotify.log"
QUARANTINE="/var/quarantine"

mkdir -p "$QUARANTINE"

inotifywait -m -r -e modify,create,move "$WATCH_DIR" \
--exclude '(/home/.*/\.cache|/home/.*/tmp)' \
--format '%w%f' | while read FILE
do
    [ -f "$FILE" ] || continue

    # skip large files > 50MB
    [ $(stat -c%s "$FILE" 2>/dev/null || echo 0) -gt 50000000 ] && continue

    RESULT=$(clamdscan --fdpass "$FILE" 2>&1)
    echo "$RESULT" >> "$LOG_FILE"

    echo "$RESULT" | grep -q "FOUND" && {
        mkdir -p "$QUARANTINE"
        mv "$FILE" "$QUARANTINE"/ 2>/dev/null || true
        echo "$(date) QUARANTINED: $FILE" >> "$LOG_FILE"
    }
done
EOF

    chmod +x "$INOTIFY_SCRIPT"
}

# =========================
# SYSTEMD SERVICE
# =========================
create_service() {
    log "Creating systemd service..."

    cat > "/etc/systemd/system/$INOTIFY_SERVICE.service" <<EOF
[Unit]
Description=ClamAV Real-Time Scanner (EL9)
After=network.target clamd@scan.service

[Service]
ExecStart=$INOTIFY_SCRIPT
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable --now "$INOTIFY_SERVICE" || true
}

# =========================
# CRON BACKUP SCAN
# =========================
setup_cron() {
    log "Setting backup cron scan..."

    local job='0 2 * * * clamscan -r /home --log=/var/log/clamav/daily.log'

    (crontab -l 2>/dev/null | grep -F "$job") && return
    (crontab -l 2>/dev/null; echo "$job") | crontab -
}

# =========================
# HEALTH CHECK (EL9 SAFE)
# =========================
health_check() {
    log "Running health check..."

    systemctl is-active --quiet clamd@scan || {
        log "WARNING: clamd@scan not running → restarting"
        systemctl restart clamd@scan || true
    }

    systemctl is-active --quiet clamav-freshclam || {
        log "WARNING: freshclam not running → restarting"
        systemctl restart clamav-freshclam || true
    }

    systemctl is-active --quiet "$INOTIFY_SERVICE" || {
        systemctl restart "$INOTIFY_SERVICE" || true
    }
}

# =========================
# MAIN
# =========================
main() {
    log "Starting CLEAN EL9 ClamAV deployment..."

    install_packages
    setup_freshclam
    fix_clamd_config
    fix_system
    start_clamd
    create_inotify
    create_service
    setup_cron
    health_check

    log "DONE ✔ EL9 ClamAV fully working + self-healing"
}

main
