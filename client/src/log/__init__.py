import logging
from typing import Optional
from contextlib import contextmanager
from src.settings import settings as s
from .loggers import LOGGERS

Logger = LOGGERS
"""
Loggers instances (JSON/SIMPLE)
"""

LOG = Logger.SIMPLE if s.log_formatter == "simple" else Logger.JSON
""" Default logger """


@contextmanager
def tee_logs(
    *output_streams,
    logger: logging.Logger,
    level: int = logging.INFO,
    formatter: Optional[type] = None,
):
    """Tees the output of given logger name to the specified output streams."""
    handlers = [logging.StreamHandler(os) for os in output_streams]
    for handler in handlers:
        handler.setLevel(level)
        if formatter:
            handler.setFormatter(formatter())
        logger.addHandler(handler)
    yield
    for handler in handlers:
        handler.flush()
        logger.removeHandler(handler)
        handler.close()
