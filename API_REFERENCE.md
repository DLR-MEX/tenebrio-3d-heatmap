# API Reference

## GET /

Renders the main dashboard page.

- **Response:** HTML page with the Plotly.js 3D volumetric heatmap.
- **Content-Type:** `text/html`

The dashboard auto-refreshes by polling `/api/data` every 2 seconds (configurable via `ANIMATION_INTERVAL_MS` in `backend/config.py`).

## GET /api/data

Returns JSON data for the 3D heatmap visualization.

- **Response:** JSON object
- **Content-Type:** `application/json`

### Success Response (200)

```json
{
  "volume_data": {
    "x": [0.0, 0.416, ...],
    "y": [0.0, 0.352, ...],
    "z": [0.0, 0.272, ...],
    "value": [24.5, 24.6, ...]
  },
  "humidity_volume_data": {
    "x": [0.0, 0.416, ...],
    "y": [0.0, 0.352, ...],
    "z": [0.0, 0.272, ...],
    "value": [45.0, 46.2, ...]
  },
  "x_range": [0, 10],
  "y_range": [0, 6],
  "z_range": [0, 3],
  "vmin": 14.0,
  "vmax": 35.0,
  "exterior_temp": 23.0,
  "avg_temp_superior": 26.2,
  "avg_temp_inferior": 21.9,
  "fan_on": true,
  "extractor_on": true,
  "mqtt_connected": true,
  "last_update": "2026-03-27 18:30:45",
  "sensors": {
    "t1": {"x": 2, "y": 3, "z": 2.5, "value": 25.3},
    "t2": {"x": 5, "y": 3, "z": 2.5, "value": 24.5},
    "t3": {"x": 8, "y": 3, "z": 2.5, "value": 25.3},
    "t4": {"x": 3, "y": 3, "z": 1.0, "value": 22.6},
    "t5": {"x": 7, "y": 3, "z": 1.0, "value": 23.0}
  },
  "tex_sensor": {
    "x": 2,
    "y": 6.15,
    "z": 0.8,
    "value": 23.0
  },
  "humidity": {
    "h1": 46.0,
    "h2": 21.0,
    "h3": 46.0,
    "h4": 44.0,
    "h5": 43.0,
    "hum_general": 38.0
  },
  "amoniaco": 0.0,
  "radiant_floor": {
    "temperatura1": {"value": 18.5, "name": "Salida"},
    "temperatura3": {"value": 19.1, "name": "Medio Piso"}
  }
}
```

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `volume_data` | object or null | Interpolated 3D temperature volume. Null if fewer than 3 sensors reported. |
| `humidity_volume_data` | object or null | Interpolated 3D humidity volume. Null if fewer than 3 sensors reported. |
| `x_range` | array | Room X boundaries in meters `[min, max]`. |
| `y_range` | array | Room Y boundaries in meters `[min, max]`. |
| `z_range` | array | Room Z boundaries in meters `[min, max]`. |
| `vmin` | float | Minimum temperature for the color scale (14°C). |
| `vmax` | float | Maximum temperature for the color scale (35°C). |
| `exterior_temp` | float or null | Latest exterior sensor (tex) reading. |
| `avg_temp_superior` | float or null | Average upper sensors temperature (tps). |
| `avg_temp_inferior` | float or null | Average lower sensors temperature (tpi). |
| `fan_on` | boolean | Whether the fan is currently on. |
| `extractor_on` | boolean | Whether the extractor is currently on. |
| `mqtt_connected` | boolean | Whether the MQTT client is connected to the broker. |
| `last_update` | string or null | Timestamp of last MQTT message received. |
| `sensors` | object | Per-sensor position and latest value. |
| `tex_sensor` | object | Exterior sensor position and latest value. |
| `humidity` | object | Per-sensor humidity values (h1–h5, hum_general). |
| `amoniaco` | float or null | Latest ammonia sensor reading in PPM. |
| `radiant_floor` | object | Radiant floor sensor values (temperatura1, temperatura3) with name and value. |

## GET /api/history

Returns historical temperature and humidity data from Ubidots API.

- **Parameters:**
  - `start` (required): Start date in `YYYY-MM-DD` format
  - `end` (required): End date in `YYYY-MM-DD` format
- **Response:** JSON object with timestamped values per variable

### Example Request

```
GET /api/history?start=2026-03-25&end=2026-03-27
```

### Response

```json
{
  "timestamps": [1711324800000, 1711324802000, ...],
  "temperature": {
    "t1": [{"timestamp": 1711324800000, "value": 25.3}, ...],
    "t2": [...],
    ...
  },
  "humidity": {
    "h1": [{"timestamp": 1711324800000, "value": 46.0}, ...],
    ...
  }
}
```

## GET /api/history/interpolate

Interpolates a 3D volume for a specific moment using provided sensor values.

- **Parameters:**
  - `temps` (required): JSON string with temperature values, e.g. `{"t1":25,"t2":24,...}`
  - `hums` (optional): JSON string with humidity values, e.g. `{"h1":46,"h2":21,...}`
- **Response:** JSON with `volume_data` and `humidity_volume_data`

### Error Response (503)

Returned if the engine has not been initialized.

```json
{
  "error": "Engine not initialized"
}
```
