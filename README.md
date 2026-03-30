# Mapa de Calor 3D en Tiempo Real — Temperatura y Humedad

Aplicación Python que genera un mapa de calor volumétrico 3D en tiempo real de un cuarto de cría de tenebrios, usando datos de temperatura y humedad recibidos desde Ubidots vía MQTT.

## Descripción General

Este sistema monitorea la distribución de temperatura y humedad interna de un cuarto de cría de Tenebrio molitor usando 5 sensores interiores y 1 sensor exterior. Produce un mapa de calor 3D interactivo que se actualiza en tiempo real, permitiendo a los operadores detectar gradientes térmicos, puntos calientes y zonas frías. El dashboard soporta cambio entre vistas de temperatura y humedad.

## Características

- Suscripción MQTT en tiempo real a la plataforma IoT Ubidots
- Interpolación volumétrica 3D con scipy griddata (temperatura y humedad)
- Cambio entre vistas de Temperatura y Humedad en el render 3D
- Dashboard interactivo Plotly.js con renderizado de isosuperficies
- Visor de datos históricos con slider de línea de tiempo (consulta API de Ubidots)
- Monitoreo de temperatura exterior (sensor tex) con zona coloreada en el render
- Indicadores de temperatura promedio (superior/inferior)
- Monitoreo de humedad (h1–h5, hum_general) con barras codificadas por color
- Monitoreo de amoníaco (PPM) con barra codificada por color
- Termómetros verticales por sensor con colores interpolados
- Visualización del sistema de piso radiante (losa de concreto, tuberías serpentín, sensores)
- Sala de máquinas con rotoplas, calentador solar, termo y circuito hidráulico completo
- Sensores de sala de máquinas: calentador solar, termo (escala 15-90°C), entrada cuarto
- Válvulas V1 y V2 con distribución en "H" para el piso radiante
- Geometría cilíndrica real (mesh3d triangulado) para rotoplas, termo y tanque solar
- Indicadores de temperatura del piso radiante (salida, medio piso)
- Modo "Solo Piso" para visualizar únicamente el piso radiante sin isosuperficies
- Widgets SVG animados de ventilador y extractor
- Marcas de rango ideal en barras de temperatura (23–28°C) y humedad (60–88%)
- Estado de conexión MQTT y visualización de timestamp
- Wireframe 3D: techo inclinado, ventanas, mueble, lámparas vintage, jardinera, corredor techado
- Vista isométrica con rotación solo horizontal (teclado con flechas)
- Diseño responsivo (escritorio, tablet, móvil vertical y horizontal)
- Interfaz con marca TECHNEBRIOS e Ingeniería Condor
- Fuente Orbitron para visualización de fecha/hora
- Actualización automática cada 2 segundos

## Arquitectura del Sistema

Ver [ARCHITECTURE.md](ARCHITECTURE.md) para el diagrama completo y descripción de componentes.

```
Sensores → Cliente MQTT → Motor Heatmap → API Flask → Frontend (Plotly.js)
```

## Instalación

Ver [INSTALLATION.md](INSTALLATION.md) para instrucciones detalladas de configuración y despliegue en Raspberry Pi.

```bash
pip install -r requirements.txt
python backend/main.py
```

## API

Ver [API_REFERENCE.md](API_REFERENCE.md) para documentación de endpoints.

| Endpoint | Descripción |
|----------|-------------|
| `GET /` | Dashboard con mapa de calor 3D |
| `GET /api/data` | Datos JSON para visualización en tiempo real |
| `GET /api/history` | Datos históricos desde Ubidots |
| `GET /api/history/interpolate` | Interpolación del lado del servidor para frames históricos |

## Estructura del Proyecto

```
tenebrio-3d-heatmap/
├── backend/
│   ├── config.py            # Constantes de configuración
│   ├── main.py              # Punto de entrada de la aplicación
│   ├── mqtt_client.py       # Conexión MQTT y parseo de payloads
│   ├── heatmap_engine.py    # Almacenamiento temp/humedad e interpolación 3D
│   └── visualization.py     # Servidor web Flask y API
├── templates/
│   └── index.html           # Dashboard Plotly.js con mapa de calor 3D
├── static/
│   └── CondorLogo.png       # Logo Ingeniería Condor
├── tests/
│   ├── test_interpolation.py
│   └── test_mqtt_parser.py
├── mqtt_simulator.py        # Publicador de datos de prueba local
├── requirements.txt
├── ARCHITECTURE.md
├── SYSTEM_DESCRIPTION.md
├── API_REFERENCE.md
├── INSTALLATION.md
└── README.md
```

## Modo Simulación (Pruebas Locales)

Para pruebas sin un dispositivo Ubidots real, usa el simulador con un broker MQTT local (ej. Mosquitto):

1. Inicia tu broker local (ej. `mosquitto`).
2. Actualiza `backend/config.py`:
   ```python
   MQTT_BROKER = "localhost"
   UBIDOTS_TOKEN = ""
   ```
3. En una terminal: `python mqtt_simulator.py`
4. En otra terminal: `python backend/main.py`

## Ejecutar Tests

```bash
pytest tests/ -v
```
