"""Times the workload in Bazel's own Starlark interpreter; see run.py.

Starlark has no clock, but repository rules can run programs, so this reads
one from `date` on either side of each measurement. Each measurement repeats
the workload enough times to take about `target_ms`, found by calibration runs
that double as warmup, and is taken `repeat` times.
"""

load(":workload.bzl", "message", "run")

def _now_ns(rctx):
    result = rctx.execute(["date", "+%s%N"])
    if result.return_code != 0:
        fail("date failed: " + result.stderr)
    return int(result.stdout.strip())

def _time_ns(rctx, algorithm, data, calls):
    start = _now_ns(rctx)
    run(algorithm, data, calls)
    return _now_ns(rctx) - start

def _calibrate(rctx, algorithm, data, target_ns, overhead_ns):
    """Picks a number of calls taking about target_ns, warming up on the way."""
    calls = 1
    for _ in range(32):
        ns = _time_ns(rctx, algorithm, data, calls) - overhead_ns

        # Only trust a measurement well clear of the clock's own jitter.
        if ns >= target_ns // 8:
            return max(1, calls * target_ns // ns)
        calls *= 4
    fail("{} never took {}ns".format(algorithm, target_ns))

def _results_impl(rctx):
    config = rctx.getenv("BENCH_CONFIG")
    if config == None:
        fail("run bench/run.py, which sets BENCH_CONFIG")
    config = json.decode(config)

    # Re-runs on every invocation of run.py, rather than reusing old results.
    rctx.getenv("BENCH_RUN")

    # What reading the clock twice costs, to subtract from every measurement.
    overhead_ns = min([_time_ns(rctx, "md5", "", 0) for _ in range(config["repeat"])])

    results = []
    for algorithm in config["algorithms"]:
        for size in config["sizes"]:
            data = message(size)
            calls = _calibrate(rctx, algorithm, data, config["target_ms"] * 1000000, overhead_ns)
            results.append({
                "algorithm": algorithm,
                "calls": calls,
                "digest": run(algorithm, data, 1),
                "ns": [
                    _time_ns(rctx, algorithm, data, calls) - overhead_ns
                    for _ in range(config["repeat"])
                ],
                "size": size,
            })

    rctx.file("results.json", json.encode({"overhead_ns": overhead_ns, "results": results}))
    rctx.file("BUILD.bazel", 'exports_files(["results.json"])\n')

_results = repository_rule(implementation = _results_impl)

def _bench_impl(module_ctx):
    _results(name = "hashes_bench_results")
    return module_ctx.extension_metadata(reproducible = False)

bench = module_extension(implementation = _bench_impl)
