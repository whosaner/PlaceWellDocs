# PlaceWell · Server Quick Reference

## Server Details

| Property | Value |
|---|---|
| Provider | Linode |
| OS | AlmaLinux 9.7 |
| IP Address | 45.56.71.137 |
| Domain | placewell.app |
| SSH Access | `ssh root@45.56.71.137` |

---

## What's Running

| Service | Description | Port |
|---|---|---|
| Apache (httpd) | Web server / reverse proxy | 80, 443 (public) |
| PlaceWell FastAPI | QR service | 8000 (internal only) |
| Firewall (firewalld) | Open ports: 22, 80, 443 | — |
| SSL (Let's Encrypt) | Certificate for placewell.app | — |
| certbot-renew.timer | Auto-renews SSL every 90 days | — |

---

## Key File Locations

| File / Directory | Purpose |
|---|---|
| `/opt/placewell-service/` | Project root |
| `/opt/placewell-service/app/` | FastAPI application code |
| `/opt/placewell-service/.env` | Environment variables (sensitive) |
| `/opt/placewell-service/serviceAccountKey.json` | Firebase service account key (sensitive) |
| `/opt/placewell-service/.venv/` | Python virtual environment |
| `/opt/placewell-service/requirements.txt` | Python dependencies |
| `/etc/systemd/system/placewell.service` | systemd service definition |
| `/etc/httpd/conf.d/placewell.conf` | Apache HTTP virtual host |
| `/etc/httpd/conf.d/placewell-le-ssl.conf` | Apache HTTPS virtual host (Certbot-generated) |
| `/etc/letsencrypt/live/placewell.app/` | SSL certificate files |
| `/var/log/httpd/placewell_access.log` | Apache access log |
| `/var/log/httpd/placewell_error.log` | Apache error log |

---

## Service Management

### PlaceWell FastAPI Service

```bash
# Check status
systemctl status placewell

# Start
systemctl start placewell

# Stop
systemctl stop placewell

# Restart (use after code updates)
systemctl restart placewell

# View live logs
journalctl -u placewell -f

# View last 50 log lines
journalctl -u placewell -n 50
```

### Apache

```bash
# Check status
systemctl status httpd

# Restart
systemctl restart httpd

# Test config for syntax errors (always run before restart)
httpd -t

# View live error log
tail -f /var/log/httpd/placewell_error.log

# View live access log
tail -f /var/log/httpd/placewell_access.log
```

### SSL Certificate

```bash
# Check certificate expiry
certbot certificates

# Test auto-renewal (dry run)
certbot renew --dry-run

# Check renewal timer status
systemctl status certbot-renew.timer
```

### Firewall

```bash
# List open services
firewall-cmd --list-services

# List open ports
firewall-cmd --list-ports
```

---

## Deploying a Code Update

Run these commands in order after updating code on your Windows machine:

**1. Copy updated app files from Windows to Linode:**
```
scp -r C:\PlaceWellQRService\app\* root@45.56.71.137:/opt/placewell-service/app/
```

**2. SSH into the Linode:**
```
ssh root@45.56.71.137
```

**3. Restart the service to pick up changes:**
```bash
systemctl restart placewell
```

**4. Verify it's running:**
```bash
systemctl status placewell | head -5
```

**5. Confirm it's responding:**
```bash
curl http://127.0.0.1:8000/health
```

---

## API Endpoints

| Method | URL | Auth | Purpose |
|---|---|---|---|
| GET | `https://placewell.app/health` | None | Health check |
| GET | `https://placewell.app/docs` | None | Interactive API docs |
| POST | `https://placewell.app/api/qr/allocate` | Bearer token | Allocate QR IDs for an order |
| GET | `https://placewell.app/s/{LABELID}-{SIGNATURE}` | None | Buyer scan redirect |

---

## Environment Variables

Located at `/opt/placewell-service/.env`

| Variable | Purpose |
|---|---|
| `PLACEWELL_ALLOCATE_SECRET` | Bearer token for `/api/qr/allocate` — keep this safe |
| `PLACEWELL_HMAC_SECRET` | Must match `extra.hmacSecret` in React Native `app.json` exactly |
| `GOOGLE_APPLICATION_CREDENTIALS` | Path to Firebase service account key |
| `PLACEWELL_QR_BASE_URL` | Base URL for QR codes (`https://placewell.app/s`) |
| `PLACEWELL_DEEP_LINK_SCHEME` | Deep link scheme (`placewell://scan`) |

To view current values (sensitive — do not share output):
```bash
cat /opt/placewell-service/.env
```

To edit:
```bash
nano /opt/placewell-service/.env
systemctl restart placewell
```

---

## Troubleshooting

### Service won't start
```bash
journalctl -u placewell -n 50
```
Look for Python errors or missing environment variables.

### 503 Service Unavailable in browser
```bash
# Check FastAPI is running
systemctl status placewell

# Check FastAPI responds internally
curl http://127.0.0.1:8000/health

# Check Apache error log
tail -20 /var/log/httpd/placewell_error.log

# If log shows "Permission denied" — SELinux issue
setsebool -P httpd_can_network_connect 1
systemctl restart httpd
```

### SSL certificate error in browser
```bash
# Check certificate is valid
certbot certificates

# Check Apache HTTPS config
cat /etc/httpd/conf.d/placewell-le-ssl.conf
```

### Apache won't restart after config change
```bash
# Always test config first
httpd -t

# Fix any errors shown, then restart
systemctl restart httpd
```

---

## Firebase / Firestore

| Property | Value |
|---|---|
| Project | placewell-prod |
| Database | Firestore (us-central1) |
| Collection | qr_codes |
| Service account key | `/opt/placewell-service/serviceAccountKey.json` |
| Console | https://console.firebase.google.com |

---

## SSL Certificate

| Property | Value |
|---|---|
| Provider | Let's Encrypt |
| Certificate path | `/etc/letsencrypt/live/placewell.app/fullchain.pem` |
| Key path | `/etc/letsencrypt/live/placewell.app/privkey.pem` |
| Expiry | 2026-07-28 |
| Auto-renewal | Yes — certbot-renew.timer runs daily |

---

## Domain / DNS

| Property | Value |
|---|---|
| Registrar | Namecheap (Beniralu account) |
| Domain | placewell.app |
| A Record (@) | 45.56.71.137 |
| A Record (www) | 45.56.71.137 |
| DNS management | https://www.namecheap.com → Domain List → placewell.app → Advanced DNS |
