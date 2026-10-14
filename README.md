# Hash functions in Starlark

Sometimes you need a few bytes of a reproducible hash for a Merkle tree or
configuration hash inside of Bazel rules. Unfortunately, Starlark's native
`hash()` function provides a Java-style hashcode, which is inappropriately
small and first-bytes biased for large string inputs.

Enter `hashes.bzl`; a collection of stronger hash functions implemented in pure
Starlark to be usable today without build system integration.

```starlark
load("@hashes.bzl", "hashes")

hashes.md5(input: str) -> str
hashes.sha1(input: str) -> str
hashes.sha224(input: str) -> str
hashes.sha256(input: str) -> str
hashes.sha384(input: str) -> str
hashes.sha512(input: str) -> str
hashes.sha512_224(input: str) -> str
hashes.sha512_256(input: str) -> str
hashes.blake3(input: str) -> str
hashes.crc32(input: str) -> str
```

Each takes a byte string (Bazel's usual representation of bytes: one character
per byte, U+0000 to U+00FF) and returns a lowercase hex digest; e.g.
`hashes.sha256("hello")` is `"2cf24dba5fb0a30e..."`.

## Compatibility

Bazel 8.2.0 and later; `MODULE.bazel` enforces this with `bazel_compatibility`.
Tested on 8.2.0, the latest 8.x and 9.x.

The lower bound is where Bazel's strings became consistently bytes. Bazel
represents a string as its UTF-8 bytes, one character per byte, and that is what
these functions hash. Before 8.2.0, `json.decode` was the exception: it decoded
`\u` escapes to UTF-16 code units, so the same text hashed differently depending
on how the JSON spelled it, and failed outright above U+00FF.
[bazelbuild/bazel#24417](https://github.com/bazelbuild/bazel/pull/24417)
(backported to 8.2.0 as
[#25451](https://github.com/bazelbuild/bazel/pull/25451)) made it decode to UTF-8
bytes like everything else. `//private/utf8:test_utf8` and
`examples/utf8` cover this.

## Is this a good idea?

No absolutely not.

Bazel's Starlark interpreter hashes at 143 KiB/s to 1.5 MiB/s, three to four
orders of magnitude slower than native code. Hashing 64 KiB messages on an AMD
Ryzen 7 PRO 6850U:

| Algorithm | Bazel 9.3.0 | starlark-rs | Native | Bazel vs native |
|---|---:|---:|---:|---:|
| md5 | 792 KiB/s | 1.1 MiB/s | 955 MiB/s | 1,235× slower |
| sha1 | 504 KiB/s | 649 KiB/s | 2.2 GiB/s | 4,627× slower |
| sha224 | 293 KiB/s | 310 KiB/s | 2.1 GiB/s | 7,446× slower |
| sha256 | 295 KiB/s | 308 KiB/s | 2.1 GiB/s | 7,373× slower |
| sha384 | 143 KiB/s | 254 KiB/s | 1,005 MiB/s | 7,204× slower |
| sha512 | 143 KiB/s | 262 KiB/s | 1,000 MiB/s | 7,154× slower |
| sha512_224 | 143 KiB/s | 259 KiB/s | 1,006 MiB/s | 7,203× slower |
| sha512_256 | 143 KiB/s | 260 KiB/s | 1,006 MiB/s | 7,220× slower |
| blake3 | 430 KiB/s | 612 KiB/s | 5.2 GiB/s | 12,749× slower |
| crc32 | 1.5 MiB/s | 6.1 MiB/s | 2.8 GiB/s | 1,996× slower |

Small inputs fare little better: a 64-byte message takes Bazel 0.13 to 0.87 ms
(44 µs for CRC-32), 180 to 1,230 times longer than native code.

[starlark-rs](https://github.com/facebook/starlark-rust), Buck2's interpreter,
is up to four times faster, which doesn't help. Native is CPython's `hashlib`
and `zlib`, and the `blake3` package. To reproduce:

```shell
uv run --group test benchmark/run.py
```

`benchmark/run.py` checks every digest it times. starlark-rs releases up to at
least 0.14.0 compute `1 << 31` as `-2147483648`, which breaks SHA-1 and SHA-2;
build it from
[4ab492790e](https://github.com/facebook/starlark-rust/commit/4ab492790e) or
later.

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

To release, push a `vX.Y.Z` tag. `.github/workflows/release.yaml` attaches an
attested archive to a GitHub release and opens a pull request adding it to the
Bazel Central Registry.

## License

MIT — see [LICENSE](./LICENSE).
