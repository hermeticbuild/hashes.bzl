"""SHA3-224 known-answer vectors, shared by hash_kat_test and test_sha3_224.py."""

VECTORS = [
    ("", "6b4e03423667dbb73b6e15454f0eb1abd4597f9a1b078e3f5b5a6bc7"),
    # The FIPS 180-4 example messages, the usual SHA-3 test vectors too.
    ("abc", "e642824c3f8cf24ad09234ee7d3c766fc9a3a5168d0c94ad73b46fdf"),
    ("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq", "8a24108b154ada21c9fd5574494479ba5c7e7ab76ef264ead0fcce33"),
    ("abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu", "543e6868e1666c1a643630df77367ae5a62a85070a51c14cbf665cbc"),
    # One byte short of the 144-byte rate: the padding is the single byte 0x86.
    ("a" * 143, "73b1b22b54f515f626a6abdde6af25cd4801dc6e9dc7fa3f77e1c122"),
    # Exactly one block of message; the padding is a block of its own.
    ("a" * 144, "f9019111996dcf160e284e320fd6d8825cabcd41a5ffdc4c5e9d64b6"),
    ("The quick brown fox jumps over the lazy dog", "d15dadceaa4d5d7bb3b48f446421d542e08ad8887305e28d58335795"),
    ("a" * 1000, "2461344b84416db8fe01c2a4966fea019590c231dd5724c1bfc26745"),
    # Bazel reads this file as Latin-1, so this is the UTF-8 encoding of "héllo"
    # seen as six one-byte characters.
    ("héllo", "32f17327b74764afde8bffe6ab6c51e1131817d1d3cc7d8f9ac1e17a"),
]
