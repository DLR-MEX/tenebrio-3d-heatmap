"""
Pruebas para el sistema de caché de interpolación del HeatmapEngine.

Verifica que la interpolación solo se recalcula cuando llegan datos nuevos,
y que múltiples llamadas sin update() retornan el resultado cacheado.
"""

import threading

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


def _humidity_data():
    """Retorna un conjunto completo de lecturas de humedad."""
    return {
        "h1": 60.0,
        "h2": 65.0,
        "h3": 70.0,
        "h4": 55.0,
        "h5": 62.0,
    }


class TestInterpolationCache:
    def test_cached_result_is_same_object(self, engine):
        """Dos llamadas consecutivas sin update() deben retornar el mismo resultado."""
        engine.update(_full_sensor_data())
        result1 = engine.interpolate_volume()
        result2 = engine.interpolate_volume()

        assert result1 is result2

    def test_cache_invalidated_on_update(self, engine):
        """Después de update(), interpolate_volume() debe retornar datos nuevos."""
        engine.update(_full_sensor_data())
        result1 = engine.interpolate_volume()

        engine.update({"t1": 30.0})
        result2 = engine.interpolate_volume()

        assert result1 is not result2
        assert result2 is not None

    def test_humidity_cache_works(self, engine):
        """El caché de humedad también debe funcionar."""
        data = {**_full_sensor_data(), **_humidity_data()}
        engine.update(data)
        result1 = engine.interpolate_humidity_volume()
        result2 = engine.interpolate_humidity_volume()

        assert result1 is result2

    def test_humidity_cache_invalidated_on_update(self, engine):
        """Después de update(), la humedad cacheada debe recalcularse."""
        data = {**_full_sensor_data(), **_humidity_data()}
        engine.update(data)
        result1 = engine.interpolate_humidity_volume()

        engine.update({"h1": 80.0})
        result2 = engine.interpolate_humidity_volume()

        assert result1 is not result2

    def test_no_recompute_without_new_data(self, engine):
        """Múltiples llamadas sin update() no deben marcar dirty."""
        engine.update(_full_sensor_data())
        engine.interpolate_volume()

        # El flag dirty debe ser False después de interpolar
        assert not engine._dirty

        # Llamar de nuevo no debe cambiar nada
        engine.interpolate_volume()
        assert not engine._dirty

    def test_concurrent_calls_no_duplicate_compute(self, engine):
        """Llamadas concurrentes no deben causar doble cómputo."""
        engine.update(_full_sensor_data())

        results = [None, None]
        errors = []

        def call_interpolate(idx):
            try:
                results[idx] = engine.interpolate_volume()
            except Exception as e:
                errors.append(e)

        t1 = threading.Thread(target=call_interpolate, args=(0,))
        t2 = threading.Thread(target=call_interpolate, args=(1,))
        t1.start()
        t2.start()
        t1.join()
        t2.join()

        assert not errors
        assert results[0] is not None
        assert results[1] is not None
        # Ambos deben retornar el mismo objeto cacheado
        assert results[0] is results[1]

    def test_initial_state_returns_none(self, engine):
        """Sin datos, el caché debe retornar None."""
        result = engine.interpolate_volume()
        assert result is None

    def test_initial_humidity_returns_none(self, engine):
        """Sin datos de humedad, el caché debe retornar None."""
        result = engine.interpolate_humidity_volume()
        assert result is None
