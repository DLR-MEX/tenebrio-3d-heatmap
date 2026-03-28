"""
Pruebas para el motor de interpolación volumétrica 3D del mapa de calor.
"""

import numpy as np
import pytest

from heatmap_engine import HeatmapEngine


@pytest.fixture
def engine():
    return HeatmapEngine()


def _full_sensor_data():
    """Retorna un conjunto completo de lecturas de sensores."""
    return {
        "t1": 24.0,
        "t2": 26.0,
        "t3": 25.0,
        "t4": 27.0,
        "t5": 23.0,
    }


class TestInterpolateVolume:
    def test_returns_none_with_insufficient_data(self, engine):
        """La interpolación requiere al menos 3 sensores; menos debe retornar None."""
        engine.update({"t1": 25.0})
        assert engine.interpolate_volume() is None

        engine.update({"t2": 26.0})
        assert engine.interpolate_volume() is None

    def test_returns_volume_with_three_sensors(self, engine):
        """Con exactamente 3 sensores, la interpolación debe producir arreglos válidos."""
        engine.update({"t1": 24.0, "t2": 26.0, "t3": 25.0})
        result = engine.interpolate_volume()

        assert result is not None
        assert set(result.keys()) == {"x", "y", "z", "value"}
        # 25 * 18 * 12 = 5400 puntos
        assert len(result["x"]) == 5400
        assert len(result["value"]) == 5400

    def test_returns_valid_volume_with_all_sensors(self, engine):
        """Datos completos de sensores deben producir un volumen sin NaN."""
        engine.update(_full_sensor_data())
        result = engine.interpolate_volume()

        assert result is not None
        values = np.array(result["value"])
        assert not np.isnan(values).any(), "El volumen no debe contener valores NaN"

    def test_volume_values_within_clamp_range(self, engine):
        """Los valores interpolados deben estar acotados entre [VMIN, VMAX]."""
        engine.update(_full_sensor_data())
        result = engine.interpolate_volume()
        values = np.array(result["value"])

        from config import HEATMAP_VMIN, HEATMAP_VMAX
        assert values.min() >= HEATMAP_VMIN
        assert values.max() <= HEATMAP_VMAX

    def test_partial_update_preserves_previous(self, engine):
        """Actualizar solo algunos sensores debe conservar los valores previos."""
        engine.update(_full_sensor_data())
        engine.update({"t1": 30.0})

        result = engine.interpolate_volume()
        assert result is not None
        values = np.array(result["value"])
        assert not np.isnan(values).any()

    def test_rejects_impossible_temperature(self, engine):
        """Los valores fuera del rango físico válido deben ser descartados."""
        engine.update({"t1": 24.0, "t2": 26.0, "t3": 25.0})
        # Este debe ser rechazado (>80 °C)
        engine.update({"t1": 200.0})

        # t1 debe seguir siendo 24.0, no 200.0
        assert engine.get_sensor_value("t1") == 24.0

    def test_rejects_negative_impossible_temperature(self, engine):
        """Los valores extremadamente bajos deben ser descartados."""
        engine.update({"t1": 24.0, "t2": 26.0, "t3": 25.0})
        engine.update({"t2": -50.0})

        assert engine.get_sensor_value("t2") == 26.0
