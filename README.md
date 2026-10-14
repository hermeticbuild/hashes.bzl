# Hash functions in Starlark

Sometimes you need a few bytes of a reproducible hash for a Merkle tree or
configuration hash inside of Bazel rules. Unfortunately, Starlark's native
`hash()` function provides a Java-style hashcode, which is inappropriately
small and first-bytes biased for large string inputs.

Enter `hashes.bzl`; a collection of stronger hash functions implemented in pure
Starlark to be usable today without build system integration.

```starlark
load("@hashes.bzl", "hashes")

hashes.sha1(input: str) -> str
hashes.md5(input: str) -> str
hashes.sha256(input: str) -> str
hashes.blake3(input: str) -> str
```

Each takes a byte string (Bazel's usual representation of bytes: one character
per byte, U+0000 to U+00FF) and returns a lowercase hex digest; e.g.
`hashes.sha256("hello")` is `"2cf24dba5fb0a30e..."`.

Text from `json.decode` with `\u` escapes is only UTF-8 bytes from Bazel 8.2
on; earlier versions fail or hash it as Latin-1. Literals and file contents
work on every version.

## Is this a good idea?

No absolutely not.

## Development

```shell
bazel test //...
bazel run //bazel:buildifier  # format and lint-fix Starlark
```

Each hash lives in `private/<hash>/` and is tested twice:

- `<hash>_kat_test` evaluates known-answer vectors (`vectors.bzl`) in Bazel's
  own Starlark interpreter.
- `test_<hash>` is a pytest + hypothesis suite comparing the Starlark against a
  reference implementation. It imports the `.bzl` file as a Python module via
  `bazel/python/starlark_finder.py`, which shims `load()` and the few Starlark
  builtins Python lacks.

Python test dependencies are locked in `uv.lock`; after editing
`pyproject.toml`, run `uv lock`.

## License

MIT — see [LICENSE](./LICENSE).
