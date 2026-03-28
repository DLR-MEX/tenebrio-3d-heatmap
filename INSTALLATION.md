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
