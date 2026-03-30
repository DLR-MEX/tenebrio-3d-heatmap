"""
Servidor web Flask para visualización de mapa de calor volumétrico 3D en tiempo real.

Sirve una página HTML con un trazo de volumen Plotly.js que se actualiza
automáticamente consultando un endpoint de API JSON.
"""

import json
import logging
import os
import urllib.request
import urllib.error
from datetime import datetime
from typing import Callable

from flask import Flask, jsonify, render_template, request

import config
from heatmap_engine import HeatmapEngine

logger = logging.getLogger(__name__)

app = Flask(
    __name__,
    template_folder=os.path.join(os.path.dirname(__file__), "..", "templates"),
    static_folder=os.path.join(os.path.dirname(__file__), "..", "static"),
)

_engine: HeatmapEngine = None
_mqtt_status: Callable[[], bool] = lambda: False


def set_engine(engine: HeatmapEngine):
    """Inyecta la instancia compartida de HeatmapEngine."""
    global _engine
    _engine = engine


def set_mqtt_status(status_fn: Callable[[], bool]):
    """Inyecta un callable que retorna el estado de conexión MQTT."""
    global _mqtt_status
    _mqtt_status = status_fn


@app.route("/")
def index():
    return render_template("index.html", refresh_ms=config.ANIMATION_INTERVAL_MS)


@app.route("/api/data")
def api_data():
    if _engine is None:
        return jsonify({"error": "Engine not initialized"}), 503

    volume = _engine.interpolate_volume()
    humidity_volume = _engine.interpolate_humidity_volume()

    sensor_values = {}
    for label in config.SENSOR_POSITIONS:
        val = _engine.get_sensor_value(label)
        if val is not None:
            sensor_values[label] = round(val, 1)

    ext_temp = _engine.get_exterior_temp()
    tex_sensor = {
        "x": config.TEX_POSITION[0],
        "y": config.TEX_POSITION[1],
        "z": config.TEX_POSITION[2],
        "value": round(ext_temp, 1) if ext_temp is not None else None,
    }

    avg_sup = _engine.get_avg_temp_superior()
    avg_inf = _engine.get_avg_temp_inferior()

    return jsonify({
        "volume_data": volume,
        "humidity_volume_data": humidity_volume,
        "x_range": [config.ROOM_X_MIN, config.ROOM_X_MAX],
        "y_range": [config.ROOM_Y_MIN, config.ROOM_Y_MAX],
        "z_range": [config.ROOM_Z_MIN, config.ROOM_Z_MAX],
        "vmin": config.HEATMAP_VMIN,
        "vmax": config.HEATMAP_VMAX,
        "exterior_temp": ext_temp,
        "avg_temp_superior": round(avg_sup, 1) if avg_sup is not None else None,
        "avg_temp_inferior": round(avg_inf, 1) if avg_inf is not None else None,
        "fan_on": _engine.get_fan_state(),
        "extractor_on": _engine.get_extractor_state(),
        "mqtt_connected": _mqtt_status(),
        "sensors": {
            label: {
                "x": pos[0], "y": pos[1], "z": pos[2],
                "value": sensor_values.get(label),
            }
            for label, pos in config.SENSOR_POSITIONS.items()
        },
        "tex_sensor": tex_sensor,
        "humidity": {
            label: round(_engine.get_humidity(label), 1)
            if _engine.get_humidity(label) is not None else None
            for label in config.HUMIDITY_LABELS
        },
        "amoniaco": round(_engine.get_ammonia_ppm(), 2)
        if _engine.get_ammonia_ppm() is not None else None,
        "radiant_floor": {
            label: {
                "value": round(_engine.get_radiant_floor(label), 1)
                if _engine.get_radiant_floor(label) is not None else None,
                "name": desc,
            }
            for label, desc in config.RADIANT_FLOOR_LABELS.items()
        },
        "last_update": _engine.get_last_update(),
    })


def _fetch_ubidots_values(variable_label: str, start_ms: int, end_ms: int) -> list:
    """Consulta valores históricos de una variable en Ubidots."""
    url = (
        f"https://industrial.api.ubidots.com/api/v1.6/devices/"
        f"{config.DEVICE_LABEL}/{variable_label}/values"
        f"?start={start_ms}&end={end_ms}&page_size=5000"
    )
    req = urllib.request.Request(url)
    req.add_header("X-Auth-Token", config.UBIDOTS_TOKEN)
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            return data.get("results", [])
    except (urllib.error.URLError, Exception) as e:
        logger.warning("Error consultando Ubidots para %s: %s", variable_label, e)
        return []


@app.route("/api/history")
def api_history():
    """Retorna datos históricos de temperatura y humedad desde Ubidots.

    Parámetros: start (YYYY-MM-DD), end (YYYY-MM-DD)
    """
    start_date = request.args.get("start")
    end_date = request.args.get("end")
    if not start_date or not end_date:
        return jsonify({"error": "Parámetros start y end requeridos (YYYY-MM-DD)"}), 400

    try:
        start_ms = int(datetime.strptime(start_date, "%Y-%m-%d").timestamp() * 1000)
        end_ms = int(datetime.strptime(end_date, "%Y-%m-%d").timestamp() * 1000) + 86400000
    except ValueError:
        return jsonify({"error": "Formato de fecha inválido, usar YYYY-MM-DD"}), 400

    # Variables de temperatura y humedad
    temp_vars = list(config.SENSOR_POSITIONS.keys())
    hum_vars = ["h1", "h2", "h3", "h4", "h5"]

    result = {"timestamps": [], "temperature": {}, "humidity": {}}

    # Consultar cada variable
    all_timestamps = set()
    for var in temp_vars:
        values = _fetch_ubidots_values(var, start_ms, end_ms)
        result["temperature"][var] = [
            {"timestamp": v["timestamp"], "value": v["value"]} for v in values
        ]
        for v in values:
            all_timestamps.add(v["timestamp"])

    for var in hum_vars:
        values = _fetch_ubidots_values(var, start_ms, end_ms)
        result["humidity"][var] = [
            {"timestamp": v["timestamp"], "value": v["value"]} for v in values
        ]
        for v in values:
            all_timestamps.add(v["timestamp"])

    # Timestamps ordenados para el slider
    result["timestamps"] = sorted(all_timestamps)

    return jsonify(result)


@app.route("/api/history/interpolate")
def api_history_interpolate():
    """Interpola volumen 3D para un timestamp específico usando datos históricos del request."""
    if _engine is None:
        return jsonify({"error": "Engine not initialized"}), 503

    temp_data = request.args.get("temps")
    hum_data = request.args.get("hums")
    if not temp_data:
        return jsonify({"error": "Parámetro temps requerido"}), 400

    try:
        temps = json.loads(temp_data)
        hums = json.loads(hum_data) if hum_data else {}
    except (json.JSONDecodeError, TypeError):
        return jsonify({"error": "JSON inválido"}), 400

    # Crear engine temporal para interpolar
    import numpy as np
    from scipy.interpolate import griddata

    sensor_labels = list(config.SENSOR_POSITIONS.keys())
    sensor_coords = np.array([config.SENSOR_POSITIONS[s] for s in sensor_labels])

    # Interpolar temperatura
    t_values, t_coords = [], []
    for i, label in enumerate(sensor_labels):
        if label in temps and temps[label] is not None:
            t_values.append(temps[label])
            t_coords.append(sensor_coords[i])

    temp_vol = None
    if len(t_values) >= 3:
        t_coords_arr = np.array(t_coords)
        t_values_arr = np.array(t_values)
        volume = griddata(t_coords_arr, t_values_arr, _engine._grid_points, method="nearest")
        try:
            linear = griddata(t_coords_arr, t_values_arr, _engine._grid_points, method="linear")
            valid = ~np.isnan(linear)
            volume[valid] = linear[valid]
        except Exception:
            pass
        np.clip(volume, config.HEATMAP_VMIN, config.HEATMAP_VMAX, out=volume)
        temp_vol = {
            "x": _engine._grid_x.tolist(),
            "y": _engine._grid_y.tolist(),
            "z": _engine._grid_z.tolist(),
            "value": volume.tolist(),
        }

    # Interpolar humedad
    hum_map = {"h1": 0, "h2": 1, "h3": 2, "h4": 3, "h5": 4}
    h_values, h_coords = [], []
    for hlabel, idx in hum_map.items():
        if hlabel in hums and hums[hlabel] is not None:
            h_values.append(hums[hlabel])
            h_coords.append(sensor_coords[idx])

    hum_vol = None
    if len(h_values) >= 3:
        h_coords_arr = np.array(h_coords)
        h_values_arr = np.array(h_values)
        volume = griddata(h_coords_arr, h_values_arr, _engine._grid_points, method="nearest")
        try:
            linear = griddata(h_coords_arr, h_values_arr, _engine._grid_points, method="linear")
            valid = ~np.isnan(linear)
            volume[valid] = linear[valid]
        except Exception:
            pass
        np.clip(volume, 0, 100, out=volume)
        hum_vol = {
            "x": _engine._grid_x.tolist(),
            "y": _engine._grid_y.tolist(),
            "z": _engine._grid_z.tolist(),
            "value": volume.tolist(),
        }

    return jsonify({
        "volume_data": temp_vol,
        "humidity_volume_data": hum_vol,
    })


def start(host="0.0.0.0", port=5000):
    logger.info("Starting web server on http://%s:%d", host, port)
    app.run(host=host, port=port, debug=False, use_reloader=False)
