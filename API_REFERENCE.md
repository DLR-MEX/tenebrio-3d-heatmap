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
  "x_range": [0, 10],
  "y_range": [0, 6],
  "z_range": [0, 3],
  "vmin": 15.0,
  "vmax": 40.0,
  "exterior_temp": 25.0,
  "fan_on": true,
  "extractor_on": false,
  "mqtt_connected": true,
  "sensors": {
    "t1": {"x": 2, "y": 3, "z": 2.5, "value": 25.3},
    "t2": {"x": 5, "y": 3, "z": 2.5, "value": 24.5},
    "t3": {"x": 8, "y": 3, "z": 2.5, "value": 25.3},
    "t4": {"x": 3, "y": 3, "z": 1.0, "value": 22.6},
    "t5": {"x": 7, "y": 3, "z": 1.0, "value": 23.0}
  },
  "tex_sensor": {
    "x": 6.5,
    "y": -0.15,
    "z": 0.8,
    "value": 25.0
  },
  "avg_temp_superior": 25.5,
  "avg_temp_inferior": 23.0,
  "humidity": {
    "h1": 46.0,
    "h2": 21.0,
    "h3": 46.0,
    "h4": 44.0,
    "h5": 43.0,
    "hum_general": null
  },
  "amoniaco": null
}
```

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `volume_data` | object or null | Interpolated 3D volume with flat arrays `x`, `y`, `z`, `value`. Null if fewer than 3 sensors have reported. |
| `x_range` | array | Room X boundaries in meters `[min, max]`. |
| `y_range` | array | Room Y boundaries in meters `[min, max]`. |
| `z_range` | array | Room Z boundaries in meters `[min, max]`. |
| `vmin` | float | Minimum temperature for the color scale. |
| `vmax` | float | Maximum temperature for the color scale. |
| `exterior_temp` | float or null | Latest exterior sensor (tex) reading. |
| `avg_temp_superior` | float or null | Average upper sensors temperature (tps). |
| `avg_temp_inferior` | float or null | Average lower sensors temperature (tpi). |
| `fan_on` | boolean | Whether the fan is currently on. |
| `extractor_on` | boolean | Whether the extractor is currently on. |
| `mqtt_connected` | boolean | Whether the MQTT client is connected to the broker. |
| `sensors` | object | Per-sensor position and latest value. Value is null if no reading received yet. |
| `tex_sensor` | object | Exterior sensor position and latest value. |
| `humidity` | object | Per-sensor humidity values (h1–h5, hum_general). Value is null if no reading received yet. |
| `amoniaco` | float or null | Latest ammonia sensor reading in PPM. |

### Error Response (503)

Returned if the engine has not been initialized.

```json
{
  "error": "Engine not initialized"
}
```
