"""SHA3-256 known-answer vectors, shared by hash_kat_test and test_sha3_256.py."""

VECTORS = [
    ("", "a7ffc6f8bf1ed76651c14756a061d662f580ff4de43b49fa82d80a4b80f8434a"),
    # The FIPS 180-4 example messages, the usual SHA-3 test vectors too.
    ("abc", "3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532"),
    ("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq", "41c0dba2a9d6240849100376a8235e2c82e1b9998a999e21db32dd97496d3376"),
    ("abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu", "916f6061fe879741ca6469b43971dfdb28b1a32dc36cb3254e812be27aad1d18"),
    # One byte short of the 136-byte rate: the padding is the single byte 0x86.
    ("a" * 135, "8094bb53c44cfb1e67b7c30447f9a1c33696d2463ecc1d9c92538913392843c9"),
    # Exactly one block of message; the padding is a block of its own.
    ("a" * 136, "3fc5559f14db8e453a0a3091edbd2bc25e11528d81c66fa570a4efdcc2695ee1"),
    ("The quick brown fox jumps over the lazy dog", "69070dda01975c8c120c3aada1b282394e7f032fa9cf32f4cb2259a0897dfc04"),
    ("a" * 1000, "8f3934e6f7a15698fe0f396b95d8c4440929a8fa6eae140171c068b4549fbf81"),
    # Bazel reads this file as Latin-1, so this is the UTF-8 encoding of "héllo"
    # seen as six one-byte characters.
    ("héllo", "af9db8307521b5e3d5549adcb8d6197a378902789c1649a9adb2c559c54943ac"),
]
