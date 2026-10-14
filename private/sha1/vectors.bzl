"""SHA-1 known-answer vectors, shared by hash_kat_test and test_sha1.py."""

VECTORS = [
    ("", "da39a3ee5e6b4b0d3255bfef95601890afd80709"),
    ("abc", "a9993e364706816aba3e25717850c26c9cd0d89d"),
    # Pads into a second block.
    ("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq", "84983e441c3bd26ebaae4aa1f95129e5e54670f1"),
    ("The quick brown fox jumps over the lazy dog", "2fd4e1c67a2d28fced849ee1bb76e7391b93eb12"),
    ("a" * 1000, "291e9a6c66994949b57ba5e650361e98fc36b1ba"),
    # Bazel reads this file as Latin-1, so this is the UTF-8 encoding of "héllo"
    # seen as six one-byte characters.
    ("héllo", "35b5ea45c5e41f78b46a937cc74d41dfea920890"),
]
