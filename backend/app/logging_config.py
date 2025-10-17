import logging
from logging.handlers import RotatingFileHandler

def setup_logging():
    fmt = "%(asctime)s %(levelname)s %(name)s: %(message)s"
    logging.basicConfig(level=logging.INFO, format=fmt)
    fh = RotatingFileHandler("app.log", maxBytes=1_000_000, backupCount=3)
    fh.setFormatter(logging.Formatter(fmt))
    root = logging.getLogger()
    root.addHandler(fh)
