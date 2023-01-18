import os
import time

from prometheus_client import start_http_server
from prometheus_client.core import REGISTRY

from .collector import AkkomaCollector


def cli():
    url = os.environ["URL"]
    port = int(os.getenv("PORT", 8000))
    REGISTRY.register(AkkomaCollector(url))
    start_http_server(port)
    while True:
        time.sleep(10)


if __name__ == "__main__":
    cli()
