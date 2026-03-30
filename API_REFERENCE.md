# Referencia de API

## GET /

Renderiza la página principal del dashboard.

- **Respuesta:** Página HTML con el mapa de calor volumétrico 3D Plotly.js.
- **Content-Type:** `text/html`

El dashboard se actualiza automáticamente consultando `/api/data` cada 2 segundos (configurable vía `ANIMATION_INTERVAL_MS` en `backend/config.py`).

## GET /api/data

Retorna datos JSON para la visualización del mapa de calor 3D.

- **Respuesta:** Objeto JSON
- **Content-Type:** `application/json`

### Respuesta Exitosa (200)

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

### Campos

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `volume_data` | objeto o null | Volumen 3D de temperatura interpolado. Null si menos de 3 sensores reportaron. |
| `humidity_volume_data` | objeto o null | Volumen 3D de humedad interpolado. Null si menos de 3 sensores reportaron. |
| `x_range` | arreglo | Límites X del cuarto en metros `[min, max]`. |
| `y_range` | arreglo | Límites Y del cuarto en metros `[min, max]`. |
| `z_range` | arreglo | Límites Z del cuarto en metros `[min, max]`. |
| `vmin` | float | Temperatura mínima para la escala de color (14°C). |
| `vmax` | float | Temperatura máxima para la escala de color (35°C). |
| `exterior_temp` | float o null | Última lectura del sensor exterior (tex). |
| `avg_temp_superior` | float o null | Temperatura promedio de sensores superiores (tps). |
| `avg_temp_inferior` | float o null | Temperatura promedio de sensores inferiores (tpi). |
| `fan_on` | booleano | Si el ventilador está actualmente encendido. |
| `extractor_on` | booleano | Si el extractor está actualmente encendido. |
| `mqtt_connected` | booleano | Si el cliente MQTT está conectado al broker. |
| `last_update` | cadena o null | Timestamp del último mensaje MQTT recibido. |
| `sensors` | objeto | Posición y último valor por sensor. |
| `tex_sensor` | objeto | Posición y último valor del sensor exterior. |
| `humidity` | objeto | Valores de humedad por sensor (h1–h5, hum_general). |
| `amoniaco` | float o null | Última lectura del sensor de amoníaco en PPM. |
| `radiant_floor` | objeto | Valores de los sensores del piso radiante (temperatura1, temperatura3) con nombre y valor. |

## GET /api/history

Retorna datos históricos de temperatura y humedad desde la API de Ubidots.

- **Parámetros:**
  - `start` (requerido): Fecha de inicio en formato `YYYY-MM-DD`
  - `end` (requerido): Fecha de fin en formato `YYYY-MM-DD`
- **Respuesta:** Objeto JSON con valores por variable con timestamps

### Ejemplo de Solicitud

```
GET /api/history?start=2026-03-25&end=2026-03-27
```

### Respuesta

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

Interpola un volumen 3D para un momento específico usando valores de sensores proporcionados.

- **Parámetros:**
  - `temps` (requerido): Cadena JSON con valores de temperatura, ej. `{"t1":25,"t2":24,...}`
  - `hums` (opcional): Cadena JSON con valores de humedad, ej. `{"h1":46,"h2":21,...}`
- **Respuesta:** JSON con `volume_data` y `humidity_volume_data`

### Respuesta de Error (503)

Retornado si el motor no ha sido inicializado.

```json
{
  "error": "Engine not initialized"
}
```
