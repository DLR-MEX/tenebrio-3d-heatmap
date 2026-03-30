"""
Módulo cliente MQTT para comunicación con Ubidots.

Se suscribe a /v1.6/devices/{device}/+/lv y reenvía las lecturas
parseadas a un callback. Los payloads /lv de Ubidots son cadenas
numéricas planas, NO JSON.
"""

import logging
from typing import Callable, Optional

import paho.mqtt.client as mqtt

import config

logger = logging.getLogger(__name__)

# Todas las etiquetas de variables que nos interesan
ALL_VARIABLES = (
    list(config.SENSOR_POSITIONS.keys())
    + [config.EXTERIOR_TEMP_LABEL, config.FAN_LABEL, config.EXTRACTOR_LABEL]
    + [config.AVG_TEMP_SUPERIOR_LABEL, config.AVG_TEMP_INFERIOR_LABEL]
    + list(config.RADIANT_FLOOR_LABELS.keys())
    + config.HUMIDITY_LABELS
    + [config.AMMONIA_LABEL]
)

# Tópico comodín para recibir todas las variables del dispositivo
SUBSCRIBE_TOPIC = f"/v1.6/devices/{config.DEVICE_LABEL}/+/lv"


def parse_lv_message(topic: str, payload_raw: bytes) -> Optional[dict]:
    """Parsea un mensaje /lv (último valor) de Ubidots.

    Formato del tópico: /v1.6/devices/{device}/{variable}/lv
    Payload: cadena numérica plana como "25.4"

    Retorna un dict de una sola clave como {"t1": 25.4} o None en caso de error.
    """
    try:
        parts = topic.strip("/").split("/")
        # Esperado: ["v1.6", "devices", "{device}", "{variable}", "lv"]
        if len(parts) < 5 or parts[-1] != "lv":
            return None
        variable_label = parts[3]
    except (IndexError, AttributeError):
        return None

    if variable_label not in ALL_VARIABLES:
        logger.debug("Ignoring unknown variable: %s", variable_label)
        return None

    try:
        value = float(payload_raw.decode("utf-8").strip())
    except (ValueError, UnicodeDecodeError):
        logger.warning("Cannot parse value for '%s': %r", variable_label, payload_raw)
        return None

    return {variable_label: value}


class MqttClient:
    """Administra la conexión MQTT a Ubidots (solo suscripción)."""

    def __init__(self, on_data: Callable[[dict], None]):
        self._on_data = on_data
        self._connected = False
        self._client = mqtt.Client(
            callback_api_version=mqtt.CallbackAPIVersion.VERSION2,
            client_id="",
            protocol=mqtt.MQTTv311,
        )
        self._client.username_pw_set(config.UBIDOTS_TOKEN, "")
        self._client.on_connect = self._on_connect
        self._client.on_disconnect = self._on_disconnect
        self._client.on_message = self._on_message
        self._client.reconnect_delay_set(min_delay=1, max_delay=60)

    # ------------------------------------------------------------------
    # Callbacks
    # ------------------------------------------------------------------

    def _on_connect(self, client, userdata, flags, reason_code, properties=None):
        if reason_code == 0:
            self._connected = True
            logger.info("Connected to MQTT broker at %s:%d",
                        config.MQTT_BROKER, config.MQTT_PORT)
            client.subscribe(SUBSCRIBE_TOPIC)
            logger.info("Subscribed to: %s", SUBSCRIBE_TOPIC)
        else:
            self._connected = False
            logger.error("Connection failed with reason code: %s", reason_code)

    def _on_disconnect(self, client, userdata, flags, reason_code, properties=None):
        self._connected = False
        if reason_code != 0:
            logger.warning(
                "Unexpected disconnection (rc=%s). Paho will auto-reconnect.",
                reason_code,
            )
        else:
            logger.info("Disconnected cleanly from broker.")

    def _on_message(self, client, userdata, msg):
        data = parse_lv_message(msg.topic, msg.payload)
        if data:
            logger.info("Received: %s", data)
            self._on_data(data)

    # ------------------------------------------------------------------
    # API pública
    # ------------------------------------------------------------------

    def is_connected(self) -> bool:
        """Retorna True si está conectado al broker MQTT."""
        return self._connected

    def start(self):
        """Conecta e inicia el loop de red en segundo plano."""
        logger.info("Connecting to %s:%d ...", config.MQTT_BROKER, config.MQTT_PORT)
        self._client.connect_async(config.MQTT_BROKER, config.MQTT_PORT, keepalive=60)
        self._client.loop_start()

    def stop(self):
        """Desconecta y detiene el loop."""
        self._client.loop_stop()
        self._client.disconnect()
        logger.info("MQTT client stopped.")
