"""SHA-512/256 known-answer vectors, shared by hash_kat_test and test_sha512_256.py."""

VECTORS = [
    ("", "c672b8d1ef56ed28ab87c3622c5114069bdd3ad7b8f9737498d0c01ecef0967a"),
    # FIPS 180-4 example messages.
    ("abc", "53048e2681941ef99b2e29b76b4c7dabe4c2d0c634fc6d46e0e2f13107e7af23"),
    # 896 bits; pads into a second block.
    ("abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu", "3928e184fb8690f840da3988121d31be65cb9d3ef83ee6146feac861e19b563a"),
    # 448 bits; FIPS 180-4's SHA-256 two-block example.
    ("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq", "bde8e1f9f19bb9fd3406c90ec6bc47bd36d8ada9f11880dbc8a22a7078b6a461"),
    # The longest message whose padding fits in one block, and the shortest that doesn't.
    ("a" * 111, "0239e429f98d0ed61ee8e2a7c30afe98c1c3a80ce5dff62a107e9c538f7632ce"),
    ("a" * 112, "9216b5303edb66504570bee90e48ea5beaa5e9fe9f760bbd3e0460559fc005f6"),
    # Exactly one block of message; the padding is a block of its own.
    ("a" * 128, "b88f97e274f9c1d49f181c8cbd01a9c74930ad055a46ac4499a1d601f1c80bf2"),
    ("The quick brown fox jumps over the lazy dog", "dd9d67b371519c339ed8dbd25af90e976a1eeefd4ad3d889005e532fc5bef04d"),
    ("a" * 1000, "40eb4a70d4d69815407a9e272f0101cd67e3d11262a4a0bfc087712749c7fb53"),
    # Bazel reads this file as Latin-1, so this is the UTF-8 encoding of "héllo"
    # seen as six one-byte characters.
    ("héllo", "e85510cc4c72bb7889359626546beff905dcc4bf860796fde87f5a19f81e6c13"),
]
