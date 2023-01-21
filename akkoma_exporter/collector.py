import requests
from prometheus_client.core import CounterMetricFamily, GaugeMetricFamily


class AkkomaCollector(object):
    def __init__(self, url) -> None:
        super().__init__()
        self.url = url

    def collect(self):
        hc = requests.get(self.url).json()

        yield GaugeMetricFamily(
            "akkoma_healthy",
            "Is the Akkoma server healthy?",
            value=1 if hc["healthy"] else 0,
        )
        yield GaugeMetricFamily(
            "akkoma_active", "Active database connections", value=hc["active"]
        )
        yield GaugeMetricFamily(
            "akkoma_idle", "Idle database connections", value=hc["idle"]
        )
        yield GaugeMetricFamily(
            "akkoma_pool_size", "Total database pool", value=hc["idle"]
        )

        yield GaugeMetricFamily(
            "akkoma_memory_used",
            "Memory used by the Akkoma server",
            value=hc["memory_used"],
        )

        yield CounterMetricFamily(
            "akkoma_processed_jobs",
            "Total jobs processed by Akkoma's job queue.",
            value=hc["job_queue_stats"]["processed_jobs"],
        )

        yield AkkomaCollector.get_job_queue_counter(hc)
        yield AkkomaCollector.get_worker_counter(hc)

    @staticmethod
    def get_job_queue_counter(hc):
        jqs = CounterMetricFamily(
            "akkoma_job_queue_jobs",
            "Akkoma job queue statistics for all of the job queues.",
            labels=["queue", "status"],
        )
        for qname, qinfo in hc["job_queue_stats"]["queues"].items():
            for status, counts in qinfo.items():
                jqs.add_metric([qname, status], counts)
        return jqs

    @staticmethod
    def get_worker_counter(hc):
        ws = CounterMetricFamily(
            "akkoma_worker_jobs",
            "Akkoma worker statistics",
            labels=["worker", "jobname", "status"],
        )
        for wname, winfo in hc["job_queue_stats"]["workers"].items():
            for action, counts in winfo.items():
                for status, count in counts.items():
                    ws.add_metric([wname, action, status], count)
        return ws
