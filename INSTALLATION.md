# Installation

## Requirements

- Python 3.10 or higher
- pip (Python package manager)

## Install Dependencies

```bash
# Option 1: Using the install script
bash install.sh

# Option 2: Manual
pip install -r requirements.txt
```

### Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| paho-mqtt | >= 2.0.0 | MQTT client for Ubidots communication |
| numpy | >= 1.24.0 | Numerical arrays and operations |
| scipy | >= 1.10.0 | 3D volumetric interpolation (griddata) |
| flask | >= 3.0.0 | Web server and JSON API |
| pytest | >= 7.0.0 | Test framework |

## Configuration

Edit `backend/config.py` with your Ubidots credentials:

```python
UBIDOTS_TOKEN = "YOUR_UBIDOTS_TOKEN"
DEVICE_LABEL  = "YOUR_DEVICE_LABEL"
```

## Run System

```bash
python backend/main.py
```

The application will:

1. Connect to the Ubidots MQTT broker.
2. Subscribe to sensor data from the configured device.
3. Start a Flask web server on `http://0.0.0.0:5000`.
4. Serve the 3D heatmap dashboard at the root URL.

Open `http://localhost:5000` in a browser to view the dashboard.

## Run Tests

```bash
pytest tests/ -v
```

---

## Deployment on Raspberry Pi

This section describes how to deploy the system as a service on a Raspberry Pi running Raspberry Pi OS (or any Debian-based Linux).

### 1. Install Tailscale (Remote Access)

Tailscale allows secure remote access to the Raspberry Pi from any device on your Tailscale network.

```bash
# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Authenticate and connect
sudo tailscale up

# Verify connection and get the Tailscale IP
tailscale ip -4
```

Once connected, you can access the dashboard remotely via `http://<tailscale-ip>:5000` from any device on your Tailscale network.

To enable Tailscale on boot (usually enabled by default):

```bash
sudo systemctl enable tailscaled
sudo systemctl start tailscaled
```

### 2. Clone the Repository

```bash
cd /home/spaces
git clone https://github.com/DLR-MEX/tenebrio-3d-heatmap.git
cd tenebrio-3d-heatmap
```

### 3. Create Virtual Environment and Install Dependencies

```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### 4. Configure Ubidots Credentials

```bash
nano backend/config.py
```

Set `UBIDOTS_TOKEN` and `DEVICE_LABEL` with your credentials.

### 5. Create the systemd Service

Create the service file:

```bash
sudo nano /etc/systemd/system/tenebrio.service
```

Paste the following content:

```ini
[Unit]
Description=Tenebrio 3D Heatmap
After=network.target

[Service]
User=spaces
WorkingDirectory=/home/spaces/tenebrio-3d-heatmap/backend
ExecStart=/home/spaces/tenebrio-3d-heatmap/venv/bin/python3 main.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

### 6. Enable and Start the Service

```bash
# Reload systemd to recognize the new service
sudo systemctl daemon-reload

# Enable automatic start on boot
sudo systemctl enable tenebrio

# Start the service now
sudo systemctl start tenebrio

# Verify it is running
sudo systemctl status tenebrio
```

The dashboard will be available at:
- Local network: `http://<raspberry-pi-ip>:5000`
- Tailscale: `http://<tailscale-ip>:5000`

### 7. View Logs

```bash
# Real-time logs
journalctl -u tenebrio -f

# Last 50 lines
journalctl -u tenebrio -n 50
```

---

## Updating the Project (Pull & Restart)

When there are new changes in the repository, follow these steps to update the Raspberry Pi:

```bash
# Navigate to the project directory
cd /home/spaces/tenebrio-3d-heatmap

# Pull latest changes from GitHub
git pull origin main

# Activate virtual environment and update dependencies (if changed)
source venv/bin/activate
pip install -r requirements.txt

# Restart the service to apply changes
sudo systemctl restart tenebrio

# Verify it restarted correctly
sudo systemctl status tenebrio
```

To do it all in one command:

```bash
cd /home/spaces/tenebrio-3d-heatmap && git pull origin main && source venv/bin/activate && pip install -r requirements.txt && sudo systemctl restart tenebrio && sudo systemctl status tenebrio
```
