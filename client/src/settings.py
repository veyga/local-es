import os
from pathlib import Path
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    log_level: str = os.getenv("LOG_LEVEL", "INFO")
    log_formatter: str = os.getenv("LOG_FORMATTER", "simple")
    authtoken: str = os.getenv("AUTHTOKEN", "")
    environment: str = os.getenv("ENVIRONMENT", "")
    es_host: str = os.getenv("ES_HOST", "https://localhost:9200")
    es_user: str = os.getenv("ES_USER", "elastic")
    es_ca_cert: str = os.getenv("ES_CA_CERT", "/output/es-ca.crt")

    @property
    def es_password(self) -> str:
        pw_file = Path(os.getenv("ES_PASSWORD_FILE", "/output/es-password"))
        if pw_file.exists():
            return pw_file.read_text().strip()
        return os.getenv("ES_PASSWORD", "")


settings = Settings()
