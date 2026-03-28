"""
Servidor web Flask para visualización de mapa de calor volumétrico 3D en tiempo real.

Sirve una página HTML con un trazo de volumen Plotly.js que se actualiza
automáticamente consultando un endpoint de API JSON.
"""

import logging
import os
from typing import Callable

from flask import Flask, jsonify, render_template

import config
from heatmap_engine import HeatmapEngine

logger = logging.getLogger(__name__)

app = Flask(
    __name__,
    template_folder=os.path.join(os.path.dirname(__file__), "..", "templates"),
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
    })


def start(host="0.0.0.0", port=5000):
    logger.info("Starting web server on http://%s:%d", host, port)
    app.run(host=host, port=port, debug=False, use_reloader=False)
