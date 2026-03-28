# System Description

## System Context

This system monitors the internal temperature of a mealworm (Tenebrio molitor) breeding room. The room measures approximately 10 m (length) x 6 m (width) x 3 m (height). Maintaining a stable and uniform temperature is critical for optimal larval development and production yield.

## Sensors

The system uses **5 interior temperature sensors** (t1–t5) distributed at different positions and heights inside the room:

| Sensor | Position (x, y, z) | Location |
|--------|-------------------|----------|
| t1 | (2, 3, 2.5) | Upper level |
| t2 | (5, 3, 2.5) | Upper level |
| t3 | (8, 3, 2.5) | Upper level |
| t4 | (3, 3, 1.0) | Lower level |
| t5 | (7, 3, 1.0) | Lower level |

Additionally, there is **1 exterior temperature sensor** (tps) at position (6.5, -0.15, 0.8), placed on top of a planter outside the room wall.

The system also monitors the state of a **fan** and an **extractor** (on/off).

All sensors publish data to the Ubidots IoT platform via MQTT.

## Monitoring Goal

The goal is to detect thermal gradients, hot spots, and cold zones inside the breeding room in real time. This allows operators to:

- Verify that the room temperature stays within the ideal range (20–30 °C).
- Identify areas where ventilation or heating adjustments are needed.
- Compare interior temperature against the exterior reference.
- Monitor the fan and extractor operational status.

## Visualization Purpose

The 3D volumetric heatmap provides a spatial representation of the temperature distribution across the entire room volume. Using interpolation from the 5 sensor points, the system generates a continuous temperature field that helps operators visually understand where temperature varies and how uniform the environment is, without needing to check each sensor individually.
