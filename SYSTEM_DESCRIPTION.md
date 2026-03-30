# System Description

## System Context

This system monitors the internal temperature, humidity, and environmental conditions of a mealworm (Tenebrio molitor) breeding room. The room measures approximately 10 m (length) x 6 m (width) x 3 m (height) with an inclined roof (high at Y=0, low at Y=6). Maintaining a stable and uniform temperature and humidity is critical for optimal larval development and production yield.

## Sensors

### Temperature Sensors (Interior)

| Sensor | Position (x, y, z) | Location |
|--------|-------------------|----------|
| t1 | (2, 3, 2.5) | Upper level |
| t2 | (5, 3, 2.5) | Upper level |
| t3 | (8, 3, 2.5) | Upper level |
| t4 | (3, 3, 1.0) | Lower level |
| t5 | (7, 3, 1.0) | Lower level |

### Exterior Temperature Sensor

| Sensor | Position (x, y, z) | Location |
|--------|-------------------|----------|
| tex | (2, 6.15, 0.8) | Planter on back wall (Y=6) |

### Average Temperature Sensors

| Sensor | Description |
|--------|-------------|
| tps | Average upper sensors temperature |
| tpi | Average lower sensors temperature |

### Humidity Sensors

| Sensor | Description |
|--------|-------------|
| h1–h5 | Interior humidity (same positions as t1–t5) |
| hum_general | General room humidity |

### Radiant Floor Sensors

| Sensor | Description |
|--------|-------------|
| temperatura1 | Floor output temperature |
| temperatura3 | Mid-floor temperature |

### Other Sensors

| Sensor | Description |
|--------|-------------|
| amoniaco | Ammonia concentration (PPM) |
| ventilador | Fan status (on/off) |
| extractor | Extractor status (on/off) |

All sensors publish data to the Ubidots IoT platform via MQTT.

## Monitoring Goal

The goal is to detect thermal gradients, hot spots, and cold zones inside the breeding room in real time. This allows operators to:

- Verify that the room temperature stays within the ideal range (23–28 °C).
- Monitor humidity levels within the ideal range (60–88%).
- Track ammonia concentration (ideal: 0–1 PPM).
- Monitor radiant floor heating system performance.
- Compare interior temperature against the exterior reference.
- Monitor the fan and extractor operational status.
- Review historical data trends using the timeline slider.

## Visualization Purpose

The 3D volumetric heatmap provides a spatial representation of the temperature and humidity distribution across the entire room volume. The system supports toggling between temperature and humidity views. Using interpolation from the 5 sensor points, the system generates a continuous field that helps operators visually understand environmental conditions without checking each sensor individually.

The 3D render also includes a detailed wireframe of the room with inclined roof, windows, furniture, vintage lamps, planter, and a radiant floor system with serpentine heating pipes colored according to floor temperature.
