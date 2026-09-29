"""Adds a Server-Timing response header breaking a request into connect, db
and app milliseconds, so latency can be attributed without a profiler.

    Server-Timing: app;dur=12.3, conn;dur=1.1, db;dur=4.6, total;dur=20.0,
                   pA;dur=..., pB;dur=..., pC;dur=..., nq;dur=3

pA/pB/pC are nested probe timings (below cors / below gzip / view layer).
X-DB lists the executed SQL with per-statement durations (diagnostic).
"""

import time

from django.db import connection


def _make_probe(label):
    class Probe:
        def __init__(self, get_response):
            self.get_response = get_response

        def __call__(self, request):
            started = time.perf_counter()
            try:
                response = self.get_response(request)
            finally:
                store = getattr(request, "_st", None)
                if store is not None:
                    store["p" + label] = (time.perf_counter() - started) * 1000
            return response

    Probe.__name__ = "Probe" + label
    return Probe


ProbeA = _make_probe("A")
ProbeB = _make_probe("B")
ProbeC = _make_probe("C")


class ServerTimingMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        started = time.perf_counter()
        timings = {"conn": 0.0, "db": 0.0}
        queries = []
        store = {}
        request._st = store

        def measure(execute, sql, params, many, context):
            query_started = time.perf_counter()
            try:
                return execute(sql, params, many, context)
            finally:
                ms = (time.perf_counter() - query_started) * 1000
                timings["db"] += ms
                queries.append((ms, " ".join(sql.split())[:140]))

        connection.execute_wrappers.append(measure)
        try:
            conn_started = time.perf_counter()
            connection.ensure_connection()
            timings["conn"] = (time.perf_counter() - conn_started) * 1000

            response = self.get_response(request)
        finally:
            connection.execute_wrappers.pop()

        total = (time.perf_counter() - started) * 1000
        app = total - timings["conn"] - timings["db"]
        parts = [
            f"app;dur={app:.1f}",
            f"conn;dur={timings['conn']:.1f}",
            f"db;dur={timings['db']:.1f}",
            f"total;dur={total:.1f}",
        ]
        for key in ("A", "B", "C"):
            if "p" + key in store:
                parts.append(f"p{key};dur={store['p' + key]:.1f}")
        parts.append(f"nq;dur={len(queries)}")
        response["Server-Timing"] = ", ".join(parts)
        if queries:
            response["X-DB"] = " | ".join(f"{ms:.0f}ms {sql}" for ms, sql in queries[:8])
        return response
