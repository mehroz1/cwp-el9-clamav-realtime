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
