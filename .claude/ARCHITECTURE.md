ARQUITECTURA DEL SISTEMA

Sensores
   │
   │ (publican a Ubidots)
   ▼
Broker MQTT de Ubidots
   │
   │ (suscripción /lv)
   ▼
Cliente MQTT local (mqtt_client.py)
   │
   ▼
Motor de almacenamiento de temperatura (heatmap_engine.py)
   │
   ▼
Interpolación volumétrica 3D
   │
   ▼
Servidor API Flask (visualization.py)
   │
   ▼
Frontend Plotly.js (templates/index.html)