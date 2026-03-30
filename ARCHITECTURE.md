# Arquitectura

## Componentes

- **Cliente MQTT** — Se conecta al broker MQTT de Ubidots y se suscribe a datos de sensores usando el formato de tópico `/lv` (último valor).
- **Motor Heatmap** — Almacena las últimas temperaturas, humedad y datos del piso radiante. Produce volúmenes 3D interpolados de temperatura y humedad usando `scipy.interpolate.griddata`.
- **Servidor API** — Servidor web Flask que expone endpoints JSON para datos en tiempo real, datos históricos desde Ubidots e interpolación del lado del servidor.
- **Frontend de Visualización** — Dashboard basado en Plotly.js que renderiza un mapa de calor volumétrico 3D interactivo con cambio entre vistas de temperatura/humedad, indicadores ambientales y línea de tiempo histórica.

## Diagrama de Arquitectura

```
Sensores (t1–t5, tex, tps, tpi, h1–h5, hum_general, amoniaco,
          temperatura1, temperatura3, ventilador, extractor)
       │
       │  MQTT (tópicos Ubidots /lv)
       ▼
  Cliente MQTT  (backend/mqtt_client.py)
       │
       │  Lecturas de sensores parseadas
       ▼
  Motor Heatmap  (backend/heatmap_engine.py)
       │
       │  Volúmenes 3D interpolados (temp + humedad)
       ▼
  API Flask  (backend/visualization.py)
       │
       │  JSON sobre HTTP (/api/data, /api/history, /api/history/interpolate)
       ▼
  Frontend  (templates/index.html — Plotly.js)
       │
       ▲  Datos históricos
       │
  API REST Ubidots  (consultada por endpoint /api/history)
```

## Responsabilidades de Componentes

### backend/mqtt_client.py

Administra la conexión MQTT a Ubidots. Se suscribe a `/v1.6/devices/{device}/+/lv` y parsea los payloads numéricos planos en diccionarios `{etiqueta: valor}`. Reenvía datos parseados a un callback (el motor heatmap). Soporta todos los tipos de variables: temperatura, humedad, promedios, piso radiante, amoníaco y estados de dispositivos.

### backend/heatmap_engine.py

Almacén de datos thread-safe. Recibe actualizaciones de sensores, valida valores contra un rango físicamente plausible, y realiza interpolación volumétrica 3D usando `scipy.interpolate.griddata` (vecino más cercano + lineal) tanto para temperatura como humedad. También rastrea temperatura exterior, temperaturas promedio, sensores del piso radiante, humedad, amoníaco, estados de ventilador/extractor y timestamp de última actualización.

### backend/visualization.py

Aplicación Flask con cuatro rutas:
- `GET /` — Renderiza el dashboard Plotly.js.
- `GET /api/data` — Retorna JSON con volúmenes 3D interpolados (temperatura y humedad), datos de sensores, datos del piso radiante y estados de dispositivos.
- `GET /api/history` — Consulta datos históricos desde la API REST de Ubidots para un rango de fechas.
- `GET /api/history/interpolate` — Interpolación 3D del lado del servidor para un momento histórico específico.

### backend/config.py

Módulo central de configuración que contiene credenciales MQTT, posiciones de sensores, dimensiones del cuarto, resolución de grilla, rangos de temperatura, etiquetas del piso radiante, etiquetas de humedad, etiqueta de amoníaco y configuración del servidor web.

### templates/index.html

Dashboard de una sola página usando Plotly.js con:
- Render 3D de isosuperficies con cambio temperatura/humedad
- Wireframe 3D (techo inclinado, ventanas, mueble, lámparas, piso radiante)
- Panel lateral con termómetros, barras de humedad, barra de amoníaco, barras del piso radiante y widgets de dispositivos
- Visor de datos históricos con slider de línea de tiempo
- Diseño responsivo (escritorio + móvil)
- Header con marca (TECHNEBRIOS + Ingeniería Condor)
