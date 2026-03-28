# Architecture

## Components

- **MQTT Client** — Connects to the Ubidots MQTT broker and subscribes to sensor data using the `/lv` (last value) topic format.
- **Heatmap Engine** — Stores the latest sensor temperatures and produces a 3D interpolated temperature volume using `scipy.interpolate.griddata`.
- **API Server** — Flask web server that exposes a JSON API endpoint (`/api/data`) with the interpolated volume and sensor metadata.
- **Visualization Frontend** — Plotly.js-based dashboard that renders an interactive 3D volumetric heatmap, auto-refreshing from the API.

## Architecture Diagram

```
Sensors (t1–t5, tps)
       │
       │  MQTT (Ubidots /lv topics)
       ▼
  MQTT Client  (backend/mqtt_client.py)
       │
       │  Parsed sensor readings
       ▼
  Heatmap Engine  (backend/heatmap_engine.py)
       │
       │  3D interpolated volume
       ▼
  Flask API  (backend/visualization.py)
       │
       │  JSON over HTTP
       ▼
  Frontend  (templates/index.html — Plotly.js)
```

## Component Responsibilities

### backend/mqtt_client.py

Manages the MQTT connection to Ubidots. Subscribes to `/v1.6/devices/{device}/+/lv` and parses the plain numeric payloads into `{label: value}` dictionaries. Forwards parsed data to a callback (the heatmap engine).

### backend/heatmap_engine.py

Thread-safe temperature store. Receives sensor updates, validates values against a physically plausible range, and performs 3D volumetric interpolation using `scipy.interpolate.griddata` (nearest-neighbor + linear). Also tracks exterior temperature, fan, and extractor states.

### backend/visualization.py

Flask application with two routes:
- `GET /` — Renders the Plotly.js dashboard.
- `GET /api/data` — Returns JSON with the interpolated 3D volume, sensor positions and values, exterior temperature, and device states.

### backend/config.py

Central configuration module containing MQTT credentials, sensor positions, room dimensions, grid resolution, temperature ranges, and web server settings.

### templates/index.html

Single-page dashboard using Plotly.js to render an interactive 3D volume trace. Polls `/api/data` at a configurable interval to update the heatmap in real time.
