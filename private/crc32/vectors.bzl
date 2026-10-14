"""CRC-32 known-answer vectors, shared by hash_kat_test and test_crc32.py."""

VECTORS = [
    ("", "00000000"),
    # The standard check value, from the Catalogue of parametrised CRC algorithms
    # (CRC-32/ISO-HDLC).
    ("123456789", "cbf43926"),
    ("abc", "352441c2"),
    # SHA-1's two-block padding case; CRC-32 has no blocks, but kept for parity.
    ("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq", "171a3f5f"),
    ("abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu", "191f3349"),
    ("The quick brown fox jumps over the lazy dog", "414fa339"),
    ("a" * 1000, "9a38da03"),
    # Bazel reads this file as Latin-1, so this is the UTF-8 encoding of "héllo"
    # seen as six one-byte characters.
    ("héllo", "9e3b8236"),
]
