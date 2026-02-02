from elasticsearch import Elasticsearch
from settings import settings


# disable some features just for local testing
def get_client() -> Elasticsearch:
    return Elasticsearch(
        settings.es_host,
        basic_auth=(settings.es_user, settings.es_password),
        ca_certs=settings.es_ca_cert,
        verify_certs=False,
        ssl_show_warn=False,
    )
