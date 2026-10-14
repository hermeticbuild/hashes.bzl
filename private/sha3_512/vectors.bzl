"""SHA3-512 known-answer vectors, shared by hash_kat_test and test_sha3_512.py."""

VECTORS = [
    ("", "a69f73cca23a9ac5c8b567dc185a756e97c982164fe25859e0d1dcc1475c80a615b2123af1f5f94c11e3e9402c3ac558f500199d95b6d3e301758586281dcd26"),
    # The FIPS 180-4 example messages, the usual SHA-3 test vectors too.
    ("abc", "b751850b1a57168a5693cd924b6b096e08f621827444f70d884f5d0240d2712e10e116e9192af3c91a7ec57647e3934057340b4cf408d5a56592f8274eec53f0"),
    ("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq", "04a371e84ecfb5b8b77cb48610fca8182dd457ce6f326a0fd3d7ec2f1e91636dee691fbe0c985302ba1b0d8dc78c086346b533b49c030d99a27daf1139d6e75e"),
    ("abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu", "afebb2ef542e6579c50cad06d2e578f9f8dd6881d7dc824d26360feebf18a4fa73e3261122948efcfd492e74e82e2189ed0fb440d187f382270cb455f21dd185"),
    # One byte short of the 72-byte rate: the padding is the single byte 0x86.
    ("a" * 71, "070faf98d2a8fddf8ed886408744dc06456096c2e045f26f3c7b010530e6bbb3db535a54d636856f4e0e1e982461cb9a7e8e57ff8895cff1619af9f0e486e28c"),
    # Exactly one block of message; the padding is a block of its own.
    ("a" * 72, "a8ae722a78e10cbbc413886c02eb5b369a03f6560084aff566bd597bb7ad8c1ccd86e81296852359bf2faddb5153c0a7445722987875e74287adac21adebe952"),
    ("The quick brown fox jumps over the lazy dog", "01dedd5de4ef14642445ba5f5b97c15e47b9ad931326e4b0727cd94cefc44fff23f07bf543139939b49128caf436dc1bdee54fcb24023a08d9403f9b4bf0d450"),
    ("a" * 1000, "ac7e95cc95aa7f24aaa95e040ca0c79b39cd9cc84a10abb84ddd8dd5e4b45cf96543aaa70d0ef99fbf8d2769639981ee1fd0b0276f4756b9d504d0b7de19b700"),
    # Bazel reads this file as Latin-1, so this is the UTF-8 encoding of "héllo"
    # seen as six one-byte characters.
    ("héllo", "d2afc6ebcc64f91017b4b42b22cd6f33e27beaf43019bab56994c722d224ee25e7c9110fbcdfd7bc6f89cf1e6c53dcfe39a793d7937c59101e1c21d6a20cf452"),
]
