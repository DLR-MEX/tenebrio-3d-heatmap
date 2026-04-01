"""
Configuración de logging con archivos diarios organizados por carpetas mensuales.

Estructura generada:
    logs/
    └── 2026-04/
        ├── 2026-04-01.log
        ├── 2026-04-02.log
        └── ...

Compatible con ejecución como servicio de Windows (NSSM).
"""

import logging
import os
from datetime import datetime
from logging.handlers import TimedRotatingFileHandler
from pathlib import Path

# Carpeta raíz de logs (relativa al directorio del proyecto)
_PROJECT_ROOT = Path(__file__).resolve().parent.parent
LOGS_DIR = _PROJECT_ROOT / "logs"

LOG_FORMAT = "%(asctime)s [%(levelname)s] %(name)s: %(message)s"


class MonthlyFolderFileHandler(TimedRotatingFileHandler):
    """Handler que crea un archivo de log por día dentro de una carpeta por mes.

    Genera rutas como: logs/2026-04/2026-04-01.log
    Al cambiar de día, rota automáticamente y crea la carpeta del nuevo mes
    si es necesario.
    """

    def __init__(self, logs_dir: Path, level=logging.DEBUG):
        self._logs_dir = logs_dir
        # Crear archivo inicial
        log_file = self._current_log_path()
        log_file.parent.mkdir(parents=True, exist_ok=True)

        super().__init__(
            filename=str(log_file),
            when="midnight",
            interval=1,
            backupCount=0,  # no eliminar archivos antiguos
            encoding="utf-8",
        )
        self.setLevel(level)
        self.suffix = "%Y-%m-%d"

    def _current_log_path(self) -> Path:
        """Ruta del archivo de log para hoy."""
        now = datetime.now()
        month_folder = now.strftime("%Y-%m")
        day_file = now.strftime("%Y-%m-%d") + ".log"
        return self._logs_dir / month_folder / day_file

    def doRollover(self):
        """Al rotar (medianoche), apunta al archivo del nuevo día/mes."""
        if self.stream:
            self.stream.close()
            self.stream = None  # type: ignore[assignment]

        new_path = self._current_log_path()
        new_path.parent.mkdir(parents=True, exist_ok=True)
        self.baseFilename = str(new_path)

        # Reiniciar cálculo de siguiente rotación
        self.rolloverAt = self.computeRollover(int(datetime.now().timestamp()))

        if not self.delay:
            self.stream = self._open()


def setup_logging(level=logging.INFO):
    """Configura el logging global: consola + archivos diarios por mes.

    Debe llamarse una sola vez al inicio de la aplicación.
    """
    root_logger = logging.getLogger()
    root_logger.setLevel(level)

    formatter = logging.Formatter(LOG_FORMAT)

    # Handler de consola (para ver en terminal y en NSSM stdout)
    console_handler = logging.StreamHandler()
    console_handler.setLevel(level)
    console_handler.setFormatter(formatter)
    root_logger.addHandler(console_handler)

    # Handler de archivos (logs/YYYY-MM/YYYY-MM-DD.log)
    file_handler = MonthlyFolderFileHandler(LOGS_DIR, level=level)
    file_handler.setFormatter(formatter)
    root_logger.addHandler(file_handler)
