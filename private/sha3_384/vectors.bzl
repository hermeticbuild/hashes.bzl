"""SHA3-384 known-answer vectors, shared by hash_kat_test and test_sha3_384.py."""

VECTORS = [
    ("", "0c63a75b845e4f7d01107d852e4c2485c51a50aaaa94fc61995e71bbee983a2ac3713831264adb47fb6bd1e058d5f004"),
    # The FIPS 180-4 example messages, the usual SHA-3 test vectors too.
    ("abc", "ec01498288516fc926459f58e2c6ad8df9b473cb0fc08c2596da7cf0e49be4b298d88cea927ac7f539f1edf228376d25"),
    ("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq", "991c665755eb3a4b6bbdfb75c78a492e8c56a22c5c4d7e429bfdbc32b9d4ad5aa04a1f076e62fea19eef51acd0657c22"),
    ("abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu", "79407d3b5916b59c3e30b09822974791c313fb9ecc849e406f23592d04f625dc8c709b98b43b3852b337216179aa7fc7"),
    # One byte short of the 104-byte rate: the padding is the single byte 0x86.
    ("a" * 103, "af61fb4fd1c6afe80857fcba888318a0a1426635b4509f09707e3787630bdb621655ffa54f5884088ccc000f81436414"),
    # Exactly one block of message; the padding is a block of its own.
    ("a" * 104, "3a4f3b6284e571238884e95655e8c8a60e068e4059a9734abc08823a900d161592860243f00619ae699a29092ed91a16"),
    ("The quick brown fox jumps over the lazy dog", "7063465e08a93bce31cd89d2e3ca8f602498696e253592ed26f07bf7e703cf328581e1471a7ba7ab119b1a9ebdf8be41"),
    ("a" * 1000, "ccf4495ff20b4b33a1cc1917f9f0fe0fcb5e3d08e542cf4d4a90dd950b748e7e1cc07d2f3b36d62dd240724417cdd81b"),
    # Bazel reads this file as Latin-1, so this is the UTF-8 encoding of "héllo"
    # seen as six one-byte characters.
    ("héllo", "001ec1958d7ecb488476e308d05861dc73a26a785d8b078cbeba57ffc4b9ca16fd067e93c351db832ab765f08e3e0f00"),
]
