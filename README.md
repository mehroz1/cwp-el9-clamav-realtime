# Clamav Installation for Control Web Panel (CWP) for el9

# 🛡️ clam-auto.sh
Automated ClamAV Deployment + Real-Time Protection for EL9 (CWP Ready)

![EL9](https://img.shields.io/badge/EL9-Compatible-blue)
![ClamAV](https://img.shields.io/badge/ClamAV-Automated-green)
![Systemd](https://img.shields.io/badge/Systemd-Enabled-orange)
![SELinux](https://img.shields.io/badge/SELinux-Supported-red)
![License](https://img.shields.io/badge/License-Free-lightgrey)

---

## 📌 Overview

clam-auto.sh is a fully automated ClamAV deployment script for Enterprise Linux 9 (EL9), optimized for Control Web Panel (CWP).

It provides:
- Real-time antivirus (inotify-based)
- Automatic updates (freshclam)
- Smart configuration fixes
- Quarantine system
- Daily scans
- Self-healing services

---

## 🖥️ Compatibility

- AlmaLinux 9 ✅
- Rocky Linux 9 ✅
- RHEL 9 ✅
- EL8 / EL7 ❌

---

## 📦 Installation

```bash
git clone https://github.com/yourusername/clam-auto.git
cd clam-auto
chmod +x clam-auto.sh
sudo ./clam-auto.sh
```
## ⚙️ What It Does

### 📦 Installs
- ClamAV
- clamav-server-systemd
- clamav-update
- inotify-tools
- SELinux utilities

---

### 🔧 Configures
- /etc/clamd.d/scan.conf
- Runtime directories
- Permissions + SELinux contexts

---

### 🔄 Enables Services
- clamd@scan
- clamav-freshclam
- clamav-inotify

---

## 👀 Real-Time Protection

- **Watches:** /home

### Detects:
- File create
- Modify
- Move

### Skips:
- Cache/temp directories
- Files larger than 50MB

---

### 🦠 On Virus Detection

- File moved to:
```
  /var/quarantine
```  
- Logged in:
```
  /var/log/clamav/inotify.log
```

---

## 📅 Daily Scan

Runs every day at **2 AM**:
```
0 2 * * * clamscan -r /home --log=/var/log/clamav/daily.log
```
---

## 📂 Important Paths

- /etc/clamd.d/scan.conf
- /usr/local/bin/clamav-inotify.sh
- /etc/systemd/system/clamav-inotify.service
- /var/quarantine

---

## 🧾 Logs

- /var/log/clamav/setup.log
- /var/log/clamav/inotify.log
- /var/log/clamav/daily.log

---

## 🧪 Health Check

The script ensures:

- clamd@scan is running
- freshclam is running
- real-time scanner is running

If not → services are automatically restarted.

---

## 🔍 Troubleshooting

### Check services:
```
systemctl status clamd@scan
systemctl status clamav-freshclam
systemctl status clamav-inotify
```
### View logs:
```
tail -f /var/log/clamav/setup.log
```
---

## ⚠️ Notes

- EL9 only
- Requires root privileges
- Safe to re-run
- Large files are skipped in real-time scanning

---

## 📜 License

Free to use, modify, and distribute.

---

## ⭐ Support

If this helped:

- Star the repo
- Fork it
- Report issues
