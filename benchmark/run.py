#!/usr/bin/env python3
"""Benchmarks hashes.bzl under Bazel's and starlark-rs's Starlark interpreters.

    uv run --group test benchmark/run.py [--algorithms sha256,crc32] [--sizes 64,65536]

Bazel runs the workload in a repository rule (bench.bzl), timing itself with
`date`. starlark-rs (the `starlark` binary from facebook/starlark-rust) has no
clock and resolves `load()` paths as files, so this stages a copy of the .bzl
files with their labels rewritten to paths, and times whole `starlark`
processes: the time per call is the difference between running the workload
`calls` times and 0 times, divided by `calls`. Each takes the best of
`--repeat` measurements of about `--target-ms` each.

starlark-rs releases up to at least 0.14.0 wrap `<<` results between 2**31 and
2**32 to negative ints, which breaks SHA-1 and SHA-2. Use a build including
facebook/starlark-rust@4ab492790e, which promotes them to bigints:

    cargo install --git https://github.com/facebook/starlark-rust --rev 4ab492790e starlark_bin

Native is CPython's hashlib and zlib (C), and the `blake3` package (Rust), for
scale. Every digest is checked against them.
"""

import argparse
import hashlib
import json
import pathlib
import platform
import re
import shutil
import subprocess
import sys
import time
import zlib

BENCH = pathlib.Path(__file__).resolve().parent
ROOT = BENCH.parent

ALGORITHMS = [
    "md5",
    "sha1",
    "sha224",
    "sha256",
    "sha384",
    "sha512",
    "sha512_224",
    "sha512_256",
    "blake3",
    "crc32",
]


def native(algorithm):
    if algorithm == "crc32":
        return lambda data: "%08x" % zlib.crc32(data)
    if algorithm == "blake3":
        import blake3

        return lambda data: blake3.blake3(data).hexdigest()
    return lambda data: hashlib.new(algorithm, data).hexdigest()


def message(size):
    # As workload.bzl's message().
    return (b"0123456789abcdef" * (size // 16 + 1))[:size]


def check(interpreter, algorithm, size, digest):
    expected = native(algorithm)(message(size))
    if digest != expected:
        sys.exit(f"{interpreter} {algorithm}({size} bytes) = {digest}, expected {expected}")


def bazel(args):
    """Seconds per call for each (algorithm, size), in Bazel."""
    config = json.dumps(
        {
            "algorithms": args.algorithms,
            "repeat": args.repeat,
            "sizes": args.sizes,
            "target_ms": args.target_ms,
        }
    )
    subprocess.run(
        [
            "bazel",
            "fetch",
            "--repo=@hashes_bench_results",
            "--repo_env=BENCH_CONFIG=" + config,
            "--repo_env=BENCH_RUN=%d" % time.time_ns(),
        ],
        cwd=BENCH,
        check=True,
    )
    output_base = subprocess.run(
        ["bazel", "info", "output_base"], cwd=BENCH, check=True, capture_output=True, text=True
    ).stdout.strip()
    [path] = pathlib.Path(output_base, "external").glob("*hashes_bench_results/results.json")
    seconds = {}
    for result in json.loads(path.read_text())["results"]:
        check("Bazel", result["algorithm"], result["size"], result["digest"])
        seconds[result["algorithm"], result["size"]] = min(result["ns"]) / result["calls"] / 1e9
    return seconds


_LOAD = re.compile(r'load\("([^"]+)"')


def _path_for(label, package):
    if label == "@hashes.bzl":
        return "hashes.bzl"
    if label.startswith("//"):
        package, _, name = label[2:].partition(":")
    elif label.startswith(":"):
        name = label[1:]
    else:
        raise ValueError(f"can't stage load of {label!r}")
    return "/".join(p for p in [package, name] if p)


def stage(dest):
    """Copies the library and workload to dest, with load() labels rewritten to paths."""
    files = subprocess.run(
        ["git", "ls-files", "--cached", "--others", "--exclude-standard", "--"]
        + ["hashes.bzl", "private/*.bzl", "benchmark/workload.bzl"],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
    ).stdout.split()
    for name in files:
        package = str(pathlib.PurePosixPath(name).parent).removeprefix(".")
        source = (ROOT / name).read_text(encoding="latin-1")
        source = _LOAD.sub(lambda m: f'load("{_path_for(m.group(1), package)}"', source)
        (dest / name).parent.mkdir(parents=True, exist_ok=True)
        (dest / name).write_text(source, encoding="latin-1")


def starlark_rs(args, stage_dir):
    """Seconds per call for each (algorithm, size), in starlark-rs."""

    def evaluate(algorithm, size, calls):
        script = stage_dir / "bench.star"
        script.write_text(
            'load("benchmark/workload.bzl", "message", "run")\n'
            "def main():\n"
            f'    print(run("{algorithm}", message({size}), {calls}))\n'
            "main()\n"
        )
        start = time.perf_counter_ns()
        result = subprocess.run(
            [args.starlark, "bench.star"], cwd=stage_dir, check=True, capture_output=True, text=True
        )
        ns = time.perf_counter_ns() - start
        # print() writes to stderr.
        return ns, result.stderr.split()[0]

    seconds = {}
    for algorithm in args.algorithms:
        for size in args.sizes:
            baseline_ns = min(evaluate(algorithm, size, 0)[0] for _ in range(args.repeat))
            calls, target_ns = 1, args.target_ms * 1e6
            while True:
                ns, digest = evaluate(algorithm, size, calls)
                if ns - baseline_ns >= target_ns / 8:
                    calls = max(1, int(calls * target_ns / (ns - baseline_ns)))
                    break
                calls *= 4
            check("starlark-rs", algorithm, size, digest)
            ns = min(evaluate(algorithm, size, calls)[0] for _ in range(args.repeat))
            seconds[algorithm, size] = (ns - baseline_ns) / calls / 1e9
    return seconds


def native_seconds(args):
    seconds = {}
    for algorithm in args.algorithms:
        fn = native(algorithm)
        for size in args.sizes:
            data = message(size)
            calls, target = 1, args.target_ms / 1e3
            while True:
                start = time.perf_counter()
                for _ in range(calls):
                    fn(data)
                elapsed = time.perf_counter() - start
                if elapsed >= target / 8:
                    calls = max(1, int(calls * target / elapsed))
                    break
                calls *= 4
            best = float("inf")
            for _ in range(args.repeat):
                start = time.perf_counter()
                for _ in range(calls):
                    fn(data)
                best = min(best, time.perf_counter() - start)
            seconds[algorithm, size] = best / calls
    return seconds


def rate(seconds, size):
    if size >= 1024:
        per_second = size / seconds
        for unit in ["B", "KiB", "MiB", "GiB"]:
            if per_second < 1024 or unit == "GiB":
                return f"{per_second:,.0f} {unit}/s" if per_second >= 10 else f"{per_second:.1f} {unit}/s"
            per_second /= 1024
    return f"{1 / seconds:,.0f}/s"


def version(command):
    return subprocess.run(command, cwd=BENCH, capture_output=True, text=True).stdout.strip().splitlines()[0]


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--algorithms", type=lambda s: s.split(","), default=ALGORITHMS)
    parser.add_argument("--sizes", type=lambda s: [int(n) for n in s.split(",")], default=[64, 65536])
    parser.add_argument("--repeat", type=int, default=5)
    parser.add_argument("--target-ms", type=int, default=250)
    parser.add_argument("--starlark", default="starlark", help="starlark-rs binary")
    args = parser.parse_args()
    # Runs from the staging directory, so must not be relative.
    args.starlark = str(pathlib.Path(shutil.which(args.starlark)).resolve())

    stage_dir = ROOT / ".tmp" / "benchmark" / "stage"
    shutil.rmtree(stage_dir, ignore_errors=True)
    stage_dir.mkdir(parents=True)
    try:
        stage(stage_dir)
        columns = {
            "Bazel": bazel(args),
            "starlark-rs": starlark_rs(args, stage_dir),
            "native": native_seconds(args),
        }
    finally:
        shutil.rmtree(stage_dir)

    print(f"- CPU: {cpu()}")
    print(f"- Bazel: {version(['bazel', '--version'])}")
    print(f"- starlark-rs: {version([args.starlark, '--version'])}")
    print(f"- native: CPython {platform.python_version()} hashlib/zlib, blake3 package")
    for size in args.sizes:
        unit = "throughput" if size >= 1024 else "hashes per second"
        print(f"\n{size:,}-byte messages ({unit}):\n")
        print("| Algorithm | " + " | ".join(columns) + " | Bazel vs native |")
        print("|---|" + "---:|" * (len(columns) + 1))
        for algorithm in args.algorithms:
            cells = [rate(c[algorithm, size], size) for c in columns.values()]
            slowdown = columns["Bazel"][algorithm, size] / columns["native"][algorithm, size]
            print(f"| {algorithm} | " + " | ".join(cells) + f" | {slowdown:,.0f}x slower |")


def cpu():
    for line in pathlib.Path("/proc/cpuinfo").read_text().splitlines():
        if line.startswith("model name"):
            return line.partition(":")[2].strip()
    return platform.processor()


if __name__ == "__main__":
    main()
