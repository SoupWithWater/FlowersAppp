from __future__ import annotations

import os
import sys
from pathlib import Path

from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

from .backend import Backend


def main() -> int:
    os.environ.setdefault("QT_QUICK_CONTROLS_STYLE", "Material")
    app = QGuiApplication(sys.argv)
    engine = QQmlApplicationEngine()
    backend = Backend()
    engine.rootContext().setContextProperty("backend", backend)
    qml_path = Path(__file__).resolve().parent / "qml" / "App.qml"
    engine.load(str(qml_path))
    if not engine.rootObjects():
        return -1
    return app.exec()


if __name__ == "__main__":
    sys.exit(main())
