"""
Punto de entrada de la aplicación de mapa de calor de temperatura en tiempo real.

Inicializa el cliente MQTT (solo suscripción) e inicia el servidor web
Flask para mostrar el dashboard del mapa de calor.
"""

import logging

from heatmap_engine import HeatmapEngine
from log_config import setup_logging
from mqtt_client import MqttClient
import visualization

setup_logging(level=logging.INFO)
logger = logging.getLogger(__name__)


def main():
    engine = HeatmapEngine()

    def on_mqtt_data(data):
        """Actualiza datos y pre-calcula la interpolación para que el caché esté listo."""
        engine.update(data)
        engine.interpolate_volume()

    client = MqttClient(on_data=on_mqtt_data)

    visualization.set_engine(engine)
    visualization.set_mqtt_status(client.is_connected)

    try:
        client.start()
        logger.info("MQTT client started (subscribe-only). Launching web server...")
        visualization.start(host="0.0.0.0", port=5000)
    except KeyboardInterrupt:
        logger.info("Interrupted by user.")
    finally:
        client.stop()
        logger.info("Application shut down.")


if __name__ == "__main__":
    main()
