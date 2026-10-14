"""UTF-8 test cases, smuggled into Bazel through json.decode.

Bazel represents a string as its UTF-8 bytes, one character per byte. Since
Bazel 8.2.0 (bazelbuild/bazel#24417), json.decode turns `\\u` escapes into
those bytes too, which lets these cases name exact code points while this file
stays ASCII. Earlier Bazels decoded escapes to UTF-16 code units, which aren't
bytes; that change is why MODULE.bazel requires 8.2.0. The one raw UTF-8 case
checks that both routes agree.

Each case is hashed as `"a" * pad + text * repeat`; the padding positions a
multibyte character across a block or chunk boundary.
"""

load("//:hashes.bzl", "hashes")

CASES_JSON = r"""
[
    {"name": "ascii", "text": "abc"},
    {"name": "nul", "text": "\u0000"},
    {"name": "first-2-byte", "text": "\u0080"},
    {"name": "latin-1", "text": "caf\u00e9"},
    {"name": "last-2-byte", "text": "\u07ff"},
    {"name": "first-3-byte", "text": "\u0800"},
    {"name": "euro", "text": "\u20ac"},
    {"name": "cjk", "text": "\u4e2d\u6587"},
    {"name": "cjk-raw", "text": "中文"},
    {"name": "bom", "text": "\ufeff"},
    {"name": "last-3-byte", "text": "\uffff"},
    {"name": "first-4-byte", "text": "\ud800\udc00"},
    {"name": "emoji", "text": "\ud83d\ude00"},
    {"name": "last-4-byte", "text": "\udbff\udfff"},
    {"name": "combining", "text": "e\u0301"},
    {"name": "zwj-sequence", "text": "\ud83d\udc68\u200d\ud83d\udc69\u200d\ud83d\udc67"},
    {"name": "mixed", "text": "\u00dcn\u00efc\u00f6d\u00e9 \u4e2d\u6587 \ud83d\ude00"},
    {"name": "2-byte-across-block", "pad": 63, "text": "\u00e9"},
    {"name": "3-byte-across-block", "pad": 62, "text": "\u20ac"},
    {"name": "4-byte-across-block", "pad": 61, "text": "\ud83d\ude00"},
    {"name": "2-byte-across-length-field", "pad": 55, "text": "\u00e9"},
    {"name": "4-byte-across-chunk", "pad": 1022, "text": "\ud83d\ude00"},
    {"name": "many-emoji", "repeat": 300, "text": "\ud83d\ude00"}
]
"""

ALGORITHMS = ["blake3", "md5", "sha1", "sha256", "crc32", "sha224", "sha512", "sha384", "sha512_224", "sha512_256", "sha3_224", "sha3_256", "sha3_384", "sha3_512"]

def utf8_cases():
    """Decodes the cases.

    Returns:
       A list of (name, message) pairs
    """
    return [
        (case["name"], "a" * case.get("pad", 0) + case["text"] * case.get("repeat", 1))
        for case in json.decode(CASES_JSON)
    ]

def digest_lines():
    """Hashes every case with every algorithm.

    Returns:
       Lines of `<name> <length in bytes> <algorithm> <hex digest>`
    """
    return [
        "{} {} {} {}".format(name, len(message), algorithm, getattr(hashes, algorithm)(message))
        for name, message in utf8_cases()
        for algorithm in ALGORITHMS
    ]
