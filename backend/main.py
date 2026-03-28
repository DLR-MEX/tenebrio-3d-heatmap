"""
Punto de entrada de la aplicación de mapa de calor de temperatura en tiempo real.

Inicializa el cliente MQTT (solo suscripción) e inicia el servidor web
Flask para mostrar el dashboard del mapa de calor.
"""

import logging

from heatmap_engine import HeatmapEngine
from mqtt_client import MqttClient
import visualization

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger(__name__)


def main():
    engine = HeatmapEngine()
    client = MqttClient(on_data=engine.update)

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
