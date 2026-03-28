"""
Módulo de configuración para el sistema de mapa de calor en tiempo real.
"""

### CONFIGURACION ###

# Configuración MQTT / Ubidots
MQTT_BROKER = "industrial.api.ubidots.com"
MQTT_PORT = 1883
UBIDOTS_TOKEN = "BBUS-6T17NCkbJ8pBVzOGwAhSnNijg2wBtu"
DEVICE_LABEL = "tenebrios"

# Tópico MQTT para suscripción a todas las variables del dispositivo
MQTT_TOPIC = f"/v1.6/devices/{DEVICE_LABEL}"

# Etiquetas de sensores y sus coordenadas espaciales (x, y, z) en el cuarto
SENSOR_POSITIONS = {
    # Sensores superiores (centrados en Y=3)
    "t1": (2, 3, 2.5),
    "t2": (5, 3, 2.5),
    "t3": (8, 3, 2.5),
    # Sensores interiores (centro, altura inferior)
    "t4": (3, 3, 1.0),
    "t5": (7, 3, 1.0),
}

# Posición del sensor de temperatura exterior (sobre jardinera, pared trasera Y=6)
# La jardinera se ubica en X=1..3, Y=6..6.3, Z=0..0.7
TEX_POSITION = (2, 6.15, 0.8)

# Límites del cuarto (metros)
ROOM_X_MIN = 0
ROOM_X_MAX = 10
ROOM_Y_MIN = 0
ROOM_Y_MAX = 6
ROOM_Z_MIN = 0
ROOM_Z_MAX = 3

# Etiquetas de variables adicionales
EXTERIOR_TEMP_LABEL = "tex"
FAN_LABEL = "ventilador"
EXTRACTOR_LABEL = "extractor"

# Etiquetas de temperaturas promedio (superior e inferior)
AVG_TEMP_SUPERIOR_LABEL = "tps"
AVG_TEMP_INFERIOR_LABEL = "tpi"

# Etiquetas de sensores de humedad
HUMIDITY_LABELS = ["h1", "h2", "h3", "h4", "h5", "hum_general"]

# Etiqueta del sensor de amoníaco (PPM)
AMMONIA_LABEL = "amoniaco"

# Resolución de la grilla volumétrica 3D (puntos en X, Y, Z)
GRID_RES_X = 25
GRID_RES_Y = 18
GRID_RES_Z = 12

# Rango de temperatura para visualización (ideal: 20-30 °C)
HEATMAP_VMIN = 14.0
HEATMAP_VMAX = 35.0

# Rango válido de temperatura física (rechazar lecturas fuera de este rango)
TEMP_VALID_MIN = -10.0
TEMP_VALID_MAX = 80.0

# Intervalo de actualización del dashboard web en milisegundos
ANIMATION_INTERVAL_MS = 2000

# Configuración del servidor web Flask
WEB_HOST = "0.0.0.0"
WEB_PORT = 5000
