"""SHA-1 (FIPS 180-4) implemented in pure Starlark for portability."""

load("//private:bits.bzl", "rotl32")
load("//private:bytes.bzl", "md_pad", "to_bytes", "words_be")
load("//private:hex.bzl", "hex_words_be")

def sha1(input):
    """Computes the SHA-1 digest of a byte string.

    Args:
        input: The byte string to hash; see hashes.bzl.

    Returns:
        The digest as 40 lowercase hex characters.
    """

    # --- SHA-1 Constants and Initial Hash Values ---
    h0 = 0x67452301
    h1 = 0xEFCDAB89
    h2 = 0x98BADCFE
    h3 = 0x10325476
    h4 = 0xC3D2E1F0

    k = [
        0x5A827999,  # 0 <= t <= 19
        0x6ED9EBA1,  # 20 <= t <= 39
        0x8F1BBCDC,  # 40 <= t <= 59
        0xCA62C1D6,  # 60 <= t <= 79
    ]

    message = md_pad(to_bytes(input), big_endian = True)

    for i in range(len(message) // 64):
        w = words_be(message[i * 64:(i + 1) * 64]) + [0] * 64

        for t in range(16, 80):
            w[t] = rotl32(w[t - 3] ^ w[t - 8] ^ w[t - 14] ^ w[t - 16], 1)

        a = h0
        b = h1
        c = h2
        d = h3
        e = h4

        for t in range(80):
            if t <= 19:
                f = (b & c) | ((~b) & d)
                kt = k[0]
            elif t <= 39:
                f = b ^ c ^ d
                kt = k[1]
            elif t <= 59:
                f = (b & c) | (b & d) | (c & d)
                kt = k[2]
            else:
                f = b ^ c ^ d
                kt = k[3]

            temp = (rotl32(a, 5) + f + e + kt + w[t]) & 0xFFFFFFFF

            e = d
            d = c
            c = rotl32(b, 30)
            b = a
            a = temp

        h0 = (h0 + a) & 0xFFFFFFFF
        h1 = (h1 + b) & 0xFFFFFFFF
        h2 = (h2 + c) & 0xFFFFFFFF
        h3 = (h3 + d) & 0xFFFFFFFF
        h4 = (h4 + e) & 0xFFFFFFFF

    return hex_words_be([h0, h1, h2, h3, h4])
