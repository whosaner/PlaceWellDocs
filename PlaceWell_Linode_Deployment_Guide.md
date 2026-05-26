# PlaceWell · Linode Deployment Guide

**OS:** AlmaLinux 9
**Web server:** Apache 2.4
**Goal:** Deploy the PlaceWell FastAPI service behind Apache on placewell.app with HTTPS

---

## Overview

The deployment has six parts:

1. Provision a new Linode server (AlmaLinux 9)
2. Point `placewell.app` DNS to the server
3. Install Apache and configure the firewall
4. Set up the FastAPI service
5. Configure Apache as a reverse proxy
6. Install a free SSL certificate via Let's Encrypt

---

## Part 1 — Provision the Linode Server

### Step 1 — Create the Linode

1. Log into your Linode account
2. Click **"Create Linode"**
3. Select the following:
   - **Image:** AlmaLinux 9
   - **Plan:** Shared CPU — $5/month
   - **Region:** Same as your existing Linode
   - **Root password:** Set a strong password and save it in a password manager
   - **Firewall:** Skip — we configure this on the server directly
4. Click **"Create Linode"**
5. Wait for status to show **"Running"** (1–2 minutes)
6. Note the server's public IP address from the dashboard

---

### Step 2 — SSH into the Server

On your Windows machine, open Command Prompt:

```
ssh root@YOUR_LINODE_IP
```

Enter your root password when prompted.

---

### Step 3 — Update the System

```bash
dnf update -y
```

Wait for completion (2–5 minutes). You should see `Complete!` at the end.

---

## Part 2 — Point placewell.app DNS to Your Linode

### Step 4 — Update DNS on Namecheap

1. Log into **https://www.namecheap.com** with your Beniralu account
2. Click **"Domain List"** in the left sidebar
3. Find `placewell.app` and click **"Manage"**
4. Click the **"Advanced DNS"** tab
5. Find the A Records for `@` and `www`
6. Edit each one and set the IP address to your new Linode IP
7. Save each record by clicking the green checkmark

---

### Step 5 — Wait for DNS Propagation

On your Windows machine, check propagation every few minutes:

```
nslookup placewell.app
```

When the output shows your new Linode IP, DNS is ready. Do not proceed to
Part 5 (SSL) until this resolves correctly. Propagation typically takes
15–30 minutes on Namecheap.

---

## Part 3 — Install Apache and Configure Firewall

### Step 6 — Install Apache

```bash
dnf install -y httpd
systemctl enable httpd --now
```

Verify Apache is running:

```bash
systemctl status httpd | head -5
```

You should see `Active: active (running)`.

---

### Step 7 — Configure the Firewall

```bash
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --reload
```

Verify the correct services are open:

```bash
firewall-cmd --list-services
```

You should see `http` and `https` listed (along with `ssh` and others).

---

## Part 4 — Set Up the FastAPI Service

### Step 8 — Install Python Dependencies

Python 3.9 ships with AlmaLinux 9. Install pip:

```bash
dnf install -y python3-pip
```

Verify Python is available:

```bash
python3 --version
```

---

### Step 9 — Create the Project Directory

```bash
mkdir -p /opt/placewell-service
```

---

### Step 10 — Copy Project Files from Windows

Open a **new Command Prompt on your Windows machine** (keep SSH open in the other window):

```
scp -r C:\PlaceWellQRService\* root@YOUR_LINODE_IP:/opt/placewell-service/
```

Hidden files (`.env.example`, `.gitignore`) may not copy automatically. Run these separately:

```
scp C:\PlaceWellQRService\.env.example root@YOUR_LINODE_IP:/opt/placewell-service/
scp C:\PlaceWellQRService\.gitignore root@YOUR_LINODE_IP:/opt/placewell-service/
```

Verify all files arrived on the Linode:

```bash
ls -la /opt/placewell-service/
```

You should see: `app/`, `.env.example`, `.gitignore`, `README.md`, `requirements.txt`

---

### Step 11 — Copy the Firebase Service Account Key

On your Windows machine:

```
scp C:\PlaceWellQRService\serviceAccountKey.json root@YOUR_LINODE_IP:/opt/placewell-service/
```

---

### Step 12 — Set File Permissions

```bash
chmod 600 /opt/placewell-service/serviceAccountKey.json
chmod 600 /opt/placewell-service/.env
chmod 755 /opt/placewell-service
chmod 755 /opt/placewell-service/app
```

---

### Step 13 — Create the .env File

```bash
cp /opt/placewell-service/.env.example /opt/placewell-service/.env
nano /opt/placewell-service/.env
```

Generate secrets by running these on the Linode:

```bash
python3 -c "import secrets; print(secrets.token_hex(32))"
```

Run this twice — once for `PLACEWELL_ALLOCATE_SECRET` and once for `PLACEWELL_HMAC_SECRET`.

Fill in the `.env` file:

```
PLACEWELL_ALLOCATE_SECRET=<generated value>
PLACEWELL_HMAC_SECRET=<generated value — must also go in app.json>
GOOGLE_APPLICATION_CREDENTIALS=/opt/placewell-service/serviceAccountKey.json
PLACEWELL_QR_BASE_URL=https://placewell.app/s
PLACEWELL_DEEP_LINK_SCHEME=placewell://scan
```

> **Important:** Copy the `PLACEWELL_HMAC_SECRET` value into your React Native
> app's `app.json` under `extra.hmacSecret`. If they don't match, offline QR
> validation will fail for every label scan.

Press `Ctrl + X`, then `Y`, then `Enter` to save.

---

### Step 14 — Create the Python Virtual Environment

```bash
cd /opt/placewell-service
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

Installation takes 2–3 minutes. When complete, deactivate:

```bash
deactivate
```

---

### Step 15 — Test the Service Starts Correctly

```bash
cd /opt/placewell-service
source .venv/bin/activate
uvicorn app.main:app --host 127.0.0.1 --port 8000
```

You should see:
```
INFO:     Application startup complete.
INFO:     Uvicorn running on http://127.0.0.1:8000
```

Press `Ctrl + C` to stop it. Then deactivate:

```bash
deactivate
```

---

### Step 16 — Create the systemd Service

This keeps the service running permanently and restarts it automatically after a reboot.

```bash
nano /etc/systemd/system/placewell.service
```

Paste the following exactly:

```ini
[Unit]
Description=PlaceWell Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/placewell-service
EnvironmentFile=/opt/placewell-service/.env
ExecStart=/opt/placewell-service/.venv/bin/uvicorn app.main:app --host 127.0.0.1 --port 8000 --workers 2
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

Press `Ctrl + X`, then `Y`, then `Enter` to save.

> `--host 127.0.0.1` means FastAPI listens on the internal loopback address only.
> It is not exposed to the internet. Apache is the only external entry point.

---

### Step 17 — Enable and Start the Service

```bash
systemctl daemon-reload
systemctl enable placewell --now
```

Verify it is running:

```bash
systemctl status placewell | head -8
```

You should see `Active: active (running)`.

Confirm it responds internally:

```bash
curl http://127.0.0.1:8000/health
```

You should see: `{"status":"ok"}`

---

## Part 5 — Configure Apache as a Reverse Proxy

### Step 18 — Create the Well-Known Directory for SSL Verification

```bash
mkdir -p /var/www/placewell-well-known/.well-known/acme-challenge
```

---

### Step 19 — Create the Apache Virtual Host

```bash
nano /etc/httpd/conf.d/placewell.conf
```

Paste the following exactly:

```apache
<VirtualHost *:80>
    ServerName placewell.app
    ServerAlias www.placewell.app
    ServerAdmin admin@placewell.app

    # Let's Encrypt SSL verification directory
    Alias /.well-known/acme-challenge/ /var/www/placewell-well-known/.well-known/acme-challenge/
    <Directory "/var/www/placewell-well-known/">
        AllowOverride None
        Options None
        Require all granted
    </Directory>

    # Redirect all other HTTP traffic to HTTPS
    RewriteEngine On
    RewriteCond %{REQUEST_URI} !^/.well-known/
    RewriteRule ^ https://%{SERVER_NAME}%{REQUEST_URI} [L,R=301]

    CustomLog /var/log/httpd/placewell_access.log combined
    ErrorLog /var/log/httpd/placewell_error.log
</VirtualHost>
```

Press `Ctrl + X`, then `Y`, then `Enter` to save.

---

### Step 20 — Test and Restart Apache

Always test the config before restarting:

```bash
httpd -t
```

You must see `Syntax OK`. Then:

```bash
systemctl restart httpd
```

---

## Part 6 — Install SSL Certificate via Let's Encrypt

> DNS must be propagated before this step. `nslookup placewell.app` must
> return your Linode IP or this step will fail.

### Step 21 — Install Certbot

```bash
dnf install -y epel-release
dnf install -y certbot python3-certbot-apache
```

---

### Step 22 — Disable the Default SSL Config

AlmaLinux 9 installs a default SSL config that references a non-existent
certificate. Disable it before running Certbot:

```bash
mv /etc/httpd/conf.d/ssl.conf /etc/httpd/conf.d/ssl.conf.disabled
systemctl restart httpd
```

---

### Step 23 — Obtain the SSL Certificate

```bash
certbot --apache -d placewell.app -d www.placewell.app
```

Answer the prompts:
1. **Email address:** Enter the Beniralu email address
2. **Agree to terms:** Type `A` and press Enter
3. **Share with EFF:** Type `N` and press Enter
4. **Redirect HTTP to HTTPS:** Select option `2` and press Enter

Certbot will verify domain ownership, download the certificate, and create
`/etc/httpd/conf.d/placewell-le-ssl.conf` automatically.

---

### Step 24 — Add the Proxy Configuration to the HTTPS Block

```bash
nano /etc/httpd/conf.d/placewell-le-ssl.conf
```

Find the line `ServerName placewell.app` inside the `<VirtualHost *:443>` block
and add these lines directly after it:

```apache
    # Proxy all traffic to the PlaceWell FastAPI service on port 8000
    ProxyPreserveHost On
    ProxyPass / http://127.0.0.1:8000/
    ProxyPassReverse / http://127.0.0.1:8000/
    RequestHeader set X-Forwarded-Proto "https"

    # Security headers
    Header always set X-Frame-Options "DENY"
    Header always set X-Content-Type-Options "nosniff"
```

Press `Ctrl + X`, then `Y`, then `Enter` to save.

---

### Step 25 — Allow Apache to Connect to Local Ports (SELinux)

AlmaLinux 9 runs SELinux in enforcing mode by default. SELinux blocks Apache
from making outbound connections to other processes unless explicitly permitted.
Without this, Apache returns 503 when trying to proxy to FastAPI.

```bash
setsebool -P httpd_can_network_connect 1
```

The `-P` flag makes this permanent across reboots.

---

### Step 26 — Test and Restart Apache

```bash
httpd -t
```

You must see `Syntax OK`. Then:

```bash
systemctl restart httpd
```

---

### Step 27 — Enable the SSL Renewal Timer

```bash
systemctl start certbot-renew.timer
systemctl status certbot-renew.timer
```

You should see `Active: active (waiting)` with a next trigger time shown.
Certbot will automatically renew the certificate before it expires every 90 days.

---

## Part 7 — Verify the Full Deployment

### Step 28 — Test the Health Endpoint

Open your browser and go to:

```
https://placewell.app/health
```

You should see `{"status":"ok"}` with a padlock icon confirming SSL is valid.

---

### Step 29 — Test the API Docs

```
https://placewell.app/docs
```

You should see the FastAPI interactive documentation page.

---

### Step 30 — Test QR Allocation

On the Linode, retrieve your allocate secret:

```bash
grep PLACEWELL_ALLOCATE_SECRET /opt/placewell-service/.env
```

Run a test allocation:

```bash
curl -X POST https://placewell.app/api/qr/allocate \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_SECRET" \
  -d '{
    "order_id": "PW-TEST-001",
    "items": [
      {"item_id": "spice_basil_001", "is_blank": false, "label_name": "Basil"},
      {"item_id": "spice_blank_001", "is_blank": true, "label_name": null}
    ]
  }'
```

You should receive a JSON response with two QR URLs.

---

### Step 31 — Test the Scan Redirect

Copy one of the QR URLs from the previous step and test the redirect:

```bash
curl -v https://placewell.app/s/{LABELID}-{SIGNATURE} 2>&1 | grep -i "location"
```

You should see `location: placewell://scan/{LABELID}` confirming the redirect
is firing correctly.

---

## Summary

| Component | Location | Notes |
|---|---|---|
| FastAPI service | `/opt/placewell-service/` | Running on `127.0.0.1:8000` |
| systemd service | `/etc/systemd/system/placewell.service` | Auto-starts on reboot |
| Apache HTTP config | `/etc/httpd/conf.d/placewell.conf` | Redirects HTTP to HTTPS |
| Apache HTTPS config | `/etc/httpd/conf.d/placewell-le-ssl.conf` | Proxies to FastAPI |
| SSL certificate | `/etc/letsencrypt/live/placewell.app/` | Auto-renews every 90 days |
| Access log | `/var/log/httpd/placewell_access.log` | |
| Error log | `/var/log/httpd/placewell_error.log` | |

---

## Deploying Code Updates

```bash
# On Windows — copy updated app files to server
scp -r C:\PlaceWellQRService\app\* root@45.56.71.137:/opt/placewell-service/app/

# On Linode — restart the service to pick up changes
systemctl restart placewell
systemctl status placewell | head -5
```
