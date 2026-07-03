# PlaceWell Server Reference

## Server summary

| Property | Value |
|---|---|
| Provider | Linode |
| OS | AlmaLinux 9.7 |
| Public IP | `45.56.71.137` |
| Domain | `placewell.app` |
| SSH | `ssh root@45.56.71.137` |
| Web server | Apache `httpd` |
| SSL | Let's Encrypt via Certbot |

## Public routes and internal services

| Surface | Public URL | Internal target | Notes |
|---|---|---|---|
| QR Service health | `https://placewell.app/health` | `127.0.0.1:8000` | Public |
| QR Service docs | `https://placewell.app/docs` | `127.0.0.1:8000` | Public FastAPI docs |
| QR allocation + lookup | `https://placewell.app/api/qr/*` | `127.0.0.1:8000` | Allocation requires bearer token |
| Scan redirect | `https://placewell.app/s/*` | `127.0.0.1:8000` | Public label scan endpoint |
| Operator UI | `https://placewell.app/ui` | `127.0.0.1:8080` | Apache Basic Auth protected |
| Static UI assets | `https://placewell.app/static/*` | `127.0.0.1:8080` | Protected with same UI auth |
| UI downloads | `https://placewell.app/download/*` | `127.0.0.1:8080` | Protected with same UI auth |

## Running services

| Service | Purpose | Port / exposure |
|---|---|---|
| Apache (`httpd`) | Reverse proxy and TLS termination | 80, 443 public |
| `placewell` | PlaceWellQRService FastAPI app | `127.0.0.1:8000` only |
| `placewell-ui` | PlaceWellUI FastAPI app | `127.0.0.1:8080` only |
| `firewalld` | Firewall | Opens 22, 80, 443 |
| `certbot-renew.timer` | SSL renewal automation | Daily timer |

## Key file locations

### QR Service

| Path | Purpose |
|---|---|
| `/opt/placewell-service/` | QR Service project root |
| `/opt/placewell-service/app/` | FastAPI application code |
| `/opt/placewell-service/.env` | QR Service environment variables |
| `/opt/placewell-service/serviceAccountKey.json` | Firebase service account key |
| `/opt/placewell-service/.venv/` | Python virtual environment |
| `/etc/systemd/system/placewell.service` | systemd service definition |

### Operator UI

| Path | Purpose |
|---|---|
| `/opt/placewell-ui/` | UI project root |
| `/opt/placewell-ui/app/` | FastAPI application code |
| `/opt/placewell-ui/data/` | CSV content presets |
| `/opt/placewell-ui/output/` | Generated PDFs |
| `/opt/placewell-ui/.env` | UI environment variables |
| `/etc/systemd/system/placewell-ui.service` | UI systemd service definition |
| `/etc/httpd/.htpasswd_placewell_ui` | Apache Basic Auth file for `/ui` |

### Apache / SSL

| Path | Purpose |
|---|---|
| `/etc/httpd/conf.d/placewell.conf` | HTTP virtual host and redirect rules |
| `/etc/httpd/conf.d/placewell-le-ssl.conf` | HTTPS virtual host and proxy rules |
| `/etc/letsencrypt/live/placewell.app/` | Active certificate files |
| `/var/log/httpd/placewell_access.log` | Apache access log |
| `/var/log/httpd/placewell_error.log` | Apache error log |

## Service management

### QR Service

```bash
systemctl status placewell
systemctl start placewell
systemctl stop placewell
systemctl restart placewell
journalctl -u placewell -f
journalctl -u placewell -n 50
curl http://127.0.0.1:8000/health
```

### Operator UI

```bash
systemctl status placewell-ui
systemctl start placewell-ui
systemctl stop placewell-ui
systemctl restart placewell-ui
journalctl -u placewell-ui -f
curl http://127.0.0.1:8080/health
```

### Apache and SSL

```bash
systemctl status httpd
httpd -t
systemctl restart httpd
certbot certificates
certbot renew --dry-run
systemctl status certbot-renew.timer
firewall-cmd --list-services
```

## Deployment update quick reference

### Update QR Service code

```bash
# From Windows
scp -r C:\PlaceWellQRService\app\* root@45.56.71.137:/opt/placewell-service/app/

# On the server
systemctl restart placewell
systemctl status placewell | head -5
curl http://127.0.0.1:8000/health
```

### Update UI code

```bash
# From Windows
scp -r C:\PlaceWellUI\app\* root@45.56.71.137:/opt/placewell-ui/app/

# On the server
systemctl restart placewell-ui
systemctl status placewell-ui | head -5
curl http://127.0.0.1:8080/health
```

### Update UI CSV data

```bash
scp C:\PlaceWellUI\data\spice.csv root@45.56.71.137:/opt/placewell-ui/data/
```

No service restart is required for CSV-only changes if the UI reads the file on each submission.

## Environment variables

### QR Service (`/opt/placewell-service/.env`)

| Variable | Purpose |
|---|---|
| `PLACEWELL_ALLOCATE_SECRET` | Bearer token for allocation endpoint |
| `PLACEWELL_HMAC_SECRET` | Must match the mobile app HMAC secret exactly |
| `GOOGLE_APPLICATION_CREDENTIALS` | Path to the Firebase service account key |
| `PLACEWELL_QR_BASE_URL` | Base scan URL, typically `https://placewell.app/s` |
| `PLACEWELL_DEEP_LINK_SCHEME` | App deep-link scheme, typically `placewell://scan` |

### UI (`/opt/placewell-ui/.env`)

| Variable | Purpose |
|---|---|
| `USERNAME_PREFIX` | Prefix used when generating order IDs/usernames |
| `QR_SERVICE_URL` | Local QR Service base URL |
| `QR_ALLOCATE_SECRET` | Same secret value used by the QR allocation endpoint |
| `PDF_GENERATOR_PATH` | Path to PlaceWellPdfGenerator on the server |
| `PDF_OUTPUT_DIR` | Output folder for generated PDFs |

## Firestore

| Property | Value |
|---|---|
| Project | `placewell-prod` |
| Database | Firestore (`us-central1`) |
| Primary collections | `qr_codes`, `orders` |
| Credential file | `/opt/placewell-service/serviceAccountKey.json` |
| Console | `https://console.firebase.google.com` |

## DNS

| Property | Value |
|---|---|
| Registrar | Namecheap |
| Domain | `placewell.app` |
| `A` record (`@`) | `45.56.71.137` |
| `A` record (`www`) | `45.56.71.137` |

## Troubleshooting

### QR Service returns 503 through Apache
```bash
systemctl status placewell
curl http://127.0.0.1:8000/health
tail -20 /var/log/httpd/placewell_error.log
setsebool -P httpd_can_network_connect 1
systemctl restart httpd
```

### UI does not load or prompts fail
```bash
systemctl status placewell-ui
curl http://127.0.0.1:8080/health
journalctl -u placewell-ui -n 50
htpasswd /etc/httpd/.htpasswd_placewell_ui hussain
```

### Apache will not restart
```bash
httpd -t
systemctl restart httpd
```
