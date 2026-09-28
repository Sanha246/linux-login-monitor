# 🔐 Linux Login Activity Monitor

![Linux Login Activity Monitor](./login-monitor-banner.png)

A Bash-based cybersecurity project that monitors SSH login activity on a Linux system. It analyzes successful and failed login attempts, identifies source IP addresses, checks failed-login IP locations, generates security reports, and provides security alerts.

---

## 📌 Features

### 1. Show Login Summary

* Displays the current user and system information.
* Shows successful and failed SSH login attempts.
* Displays the configured security alert threshold.

### 2. Show Successful Logins

* Displays successful SSH login attempts.
* Uses `journalctl` to analyze SSH authentication logs.

### 3. Show Failed Logins

* Displays failed SSH login attempts.
* Helps identify suspicious authentication activity.

### 4. Show Source IP Addresses

* Extracts IP addresses associated with SSH login attempts.
* Counts repeated source addresses.

### 5. Show Failed IP Locations

* Identifies public IP addresses associated with failed SSH login attempts.
* Attempts to display country, region, and city information.
* Ignores local addresses such as `::1`.

### 6. Generate Security Report

Generates a security report containing:

* System information
* Login statistics
* Security status
* Failed-login information

### 7. Security Alert Check

* Checks the number of failed SSH login attempts.
* Displays a security alert when the configured threshold is reached.

### 8. Exit

Safely exits the monitoring program.

---

## 🛠️ Technologies Used

* **Bash Shell Scripting**
* **Linux**
* **SSH / OpenSSH**
* **systemd Journal (`journalctl`)**
* **AWK**
* **grep**
* **sort**
* **uniq**
* **Linux authentication logs**

---

## 💻 Requirements

Before running the project, make sure you have:

* Linux system
* Bash
* OpenSSH / SSH logs
* systemd / `journalctl`
* `sudo` privileges for accessing SSH journal logs
* Internet connection for public IP geolocation features

The project can also be tested inside a Linux virtual machine such as **Kali Linux** or **Ubuntu**.

---

## 🚀 Installation

### 1. Clone the repository

```bash
git clone https://github.com/YOUR-USERNAME/YOUR-REPOSITORY.git
```

### 2. Enter the project directory

```bash
cd YOUR-REPOSITORY
```

### 3. Give execute permission

```bash
chmod +x login-monitor.sh
```

### 4. Run the program

```bash
sudo ./login-monitor.sh
```

---

## 📋 Main Menu

When the program starts, it provides the following options:

```text
=== Linux Login Activity Monitor ===

1. Show Login Summary
2. Show Successful Logins
3. Show Failed Logins
4. Show Source IP Addresses
5. Show Failed IP Locations
6. Generate Security Report
7. Security Alert Check
8. Exit

Enter your choice (1-8):
```

---

## 📊 Example Output

### Login Summary

```text
=== Login Summary ===

Current User       : kali
System Info        : Linux
Successful Logins : 12
Failed Logins     : 3
Alert Threshold    : 5
```

### Successful Logins

```text
=== Successful SSH Logins ===

Time                 User       Source IP
2025-09-20 10:12:34  kali       192.168.1.10
2025-09-20 11:03:21  root       203.0.113.45
2025-09-20 12:45:17  kali       192.168.1.15
```

### Failed Logins

```text
=== Failed SSH Logins ===

Time                 User       Source IP
2025-09-20 09:45:12  root       185.199.110.24
2025-09-20 10:23:47  admin      45.77.32.18
2025-09-20 11:02:13  test       93.184.216.34
```

### Failed IP Locations

```text
=== Failed IP Locations ===

IP Address       Country         Region       City
185.199.110.24   United States   California   San Jose
45.77.32.18      Russia          Moscow       Moscow
93.184.216.34    United States   California   Los Angeles
```

---

## 🚨 Security Alert

The program checks failed SSH login attempts against the configured threshold.

Example:

```text
=== Security Alert Check ===

⚠ SECURITY ALERT: 7 failed login attempts detected!
(Threshold: 5)
```

---

## 📄 Security Report

The security report contains:

```text
System Information
        ↓
Login Statistics
        ↓
Successful Login Activity
        ↓
Failed Login Activity
        ↓
Source IP Information
        ↓
Security Status
```

---

## 🔒 Security Purpose

This project demonstrates how Linux authentication logs can be analyzed to monitor SSH activity and identify potentially suspicious login behavior.

It is intended for **educational and cybersecurity learning purposes**.

---

## 📁 Project Structure

```text
Linux-Login-Activity-Monitor/
│
├── login-monitor.sh
├── README.md
└── login-monitor-banner.png
```

---

## 🎯 Learning Objectives

Through this project, you can learn:

* Bash scripting
* Linux command-line tools
* SSH security monitoring
* Log analysis
* IP address extraction
* Basic security alerting
* `journalctl` usage
* Text processing with AWK, grep, sort and uniq
* Basic cybersecurity monitoring concepts

---

## 👨‍💻 Project

**Linux Login Activity Monitor**

**Technology:** Bash + Linux + SSH

**Purpose:** SSH Login Monitoring & Security Analysis

---

### 🔐 Stay Secure • Monitor • Prevent
