"""The benchmark workload, shared by bench.bzl (Bazel) and run.py (starlark-rs)."""

load("@hashes.bzl", "hashes")

def message(size):
    """Returns `size` bytes to hash.

    Args:
        size: The length in bytes

    Returns:
        An ASCII byte string
    """
    return ("0123456789abcdef" * (size // 16 + 1))[:size]

def run(algorithm, data, calls):
    """Hashes `data` with `hashes.<algorithm>`, `calls` times over.

    Args:
        algorithm: A field of `hashes`
        data: The byte string to hash
        calls: How many times to hash it

    Returns:
        The digest, or None if `calls` is 0
    """
    fn = getattr(hashes, algorithm)
    digest = None
    for _ in range(calls):
        digest = fn(data)
    return digest
