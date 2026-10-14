"""Reference implementations of every algorithm in `hashes`, as bytes -> hex."""

import hashlib
import zlib

import blake3


def _hashlib(name):
    return lambda data: hashlib.new(name, data).hexdigest()


REFERENCES = {
    "blake3": lambda data: blake3.blake3(data).hexdigest(),
    "md5": _hashlib("md5"),
    "sha1": _hashlib("sha1"),
    "sha256": _hashlib("sha256"),
    "crc32": lambda data: "%08x" % zlib.crc32(data),
    "sha224": _hashlib("sha224"),
    "sha512": _hashlib("sha512"),
    "sha384": _hashlib("sha384"),
    "sha512_224": _hashlib("sha512_224"),
    "sha512_256": _hashlib("sha512_256"),
}
