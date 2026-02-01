import logging
import logging.config
from enum import StrEnum
from types import SimpleNamespace as ___
from src.settings import settings as s

LOG_CONFIG_FILE = "logconfig"


logging.config.fileConfig(LOG_CONFIG_FILE, disable_existing_loggers=False)


def create_logger(name: str, propagate: bool = False) -> logging.Logger:
    logger = logging.getLogger(name)
    logger.setLevel(s.log_level)
    logger.propagate = propagate
    return logger


class LoggerName(StrEnum):
    JSON = "root"
    SIMPLE = "simple"


LOGGERS = ___(
    JSON=create_logger(LoggerName.JSON),
    SIMPLE=create_logger(LoggerName.SIMPLE),
)
