REGLAS DE DESARROLLO

1. Nunca cambiar la arquitectura del sistema.

2. No modificar nombres de archivos existentes.

3. No cambiar el formato de la API.

4. No cambiar posiciones de sensores.

5. No modificar configuración MQTT sin instrucción explícita.

6. El sensor exterior TPS NO se usa en interpolación.

7. El volumen 3D siempre debe usar:
scipy griddata

8. Los comentarios deben estar en español.

9. Variables y funciones deben estar en inglés.

10. No eliminar funcionalidades existentes.
Solo extender el sistema.

11. No modificar el frontend sin razón clara.

12. Mantener compatibilidad con Python 3.10+.