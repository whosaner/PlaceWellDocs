# BeNiralu / PlaceWell — Server & Infrastructure Reference
*Last updated: May 21, 2026*

---

## 1. Server

| Field | Value |
|---|---|
| Provider | Linode (Akamai Cloud) |
| IP Address | 45.56.71.137 |
| OS | Linux (CentOS / RHEL based) |
| Web Server | Apache httpd (running as `httpd`, not `apache2`) |
| Config Location | `/etc/httpd/conf.d/` |
| SSL Provider | Let's Encrypt (Certbot) |
| SSL Auto-Renew | Yes — scheduled task set up by Certbot |

---

## 2. Domains & Virtual Hosts

### placewell.app

| Field | Value |
|---|---|
| Domain | placewell.app / www.placewell.app |
| DNS Registrar | Namecheap |
| Config File | `/etc/httpd/conf.d/` (main conf.d file) |
| SSL Cert | `/etc/letsencrypt/live/placewell.app/fullchain.pem` |
| SSL Key | `/etc/letsencrypt/live/placewell.app/privkey.pem` |
| HTTP → HTTPS | Yes — 301 redirect via RewriteRule |
| Backend (Main App) | Proxied to `http://127.0.0.1:8000` (FastAPI / Uvicorn) |
| Backend (UI) | Proxied to `http://127.0.0.1:8080` (Uvicorn) — Basic Auth protected |
| Auth File | `/etc/httpd/conf.d/.htpasswd` |
| Access Log | `/var/log/httpd/placewell_access.log` |
| Error Log | `/var/log/httpd/placewell_error.log` |

### beniralu.com

| Field | Value |
|---|---|
| Domain | beniralu.com / www.beniralu.com |
| DNS Registrar | GoDaddy |
| DNS A Record (@) | 45.56.71.137 |
| DNS A Record (www) | 45.56.71.137 |
| Config File (HTTP) | `/etc/httpd/conf.d/beniralu.conf` |
| Config File (HTTPS) | `/etc/httpd/conf.d/beniralu-le-ssl.conf` |
| Document Root | `/var/www/beniralu/public_html/` |
| Images Folder | `/var/www/beniralu/public_html/images/` |
| SSL Cert | `/etc/letsencrypt/live/beniralu.com/fullchain.pem` |
| SSL Key | `/etc/letsencrypt/live/beniralu.com/privkey.pem` |
| SSL Expiry | August 19, 2026 (auto-renews) |
| Access Log | `/var/log/httpd/beniralu_access.log` |
| Error Log | `/var/log/httpd/beniralu_error.log` |

---

## 3. Backend Services

| Field | Value |
|---|---|
| PlaceWell Main API | FastAPI — listening on `127.0.0.1:8000` |
| PlaceWell UI | Uvicorn — listening on `127.0.0.1:8080` |
| Process Manager | Python3 / Uvicorn |
| Ports (Public) | 80 (HTTP) and 443 (HTTPS) — handled by Apache |
| Ports (Internal) | 8000 (main app), 8080 (UI) — not publicly exposed |

---

## 4. Useful Commands

### Apache

```bash
# Check Apache status
systemctl status httpd

# Start / Stop / Reload Apache
systemctl start httpd
systemctl stop httpd
systemctl reload httpd

# Test config before reloading
apachectl configtest

# List virtual host configs
ls /etc/httpd/conf.d/
```

### SSL / Certbot

```bash
# Renew all certificates manually
certbot renew

# Issue a new certificate for a domain
certbot --apache -d example.com -d www.example.com

# Check certificate expiry
certbot certificates
```

### DNS Verification

```bash
# Check what DNS resolves to (from server)
curl -s "https://dns.google/resolve?name=beniralu.com&type=A" | python3 -m json.tool

# Check running processes
ps aux | grep -E 'nginx|apache|httpd|caddy'

# Check what is listening on ports 80/443
ss -tlnp | grep -E ':80|:443'
```

### File Upload (from local machine)

```bash
# Upload files to beniralu.com
scp index.html root@45.56.71.137:/var/www/beniralu/public_html/
scp basketball.jpg coach.jpg hockey.jpg root@45.56.71.137:/var/www/beniralu/public_html/images/

# Verify files on server
ls -la /var/www/beniralu/public_html/
ls -la /var/www/beniralu/public_html/images/
```

---

## 5. Apple Developer Account

| Field | Value |
|---|---|
| Entity | BeNiralu LLC |
| Account Holder | Khadija Rangwala |
| Apple ID | niralu.53@gmail.com |
| Enrollment ID | 6U58A6LHB5 |
| Business Website | https://www.beniralu.com |
| Work Email (enrollment) | khadija.r@beniralu.com |
| Status | Enrollment in progress — pending Apple approval |
| Annual Fee | $99 USD (due upon approval) |
| Purpose | PlaceWell iOS app distribution on App Store |

---

## 6. Key Accounts

| Account | Details |
|---|---|
| Namecheap | Domain registrar for placewell.app |
| GoDaddy | Domain registrar for beniralu.com and niralu.com |
| niralu.com | Redirects to BeNiralu Etsy shop |
| beniralu.com | Hosted on server — BeNiralu LLC landing page |
| Etsy Shop | etsy.com/shop/BeNiralu — 21.8k sales, 4.9 stars |
| Instagram | @be.niralu |
| Facebook | facebook.com/BeNiralu |
| PlaceWell Domain | placewell.app — hosted on same server |
| Firebase | Used for PlaceWell QR label validation (online whitelist) |
| HMAC Secret | FXE5253 — flagged for rotation after testing |

---

## 7. beniralu.com Landing Page

| Field | Value |
|---|---|
| index.html | `/var/www/beniralu/public_html/index.html` |
| basketball.jpg | `/var/www/beniralu/public_html/images/basketball.jpg` |
| coach.jpg | `/var/www/beniralu/public_html/images/coach.jpg` |
| hockey.jpg | `/var/www/beniralu/public_html/images/hockey.jpg` |
| Page Size | ~36KB HTML + 3 image files (no base64 embedding) |
| Fonts | Google Fonts CDN — Cormorant Garamond, Jost, DM Mono, Libre Baskerville |
| Purpose | Apple Developer enrollment verification + BeNiralu business presence |

---

> **Note:** Update this document whenever infrastructure changes are made — particularly SSL cert locations, new virtual hosts, or new backend services. The SSL cert for beniralu.com expires August 19, 2026 but Certbot will auto-renew it.
