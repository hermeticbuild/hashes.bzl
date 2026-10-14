"""SHA-224 known-answer vectors, shared by hash_kat_test and test_sha224.py."""

VECTORS = [
    ("", "d14a028c2a3a2bc9476102bb288234c415a2b01f828ea62ac5b3e42f"),
    # FIPS 180-4 example messages.
    ("abc", "23097d223405d8228642a477bda255b32aadbce4bda0b3f7e36c9da7"),
    # Pads into a second block.
    ("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq", "75388b16512776cc5dba5da1fd890150b0c6455cb4f58b1952522525"),
    # 896 bits; FIPS 180-4's SHA-512 example message, a common SHA-224 vector too.
    ("abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu", "c97ca9a559850ce97a04a96def6d99a9e0e0e2ab14e6b8df265fc0b3"),
    ("The quick brown fox jumps over the lazy dog", "730e109bd7a8a32b1cb9d9a09aa2325d2430587ddbc0c38bad911525"),
    ("a" * 1000, "4e8f0ce90b64661a2b5e84be6d93a7d9b76871062f1814433d04a03d"),
    # Bazel reads this file as Latin-1, so this is the UTF-8 encoding of "héllo"
    # seen as six one-byte characters.
    ("héllo", "2ed034dbfd665018cad24af1a17b76de85cbd9bf3040d702023ce9ec"),
]
