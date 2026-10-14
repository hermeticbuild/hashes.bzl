"""Hash functions in pure Starlark.

Each `hashes.<algorithm>(input)` takes a byte string and returns its digest as
a lowercase hex string.

A byte string is how Bazel represents bytes: a string of characters U+0000 to
U+00FF, one per byte. File contents and BUILD/.bzl string literals are read as
Latin-1, so they are already byte strings (non-ASCII literals as their UTF-8
bytes), as are the strings bazel_lib's `base64` produces and consumes. Other
characters fail.

Since Bazel 8.2, json.decode also produces UTF-8 bytes for `\\u` escapes.
Earlier versions produce UTF-16 code units, which aren't bytes: such text fails
(above U+00FF) or hashes as Latin-1 (U+0080 to U+00FF).
"""

load("//private/blake3:blake3.bzl", _blake3 = "blake3")
load("//private/md5:md5.bzl", _md5 = "md5")
load("//private/sha1:sha1.bzl", _sha1 = "sha1")
load("//private/sha256:sha256.bzl", _sha256 = "sha256")

hashes = struct(
    sha1 = _sha1,
    md5 = _md5,
    sha256 = _sha256,
    blake3 = _blake3,
)
