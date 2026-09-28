"""Adds a Server-Timing response header breaking a request into connect, db
and app milliseconds, so latency can be attributed without a profiler.

    Server-Timing: app;dur=12.3, conn;dur=1.1, db;dur=4.6
"""

import time

from django.db import connection


class ServerTimingMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        started = time.perf_counter()
        timings = {"conn": 0.0, "db": 0.0}

        def measure(execute, sql, params, many, context):
            query_started = time.perf_counter()
            try:
                return execute(sql, params, many, context)
            finally:
                timings["db"] += (time.perf_counter() - query_started) * 1000

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
        response["Server-Timing"] = (
            f"app;dur={app:.1f}, conn;dur={timings['conn']:.1f}, "
            f"db;dur={timings['db']:.1f}, total;dur={total:.1f}"
        )
        return response
