"""Hash functions in pure Starlark.

Each `hashes.<algorithm>(input)` takes a byte string and returns its digest as
a lowercase hex string.

A byte string is how Bazel represents bytes: a string of characters U+0000 to
U+00FF, one per byte. File contents and BUILD/.bzl string literals are read as
Latin-1, so they are already byte strings (non-ASCII literals as their UTF-8
bytes), as are the strings bazel_lib's `base64` produces and consumes. Other
characters fail.

json.decode does the same for `\\u` escapes from Bazel 8.2.0, this module's
minimum version (bazelbuild/bazel#24417).
"""

load("//private/blake3:blake3.bzl", _blake3 = "blake3")
load("//private/crc32:crc32.bzl", _crc32 = "crc32")
load("//private/md5:md5.bzl", _md5 = "md5")
load("//private/sha1:sha1.bzl", _sha1 = "sha1")
load("//private/sha224:sha224.bzl", _sha224 = "sha224")
load("//private/sha256:sha256.bzl", _sha256 = "sha256")
load("//private/sha384:sha384.bzl", _sha384 = "sha384")
load("//private/sha512:sha512.bzl", _sha512 = "sha512")

hashes = struct(
    sha1 = _sha1,
    md5 = _md5,
    sha256 = _sha256,
    blake3 = _blake3,
    crc32 = _crc32,
    sha224 = _sha224,
    sha512 = _sha512,
    sha384 = _sha384,
)
