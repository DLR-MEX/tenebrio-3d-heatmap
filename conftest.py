"""
Conftest raíz: agrega backend/ al sys.path para que los tests importen módulos del backend.
"""

import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "backend"))
