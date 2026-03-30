"""
Motor de interpolación del mapa de calor (volumétrico 3D).

Almacena las últimas temperaturas de los sensores y produce un volumen
3D interpolado usando scipy.interpolate.griddata.
"""

import logging
import threading
from datetime import datetime
from typing import Optional

import numpy as np
from scipy.interpolate import griddata

import config

logger = logging.getLogger(__name__)


def _is_valid_temperature(value: float) -> bool:
    """Retorna True si el valor está dentro del rango físicamente plausible."""
    return config.TEMP_VALID_MIN <= value <= config.TEMP_VALID_MAX


class HeatmapEngine:
    """Almacén de temperatura thread-safe con interpolación volumétrica 3D."""

    def __init__(self):
        self._lock = threading.Lock()

        self._temperatures: dict[str, float] = {}
        self._exterior_temp: Optional[float] = None
        self._fan_state: bool = False
        self._extractor_state: bool = False
        self._avg_temp_superior: Optional[float] = None
        self._avg_temp_inferior: Optional[float] = None
        self._humidity: dict[str, float] = {}
        self._ammonia_ppm: Optional[float] = None
        self._radiant_floor: dict[str, float] = {}
        self._last_update: Optional[str] = None

        self._sensor_labels = list(config.SENSOR_POSITIONS.keys())
        self._sensor_coords = np.array(
            [config.SENSOR_POSITIONS[s] for s in self._sensor_labels]
        )

        # Pre-calcula el meshgrid 3D aplanado para el trazo de volumen de Plotly.
        # Plotly espera flat_index = ix + nx*(iy + ny*iz), es decir x-más-rápido.
        # meshgrid(gz, gy, gx, indexing="ij") -> forma (nz, ny, nx),
        # así ravel() en orden C da z-más-lento / x-más-rápido = lo que Plotly necesita.
        gx = np.linspace(config.ROOM_X_MIN, config.ROOM_X_MAX, config.GRID_RES_X)
        gy = np.linspace(config.ROOM_Y_MIN, config.ROOM_Y_MAX, config.GRID_RES_Y)
        gz = np.linspace(config.ROOM_Z_MIN, config.ROOM_Z_MAX, config.GRID_RES_Z)
        mz, my, mx = np.meshgrid(gz, gy, gx, indexing="ij")
        self._grid_x = mx.ravel()
        self._grid_y = my.ravel()
        self._grid_z = mz.ravel()
        self._grid_points = np.column_stack([self._grid_x, self._grid_y, self._grid_z])

    # ------------------------------------------------------------------
    # Ingesta de datos
    # ------------------------------------------------------------------

    def update(self, data: dict) -> None:
        """Fusiona datos entrantes de sensores en el almacén interno.

        Los valores fuera del rango físico válido se descartan silenciosamente.
        """
        with self._lock:
            self._last_update = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            for label in self._sensor_labels:
                if label in data:
                    value = data[label]
                    if _is_valid_temperature(value):
                        self._temperatures[label] = value
                    else:
                        logger.warning("Rejected %s=%.1f: outside valid range", label, value)

            if config.EXTERIOR_TEMP_LABEL in data:
                value = data[config.EXTERIOR_TEMP_LABEL]
                if _is_valid_temperature(value):
                    self._exterior_temp = value
                else:
                    logger.warning("Rejected tex=%.1f: outside valid range", value)

            if config.FAN_LABEL in data:
                self._fan_state = data[config.FAN_LABEL] >= 1.0
            if config.EXTRACTOR_LABEL in data:
                self._extractor_state = data[config.EXTRACTOR_LABEL] >= 1.0

            # Temperaturas promedio (superior e inferior)
            if config.AVG_TEMP_SUPERIOR_LABEL in data:
                value = data[config.AVG_TEMP_SUPERIOR_LABEL]
                if _is_valid_temperature(value):
                    self._avg_temp_superior = value
            if config.AVG_TEMP_INFERIOR_LABEL in data:
                value = data[config.AVG_TEMP_INFERIOR_LABEL]
                if _is_valid_temperature(value):
                    self._avg_temp_inferior = value

            # Sensores de humedad
            for label in config.HUMIDITY_LABELS:
                if label in data:
                    self._humidity[label] = data[label]

            # Sensores del piso radiante
            for label in config.RADIANT_FLOOR_LABELS:
                if label in data:
                    self._radiant_floor[label] = data[label]

            # Sensor de amoníaco
            if config.AMMONIA_LABEL in data:
                self._ammonia_ppm = data[config.AMMONIA_LABEL]

    # ------------------------------------------------------------------
    # Interpolación 3D
    # ------------------------------------------------------------------

    def interpolate_volume(self) -> Optional[dict]:
        """Retorna arreglos de volumen 3D aplanados para Plotly, o None si no hay datos suficientes.

        Retorna dict con claves: x, y, z, value (todos listas 1D).
        """
        with self._lock:
            values = []
            coords = []
            for i, label in enumerate(self._sensor_labels):
                if label in self._temperatures:
                    values.append(self._temperatures[label])
                    coords.append(self._sensor_coords[i])

        if len(values) < 3:
            return None

        coords_arr = np.array(coords)
        values_arr = np.array(values)

        # Vecino más cercano siempre funciona y llena todo el volumen
        volume = griddata(
            coords_arr, values_arr, self._grid_points, method="nearest"
        )

        # Intenta lineal para mejor calidad dentro del casco convexo, mantiene nearest fuera
        try:
            linear = griddata(
                coords_arr, values_arr, self._grid_points, method="linear"
            )
            valid = ~np.isnan(linear)
            volume[valid] = linear[valid]
        except Exception:
            pass

        np.clip(volume, config.HEATMAP_VMIN, config.HEATMAP_VMAX, out=volume)

        return {
            "x": self._grid_x.tolist(),
            "y": self._grid_y.tolist(),
            "z": self._grid_z.tolist(),
            "value": volume.tolist(),
        }

    def interpolate_humidity_volume(self) -> Optional[dict]:
        """Retorna volumen 3D de humedad interpolada, o None si no hay datos suficientes.

        Los sensores h1-h5 comparten posiciones con t1-t5.
        """
        humidity_map = {"h1": 0, "h2": 1, "h3": 2, "h4": 3, "h5": 4}
        with self._lock:
            values = []
            coords = []
            for hlabel, idx in humidity_map.items():
                if hlabel in self._humidity:
                    values.append(self._humidity[hlabel])
                    coords.append(self._sensor_coords[idx])

        if len(values) < 3:
            return None

        coords_arr = np.array(coords)
        values_arr = np.array(values)

        volume = griddata(
            coords_arr, values_arr, self._grid_points, method="nearest"
        )
        try:
            linear = griddata(
                coords_arr, values_arr, self._grid_points, method="linear"
            )
            valid = ~np.isnan(linear)
            volume[valid] = linear[valid]
        except Exception:
            pass

        np.clip(volume, 0, 100, out=volume)

        return {
            "x": self._grid_x.tolist(),
            "y": self._grid_y.tolist(),
            "z": self._grid_z.tolist(),
            "value": volume.tolist(),
        }

    # ------------------------------------------------------------------
    # Accesores
    # ------------------------------------------------------------------

    def get_sensor_value(self, label: str) -> Optional[float]:
        with self._lock:
            return self._temperatures.get(label)

    def get_exterior_temp(self) -> Optional[float]:
        with self._lock:
            return self._exterior_temp

    def get_fan_state(self) -> bool:
        with self._lock:
            return self._fan_state

    def get_extractor_state(self) -> bool:
        with self._lock:
            return self._extractor_state

    def get_avg_temp_superior(self) -> Optional[float]:
        with self._lock:
            return self._avg_temp_superior

    def get_avg_temp_inferior(self) -> Optional[float]:
        with self._lock:
            return self._avg_temp_inferior

    def get_humidity(self, label: str) -> Optional[float]:
        with self._lock:
            return self._humidity.get(label)

    def get_ammonia_ppm(self) -> Optional[float]:
        with self._lock:
            return self._ammonia_ppm

    def get_radiant_floor(self, label: str) -> Optional[float]:
        with self._lock:
            return self._radiant_floor.get(label)

    def get_last_update(self) -> Optional[str]:
        with self._lock:
            return self._last_update
