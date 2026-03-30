# Architecture

## Components

- **MQTT Client** — Connects to the Ubidots MQTT broker and subscribes to sensor data using the `/lv` (last value) topic format.
- **Heatmap Engine** — Stores the latest sensor temperatures, humidity, radiant floor data, and produces 3D interpolated temperature and humidity volumes using `scipy.interpolate.griddata`.
- **API Server** — Flask web server that exposes JSON API endpoints for real-time data, historical data from Ubidots, and server-side interpolation.
- **Visualization Frontend** — Plotly.js-based dashboard that renders an interactive 3D volumetric heatmap with toggle between temperature/humidity views, environmental indicators, and a historical data timeline.

## Architecture Diagram

```
Sensors (t1–t5, tex, tps, tpi, h1–h5, hum_general, amoniaco,
         temperatura1, temperatura3, ventilador, extractor)
       │
       │  MQTT (Ubidots /lv topics)
       ▼
  MQTT Client  (backend/mqtt_client.py)
       │
       │  Parsed sensor readings
       ▼
  Heatmap Engine  (backend/heatmap_engine.py)
       │
       │  3D interpolated volumes (temp + humidity)
       ▼
  Flask API  (backend/visualization.py)
       │
       │  JSON over HTTP (/api/data, /api/history, /api/history/interpolate)
       ▼
  Frontend  (templates/index.html — Plotly.js)
       │
       ▲  Historical data
       │
  Ubidots REST API  (queried by /api/history endpoint)
```

## Component Responsibilities

### backend/mqtt_client.py

Manages the MQTT connection to Ubidots. Subscribes to `/v1.6/devices/{device}/+/lv` and parses the plain numeric payloads into `{label: value}` dictionaries. Forwards parsed data to a callback (the heatmap engine). Supports all variable types: temperature, humidity, averages, radiant floor, ammonia, and device states.

### backend/heatmap_engine.py

Thread-safe data store. Receives sensor updates, validates values against a physically plausible range, and performs 3D volumetric interpolation using `scipy.interpolate.griddata` (nearest-neighbor + linear) for both temperature and humidity. Also tracks exterior temperature, average temperatures, radiant floor sensors, humidity, ammonia, fan/extractor states, and last update timestamp.

### backend/visualization.py

Flask application with four routes:
- `GET /` — Renders the Plotly.js dashboard.
- `GET /api/data` — Returns JSON with interpolated 3D volumes (temperature and humidity), sensor data, radiant floor data, and device states.
- `GET /api/history` — Fetches historical data from Ubidots REST API for a date range.
- `GET /api/history/interpolate` — Server-side 3D interpolation for a specific historical moment.

### backend/config.py

Central configuration module containing MQTT credentials, sensor positions, room dimensions, grid resolution, temperature ranges, radiant floor labels, humidity labels, ammonia label, and web server settings.

### templates/index.html

Single-page dashboard using Plotly.js with:
- 3D isosurface render with temperature/humidity toggle
- 3D wireframe (inclined roof, windows, furniture, lamps, radiant floor)
- Side panel with thermometers, humidity bars, ammonia bar, radiant floor bars, and device widgets
- Historical data viewer with timeline slider
- Responsive design (desktop + mobile)
- Branded header (TECHNEBRIOS + Ingenieria Condor)
