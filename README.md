# Real-Time 3D Room Temperature Heatmap

A Python application that generates a real-time 3D volumetric heatmap of a mealworm breeding room using temperature data received from Ubidots via MQTT.

## Project Overview

This system monitors the internal temperature distribution of a Tenebrio molitor breeding room using 5 interior sensors and 1 exterior sensor. It produces an interactive 3D heatmap that updates in real time, allowing operators to detect thermal gradients, hot spots, and cold zones.

## Features

- Real-time MQTT subscription to Ubidots IoT platform
- 3D volumetric temperature interpolation using scipy griddata
- Interactive Plotly.js dashboard with volume trace rendering
- Exterior temperature monitoring (tps sensor)
- Fan and extractor status indicators
- Humidity monitoring (h1–h5, humidity_general) with color-coded horizontal bars
- Ammonia (PPM) monitoring with color-coded horizontal bar
- Per-sensor vertical thermometer indicators with interpolated colors
- MQTT connection status monitoring
- Auto-refresh every 2 seconds
- Physical temperature validation (rejects impossible readings)

## System Architecture

See [ARCHITECTURE.md](ARCHITECTURE.md) for the full architecture diagram and component descriptions.

```
Sensors → MQTT Client → Heatmap Engine → Flask API → Frontend (Plotly.js)
```

## Installation

See [INSTALLATION.md](INSTALLATION.md) for detailed setup instructions.

```bash
pip install -r requirements.txt
python backend/main.py
```

## API

See [API_REFERENCE.md](API_REFERENCE.md) for endpoint documentation.

| Endpoint | Description |
|----------|-------------|
| `GET /` | Dashboard with 3D heatmap |
| `GET /api/data` | JSON data for visualization |

## Project Structure

```
tenebrio-3d-heatmap/
├── backend/
│   ├── config.py            # Configuration constants
│   ├── main.py              # Application entry point
│   ├── mqtt_client.py       # MQTT connection and payload parsing
│   ├── heatmap_engine.py    # Temperature storage and 3D interpolation
│   └── visualization.py     # Flask web server and API
├── templates/
│   └── index.html           # Plotly.js 3D heatmap dashboard
├── tests/
│   ├── test_interpolation.py
│   └── test_mqtt_parser.py
├── mqtt_simulator.py        # Local test data publisher
├── requirements.txt
├── ARCHITECTURE.md
├── SYSTEM_DESCRIPTION.md
├── API_REFERENCE.md
├── INSTALLATION.md
└── README.md
```

## Simulation Mode (Local Testing)

For testing without a real Ubidots device, use the simulator with a local MQTT broker (e.g., Mosquitto):

1. Start your local broker (e.g., `mosquitto`).
2. Update `backend/config.py`:
   ```python
   MQTT_BROKER = "localhost"
   UBIDOTS_TOKEN = ""
   ```
3. In one terminal: `python mqtt_simulator.py`
4. In another terminal: `python backend/main.py`

## Running Tests

```bash
pytest tests/ -v
```
