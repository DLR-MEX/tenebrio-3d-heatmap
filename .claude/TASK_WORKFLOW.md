# Flujo de trabajo para modificaciones

Cuando se reciba una solicitud de modificación en el proyecto, seguir estrictamente el siguiente flujo.

---

## 1. Análisis del requerimiento

- Analizar completamente la solicitud.
- Identificar el objetivo real del cambio.
- Determinar si afecta:
  - API
  - arquitectura
  - flujo de datos
  - dependencias
  - rendimiento

Si el requerimiento no es claro o está incompleto, solicitar aclaración antes de continuar.

---

## 2. Identificación del alcance

Determinar exactamente:

- qué archivo(s) deben modificarse
- qué funciones están involucradas
- qué módulos dependen de esos cambios

Evitar modificar archivos que no estén directamente relacionados con la solicitud.

---

## 3. Evaluación de impacto

Antes de implementar cambios verificar que la modificación **no rompe**:

- APIs existentes
- estructuras JSON
- contratos de datos
- comunicación entre módulos
- flujo de sensores o datos
- comportamiento general del sistema

Si existe riesgo técnico, explicarlo antes de implementar la modificación.

---

## 4. Propuesta de cambio

Antes de escribir código:

- explicar brevemente qué se va a modificar
- indicar qué archivos serán modificados
- indicar qué funciones serán afectadas
- justificar por qué la solución propuesta es correcta

---

## 5. Implementación

Al implementar cambios:

- realizar **solo las modificaciones necesarias**
- **no reescribir archivos completos** si no es necesario
- mantener el estilo actual del proyecto
- evitar refactorizaciones innecesarias
- mantener consistencia en nombres de variables y funciones

Todos los comentarios del código deben estar en **español**.

---

## 6. Pruebas

Después de implementar cambios verificar:

- que el servidor inicia correctamente
- que no existen errores en consola
- que el flujo de datos continúa funcionando
- que las funcionalidades existentes siguen operando correctamente

---

## 7. Pruebas de regresión

Confirmar que el cambio **no rompe funcionalidades existentes**, incluyendo:

- lectura de datos
- procesamiento interno
- comunicación de red
- visualización o interfaces

---

## 8. Gestión de dependencias

Si se agregan nuevas librerías:

- agregarlas al archivo `requirements.txt`
- usar versiones estables cuando sea necesario
- evitar dependencias innecesarias

---

## 9. Actualización del repositorio

Si los cambios afectan el comportamiento del sistema, actualizar:

- `README.md`
- documentación técnica
- `prompts.txt`
- archivos de configuración si aplica

---

## 10. Validación final

Antes de finalizar la tarea:

- ejecutar el servidor
- validar que el sistema inicia correctamente
- verificar que no existan errores críticos en tiempo de ejecución

---

## 11. Entrega del cambio

Cada modificación debe incluir:

- descripción clara del cambio
- lista de archivos modificados
- explicación técnica
- posibles riesgos o efectos secundarios