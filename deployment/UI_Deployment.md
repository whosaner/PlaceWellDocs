# PlaceWell UI · Linode Deployment Guide

**Server:** `45.56.71.137` (AlmaLinux 9) — same server as the QR Service
**URL:** `https://placewell.app/ui`
**Auth:** HTTP Basic Auth (username + password via Apache)
**Internal port:** 8080 (localhost only — Apache proxies to it)

---

## Overview

The UI runs alongside the existing QR Service on the same Linode server:

| Service | Internal Port | Public URL |
|---|---|---|
| QR Service | 8000 | `https://placewell.app/api/qr/*` and `/s/*` |
| PlaceWell UI | 8080 | `https://placewell.app/ui` |

Both are reverse-proxied through the same Apache HTTPS config.

---

## Part 1 — Copy Files to the Server

### Step 1 — Create the project directory on the server

SSH into the server:

```
ssh root@45.56.71.137
```

Create the directory:

```bash
mkdir -p /opt/placewell-ui/output
```

### Step 2 — Copy project files from Windows

Open a **new Command Prompt on your Windows machine**:

```
scp -r C:\PlaceWellUI\app root@45.56.71.137:/opt/placewell-ui/
scp -r C:\PlaceWellUI\data root@45.56.71.137:/opt/placewell-ui/
scp C:\PlaceWellUI\requirements.txt root@45.56.71.137:/opt/placewell-ui/
scp C:\PlaceWellUI\.env.example root@45.56.71.137:/opt/placewell-ui/
```

### Step 3 — Verify files arrived

On the server:

```bash
ls -la /opt/placewell-ui/
```

You should see: `app/`, `data/`, `output/`, `requirements.txt`, `.env.example`

---

## Part 2 — Set Up the Python Environment

### Step 4 — Create virtual environment and install dependencies

```bash
cd /opt/placewell-ui
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
deactivate
```

---

## Part 3 — Configure Environment Variables

### Step 5 — Create the .env file

```bash
cp /opt/placewell-ui/.env.example /opt/placewell-ui/.env
nano /opt/placewell-ui/.env
```

Fill in the values:

```
USERNAME_PREFIX=hussain
QR_SERVICE_URL=http://127.0.0.1:8000
QR_ALLOCATE_SECRET=<same value as PLACEWELL_ALLOCATE_SECRET in /opt/placewell-service/.env>
PDF_GENERATOR_PATH=/opt/placewell-ui/placewell_generator
PDF_OUTPUT_DIR=/opt/placewell-ui/output
```

To get the QR allocate secret:

```bash
grep PLACEWELL_ALLOCATE_SECRET /opt/placewell-service/.env
```

Copy that value into the UI's `.env` as `QR_ALLOCATE_SECRET`.

Press `Ctrl + X`, then `Y`, then `Enter` to save.

### Step 6 — Set file permissions

```bash
chmod 600 /opt/placewell-ui/.env
chmod 755 /opt/placewell-ui
chmod 755 /opt/placewell-ui/app
```

---

## Part 4 — Test the Service Starts

### Step 7 — Manual test run

```bash
cd /opt/placewell-ui
source .venv/bin/activate
uvicorn app.main:app --host 127.0.0.1 --port 8080
```

You should see:

```
INFO:     Application startup complete.
INFO:     Uvicorn running on http://127.0.0.1:8080
```

Test it responds:

```bash
curl http://127.0.0.1:8080/health
```

You should see: `{"status":"ok","service":"placewell-ui"}`

Press `Ctrl + C` to stop, then:

```bash
deactivate
```

---

## Part 5 — Create the systemd Service

### Step 8 — Create the service file

```bash
nano /etc/systemd/system/placewell-ui.service
```

Paste the following exactly:

```ini
[Unit]
Description=PlaceWell UI
After=network.target placewell.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/placewell-ui
EnvironmentFile=/opt/placewell-ui/.env
ExecStart=/opt/placewell-ui/.venv/bin/uvicorn app.main:app --host 127.0.0.1 --port 8080 --workers 2
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

Press `Ctrl + X`, then `Y`, then `Enter` to save.

### Step 9 — Enable and start the service

```bash
systemctl daemon-reload
systemctl enable placewell-ui --now
```

Verify it is running:

```bash
systemctl status placewell-ui | head -8
```

You should see `Active: active (running)`.

Confirm it responds:

```bash
curl http://127.0.0.1:8080/health
```

---

## Part 6 — Set Up Apache Password Protection

### Step 10 — Install Apache utilities (if not already installed)

```bash
dnf install -y httpd-tools
```

### Step 11 — Create the password file

```bash
htpasswd -c /etc/httpd/.htpasswd_placewell_ui hussain
```

You will be prompted to enter and confirm a password. Choose a strong password and save it in your password manager.

> To add more users later:
> ```bash
> htpasswd /etc/httpd/.htpasswd_placewell_ui another_username
> ```
> (Note: no `-c` flag — that would overwrite the file)

### Step 12 — Set permissions on the password file

```bash
chmod 640 /etc/httpd/.htpasswd_placewell_ui
chown root:apache /etc/httpd/.htpasswd_placewell_ui
```

---

## Part 7 — Configure Apache Reverse Proxy

### Step 13 — Edit the Apache HTTPS config

```bash
nano /etc/httpd/conf.d/placewell-le-ssl.conf
```

Find the existing proxy lines for the QR Service (they look like this):

```apache
    ProxyPreserveHost On
    ProxyPass / http://127.0.0.1:8000/
    ProxyPassReverse / http://127.0.0.1:8000/
```

**Replace** those three lines with the following block:

```apache
    ProxyPreserveHost On

    # PlaceWell UI — password-protected operator interface on port 8080
    <Location /ui>
        AuthType Basic
        AuthName "PlaceWell Operator"
        AuthUserFile /etc/httpd/.htpasswd_placewell_ui
        Require valid-user

        ProxyPass http://127.0.0.1:8080/
        ProxyPassReverse http://127.0.0.1:8080/
    </Location>

    # Static files for the UI (CSS, JS) — also password-protected
    <Location /static>
        AuthType Basic
        AuthName "PlaceWell Operator"
        AuthUserFile /etc/httpd/.htpasswd_placewell_ui
        Require valid-user

        ProxyPass http://127.0.0.1:8080/static
        ProxyPassReverse http://127.0.0.1:8080/static
    </Location>

    # PDF downloads — also password-protected
    <Location /download>
        AuthType Basic
        AuthName "PlaceWell Operator"
        AuthUserFile /etc/httpd/.htpasswd_placewell_ui
        Require valid-user

        ProxyPass http://127.0.0.1:8080/download
        ProxyPassReverse http://127.0.0.1:8080/download
    </Location>

    # QR Service — public endpoints (no auth)
    ProxyPass /api/qr http://127.0.0.1:8000/api/qr
    ProxyPassReverse /api/qr http://127.0.0.1:8000/api/qr

    ProxyPass /s/ http://127.0.0.1:8000/s/
    ProxyPassReverse /s/ http://127.0.0.1:8000/s/

    ProxyPass /health http://127.0.0.1:8000/health
    ProxyPassReverse /health http://127.0.0.1:8000/health

    ProxyPass /docs http://127.0.0.1:8000/docs
    ProxyPassReverse /docs http://127.0.0.1:8000/docs

    ProxyPass /openapi.json http://127.0.0.1:8000/openapi.json
    ProxyPassReverse /openapi.json http://127.0.0.1:8000/openapi.json
```

Press `Ctrl + X`, then `Y`, then `Enter` to save.

### Step 14 — Test and restart Apache

```bash
httpd -t
```

You must see `Syntax OK`. Then:

```bash
systemctl restart httpd
```

---

## Part 8 — Verify the Full Deployment

### Step 15 — Test the UI loads

Open your browser and go to:

```
https://placewell.app/ui
```

You should be prompted for a username and password. Enter the credentials you set in Step 11. The order form should load.

### Step 16 — Test the QR Service still works

```
https://placewell.app/health
```

Should return `{"status":"ok"}` — no password required.

### Step 17 — Test the API docs still work

```
https://placewell.app/docs
```

Should show the FastAPI interactive docs — no password required.

---

## Deploying Code Updates

### Update UI code

On your Windows machine:

```
scp -r C:\PlaceWellUI\app\* root@45.56.71.137:/opt/placewell-ui/app/
```

On the server:

```bash
systemctl restart placewell-ui
systemctl status placewell-ui | head -5
```

### Update CSV data (e.g., add/remove spice names)

```
scp C:\PlaceWellUI\data\spice.csv root@45.56.71.137:/opt/placewell-ui/data/
```

No restart needed — CSV is read on each form submission.

---

## Useful Commands

```bash
# View UI service logs
journalctl -u placewell-ui -f

# View QR service logs (for comparison)
journalctl -u placewell -f

# Restart both services
systemctl restart placewell placewell-ui

# Check both services
systemctl status placewell placewell-ui

# Change UI password
htpasswd /etc/httpd/.htpasswd_placewell_ui hussain

# Add another user
htpasswd /etc/httpd/.htpasswd_placewell_ui newuser
```

---

## Server File Locations

| File / Directory | Purpose |
|---|---|
| `/opt/placewell-ui/` | UI project root |
| `/opt/placewell-ui/app/` | FastAPI application code |
| `/opt/placewell-ui/data/spice.csv` | Spice item names |
| `/opt/placewell-ui/output/` | Generated PDFs |
| `/opt/placewell-ui/.env` | Environment variables |
| `/etc/systemd/system/placewell-ui.service` | systemd service |
| `/etc/httpd/.htpasswd_placewell_ui` | Apache password file |
| `/etc/httpd/conf.d/placewell-le-ssl.conf` | Apache HTTPS config (shared with QR Service) |
