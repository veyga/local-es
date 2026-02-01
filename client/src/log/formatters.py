import json
import logging


class JsonFormatter(logging.Formatter):
    """JSON Formatter"""

    def format(self, record):
        return json.dumps(
            {
                "level": record.levelname,
                "message": record.getMessage(),
                "file": record.pathname,
                "lineno": record.lineno,
                "asctime": self.formatTime(record),
            }
        )


class SimpleFormatter(logging.Formatter):
    """[%LEVEL%] %MESSAGE%"""

    def format(self, record):
        return f"[{record.levelname}] {record.getMessage()}"
