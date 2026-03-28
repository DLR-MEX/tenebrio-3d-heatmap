"""
Simulador MQTT para pruebas locales.

Publica datos de sensores aleatorios cada 2 segundos al mismo tópico
al que se suscribe la aplicación real, usando un broker MQTT local
(por ejemplo, Mosquitto en localhost).

Uso:
    python mqtt_simulator.py [--broker BROKER] [--port PORT]
"""

import argparse
import json
import os
import random
import sys
import time
import logging

# Agrega backend/ al path para importar config
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "backend"))

import paho.mqtt.client as mqtt

import config

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
logger = logging.getLogger(__name__)

# Rangos de temperatura para simulación
TEMP_BASE = 25.0
TEMP_VARIATION = 3.0
EXT_TEMP_BASE = 32.0
EXT_TEMP_VARIATION = 2.0


def generate_payload() -> dict:
    """Genera un payload de sensores aleatorio."""
    return {
        "t1": round(TEMP_BASE + random.uniform(-TEMP_VARIATION, TEMP_VARIATION), 1),
        "t2": round(TEMP_BASE + random.uniform(-TEMP_VARIATION, TEMP_VARIATION), 1),
        "t3": round(TEMP_BASE + random.uniform(-TEMP_VARIATION, TEMP_VARIATION), 1),
        "t4": round(TEMP_BASE + random.uniform(-TEMP_VARIATION, TEMP_VARIATION), 1),
        "t5": round(TEMP_BASE + random.uniform(-TEMP_VARIATION, TEMP_VARIATION), 1),
        "t_ext": round(EXT_TEMP_BASE + random.uniform(-EXT_TEMP_VARIATION, EXT_TEMP_VARIATION), 1),
        "ventilador": random.choice([0, 1]),
        "extractor": random.choice([0, 1]),
    }


def main():
    parser = argparse.ArgumentParser(description="Simulador de datos de temperatura MQTT")
    parser.add_argument("--broker", default=config.MQTT_BROKER, help="Dirección del broker MQTT")
    parser.add_argument("--port", type=int, default=config.MQTT_PORT, help="Puerto del broker MQTT")
    args = parser.parse_args()

    client = mqtt.Client(
        callback_api_version=mqtt.CallbackAPIVersion.VERSION2,
        client_id="simulator",
    )

    # Autenticación con Ubidots (usuario = token, sin contraseña)
    client.username_pw_set(config.UBIDOTS_TOKEN, "")

    topic = config.MQTT_TOPIC
    logger.info("Connecting to %s:%d ...", args.broker, args.port)
    client.connect(args.broker, args.port, keepalive=60)
    client.loop_start()

    logger.info("Publishing to topic: %s  (Ctrl+C to stop)", topic)

    try:
        while True:
            payload = generate_payload()
            message = json.dumps(payload)
            client.publish(topic, message)
            logger.info("Published: %s", message)
            time.sleep(2)
    except KeyboardInterrupt:
        logger.info("Simulator stopped.")
    finally:
        client.loop_stop()
        client.disconnect()


if __name__ == "__main__":
    main()
