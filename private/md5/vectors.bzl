"""MD5 known-answer vectors, shared by hash_kat_test and test_md5.py."""

VECTORS = [
    # The RFC 1321 appendix A.5 test suite.
    ("", "d41d8cd98f00b204e9800998ecf8427e"),
    ("a", "0cc175b9c0f1b6a831c399e269772661"),
    ("abc", "900150983cd24fb0d6963f7d28e17f72"),
    ("message digest", "f96b697d7cb7938d525a2f31aaf161d0"),
    ("abcdefghijklmnopqrstuvwxyz", "c3fcd3d76192e4007dfb496cca67e13b"),
    ("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789", "d174ab98d277d9f5a5611c2c9f419d9f"),
    ("1234567890" * 8, "57edf4a22be3c955ac49da2e2107b67a"),
    # Pads into a second block.
    ("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq", "8215ef0796a20bcaaae116d3876c664a"),
    ("The quick brown fox jumps over the lazy dog", "9e107d9d372bb6826bd81d3542a419d6"),
    ("a" * 1000, "cabe45dcc9ae5b66ba86600cca6b8ba8"),
    # Bazel reads this file as Latin-1, so this is the UTF-8 encoding of "héllo"
    # seen as six one-byte characters.
    ("héllo", "be50e8478cf24ff3595bc7307fb91b50"),
]
