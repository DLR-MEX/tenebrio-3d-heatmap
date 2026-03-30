# Instalación

## Requisitos

- Python 3.10 o superior
- pip (gestor de paquetes Python)

## Instalar Dependencias

```bash
# Opción 1: Usando el script de instalación
bash install.sh

# Opción 2: Manual
pip install -r requirements.txt
```

### Dependencias

| Paquete | Versión | Propósito |
|---------|---------|-----------|
| paho-mqtt | >= 2.0.0 | Cliente MQTT para comunicación con Ubidots |
| numpy | >= 1.24.0 | Arreglos numéricos y operaciones |
| scipy | >= 1.10.0 | Interpolación volumétrica 3D (griddata) |
| flask | >= 3.0.0 | Servidor web y API JSON |
| pytest | >= 7.0.0 | Framework de pruebas |

## Configuración

Editar `backend/config.py` con tus credenciales de Ubidots:

```python
UBIDOTS_TOKEN = "TU_TOKEN_UBIDOTS"
DEVICE_LABEL  = "TU_ETIQUETA_DISPOSITIVO"
```

## Ejecutar el Sistema

```bash
python backend/main.py
```

La aplicación hará lo siguiente:

1. Conectarse al broker MQTT de Ubidots.
2. Suscribirse a datos de sensores del dispositivo configurado.
3. Iniciar un servidor web Flask en `http://0.0.0.0:5000`.
4. Servir el dashboard del mapa de calor 3D en la URL raíz.

Abrir `http://localhost:5000` en un navegador para ver el dashboard.

## Ejecutar Tests

```bash
pytest tests/ -v
```

---

## Despliegue en Raspberry Pi

Esta sección describe cómo desplegar el sistema como un servicio en una Raspberry Pi con Raspberry Pi OS (o cualquier Linux basado en Debian).

### 1. Instalar Tailscale (Acceso Remoto)

Tailscale permite acceso remoto seguro a la Raspberry Pi desde cualquier dispositivo en tu red Tailscale.

```bash
# Instalar Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Autenticar y conectar
sudo tailscale up

# Verificar conexión y obtener la IP de Tailscale
tailscale ip -4
```

Una vez conectado, puedes acceder al dashboard remotamente vía `http://<ip-tailscale>:5000` desde cualquier dispositivo en tu red Tailscale.

Para habilitar Tailscale en el arranque (usualmente habilitado por defecto):

```bash
sudo systemctl enable tailscaled
sudo systemctl start tailscaled
```

### 2. Clonar el Repositorio

```bash
cd /home/spaces
git clone https://github.com/DLR-MEX/tenebrio-3d-heatmap.git
cd tenebrio-3d-heatmap
```

### 3. Crear Entorno Virtual e Instalar Dependencias

```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### 4. Configurar Credenciales de Ubidots

```bash
nano backend/config.py
```

Establece `UBIDOTS_TOKEN` y `DEVICE_LABEL` con tus credenciales.

### 5. Crear el Servicio systemd

Crear el archivo de servicio:

```bash
sudo nano /etc/systemd/system/tenebrio.service
```

Pegar el siguiente contenido:

```ini
[Unit]
Description=Tenebrio 3D Heatmap
After=network.target

[Service]
User=spaces
WorkingDirectory=/home/spaces/tenebrio-3d-heatmap/backend
ExecStart=/home/spaces/tenebrio-3d-heatmap/venv/bin/python3 main.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

### 6. Habilitar e Iniciar el Servicio

```bash
# Recargar systemd para reconocer el nuevo servicio
sudo systemctl daemon-reload

# Habilitar arranque automático en boot
sudo systemctl enable tenebrio

# Iniciar el servicio ahora
sudo systemctl start tenebrio

# Verificar que está activo
sudo systemctl status tenebrio
```

El dashboard estará disponible en:
- Red local: `http://<ip-raspberry-pi>:5000`
- Tailscale: `http://<ip-tailscale>:5000`

### 7. Ver Logs

```bash
# Logs en tiempo real
journalctl -u tenebrio -f

# Últimas 50 líneas
journalctl -u tenebrio -n 50
```

---

## Actualizar el Proyecto (Pull y Reinicio)

Cuando hay nuevos cambios en el repositorio, seguir estos pasos para actualizar la Raspberry Pi:

```bash
# Navegar al directorio del proyecto
cd /home/spaces/tenebrio-3d-heatmap

# Descargar últimos cambios de GitHub
git pull origin main

# Activar entorno virtual y actualizar dependencias (si cambiaron)
source venv/bin/activate
pip install -r requirements.txt

# Reiniciar el servicio para aplicar cambios
sudo systemctl restart tenebrio

# Verificar que reinició correctamente
sudo systemctl status tenebrio
```

Para hacerlo todo en un solo comando:

```bash
cd /home/spaces/tenebrio-3d-heatmap && git pull origin main && source venv/bin/activate && pip install -r requirements.txt && sudo systemctl restart tenebrio && sudo systemctl status tenebrio
```
