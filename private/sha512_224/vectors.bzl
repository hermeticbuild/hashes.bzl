"""SHA-512/224 known-answer vectors, shared by hash_kat_test and test_sha512_224.py."""

VECTORS = [
    ("", "6ed0dd02806fa89e25de060c19d3ac86cabb87d6a0ddd05c333b84f4"),
    # FIPS 180-4 example messages.
    ("abc", "4634270f707b6a54daae7530460842e20e37ed265ceee9a43e8924aa"),
    # 896 bits; pads into a second block.
    ("abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu", "23fec5bb94d60b23308192640b0c453335d664734fe40e7268674af9"),
    # 448 bits; FIPS 180-4's SHA-256 two-block example, a common SHA-512/224 vector too.
    ("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq", "e5302d6d54bb242275d1e7622d68df6eb02dedd13f564c13dbda2174"),
    # The longest message whose padding fits in one block, and the shortest that doesn't.
    ("a" * 111, "3ebe1b48e8c66acb9ae014db95b4bec93de7e9572bff41cf566bd7d0"),
    ("a" * 112, "79b41fef2a0439d2705724a67615f7bcbcd2bf5664a7774b80818eb6"),
    # Exactly one block of message; the padding is a block of its own.
    ("a" * 128, "261b94bcba554264b3b738e9e09e7dc68ac8e0b4c8517fe9bb7c3617"),
    ("The quick brown fox jumps over the lazy dog", "944cd2847fb54558d4775db0485a50003111c8e5daa63fe722c6aa37"),
    ("a" * 1000, "ffdfa284ae9e562222e2a37cd683823f7e669f3636477701f4ce9abe"),
    # Bazel reads this file as Latin-1, so this is the UTF-8 encoding of "héllo"
    # seen as six one-byte characters.
    ("héllo", "2b508b59e1d99e3eeb6ebdfff3fb5ce698f72266254db96b80786b96"),
]
