# Descripción del Sistema

## Contexto del Sistema

Este sistema monitorea la temperatura interna, humedad y condiciones ambientales de un cuarto de cría de Tenebrio molitor (gusano de la harina). El cuarto mide aproximadamente 10 m (largo) x 6 m (ancho) x 3 m (alto) con un techo inclinado (alto en Y=0, bajo en Y=6). Mantener una temperatura y humedad estable y uniforme es crítico para el desarrollo óptimo de las larvas y el rendimiento de producción.

## Sensores

### Sensores de Temperatura (Interior)

| Sensor | Posición (x, y, z) | Ubicación |
|--------|-------------------|----------|
| t1 | (2, 3, 2.5) | Nivel superior |
| t2 | (5, 3, 2.5) | Nivel superior |
| t3 | (8, 3, 2.5) | Nivel superior |
| t4 | (3, 3, 1.0) | Nivel inferior |
| t5 | (7, 3, 1.0) | Nivel inferior |

### Sensor de Temperatura Exterior

| Sensor | Posición (x, y, z) | Ubicación |
|--------|-------------------|----------|
| tex | (2, 6.15, 0.8) | Jardinera en pared trasera (Y=6) |

### Sensores de Temperatura Promedio

| Sensor | Descripción |
|--------|-------------|
| tps | Temperatura promedio sensores superiores |
| tpi | Temperatura promedio sensores inferiores |

### Sensores de Humedad

| Sensor | Descripción |
|--------|-------------|
| h1–h5 | Humedad interior (mismas posiciones que t1–t5) |
| hum_general | Humedad general del cuarto |

### Sensores del Piso Radiante

| Sensor | Descripción |
|--------|-------------|
| temperatura1 | Temperatura de salida del piso |
| temperatura3 | Temperatura medio piso |

### Sensores de Sala de Máquinas y Solar

| Sensor | Descripción |
|--------|-------------|
| temperatura2 | Temperatura del calentador solar |
| temperatura4 | Temperatura de entrada al cuarto |
| temperatura5 | Temperatura del termo (escala 15-90°C) |

### Otros Sensores

| Sensor | Descripción |
|--------|-------------|
| amoniaco | Concentración de amoníaco (PPM) |
| ventilador | Estado del ventilador (encendido/apagado) |
| extractor | Estado del extractor (encendido/apagado) |

Todos los sensores publican datos a la plataforma IoT Ubidots vía MQTT.

## Objetivo del Monitoreo

El objetivo es detectar gradientes térmicos, puntos calientes y zonas frías dentro del cuarto de cría en tiempo real. Esto permite a los operadores:

- Verificar que la temperatura del cuarto se mantiene dentro del rango ideal (23–28 °C).
- Monitorear niveles de humedad dentro del rango ideal (60–88%).
- Rastrear concentración de amoníaco (ideal: 0–1 PPM).
- Monitorear rendimiento del sistema de piso radiante.
- Comparar temperatura interior contra la referencia exterior.
- Monitorear estado operativo del ventilador y extractor.
- Revisar tendencias de datos históricos usando el slider de línea de tiempo.

## Propósito de la Visualización

El mapa de calor volumétrico 3D provee una representación espacial de la distribución de temperatura y humedad en todo el volumen del cuarto. El sistema soporta cambio entre vistas de temperatura y humedad. Usando interpolación desde los 5 puntos de sensores, el sistema genera un campo continuo que ayuda a los operadores a entender visualmente las condiciones ambientales sin revisar cada sensor individualmente.

El render 3D también incluye un wireframe detallado del cuarto con techo inclinado, ventanas, mueble, lámparas vintage, jardinera y un sistema de piso radiante con tuberías de calefacción serpentín coloreadas según la temperatura del piso.
