"""SHA-256 (FIPS 180-4) implemented in pure Starlark for portability."""

load("//private:bits.bzl", "rotr32")
load("//private:bytes.bzl", "md_pad", "to_bytes", "words_be")
load("//private:hex.bzl", "hex_words_be")

# --- SHA-256 Round Constants ---
# First 32 bits of the fractional parts of the cube roots of the first 64 primes.
_K = [
    0x428A2F98,
    0x71374491,
    0xB5C0FBCF,
    0xE9B5DBA5,
    0x3956C25B,
    0x59F111F1,
    0x923F82A4,
    0xAB1C5ED5,
    0xD807AA98,
    0x12835B01,
    0x243185BE,
    0x550C7DC3,
    0x72BE5D74,
    0x80DEB1FE,
    0x9BDC06A7,
    0xC19BF174,
    0xE49B69C1,
    0xEFBE4786,
    0x0FC19DC6,
    0x240CA1CC,
    0x2DE92C6F,
    0x4A7484AA,
    0x5CB0A9DC,
    0x76F988DA,
    0x983E5152,
    0xA831C66D,
    0xB00327C8,
    0xBF597FC7,
    0xC6E00BF3,
    0xD5A79147,
    0x06CA6351,
    0x14292967,
    0x27B70A85,
    0x2E1B2138,
    0x4D2C6DFC,
    0x53380D13,
    0x650A7354,
    0x766A0ABB,
    0x81C2C92E,
    0x92722C85,
    0xA2BFE8A1,
    0xA81A664B,
    0xC24B8B70,
    0xC76C51A3,
    0xD192E819,
    0xD6990624,
    0xF40E3585,
    0x106AA070,
    0x19A4C116,
    0x1E376C08,
    0x2748774C,
    0x34B0BCB5,
    0x391C0CB3,
    0x4ED8AA4A,
    0x5B9CCA4F,
    0x682E6FF3,
    0x748F82EE,
    0x78A5636F,
    0x84C87814,
    0x8CC70208,
    0x90BEFFFA,
    0xA4506CEB,
    0xBEF9A3F7,
    0xC67178F2,
]

def sha256(input):
    """Computes the SHA-256 digest of a byte string.

    Args:
        input: The byte string to hash; see hashes.bzl.

    Returns:
        The digest as 64 lowercase hex characters.
    """

    # --- SHA-256 Initial Hash Values ---
    # First 32 bits of the fractional parts of the square roots of the first 8 primes.
    h0 = 0x6A09E667
    h1 = 0xBB67AE85
    h2 = 0x3C6EF372
    h3 = 0xA54FF53A
    h4 = 0x510E527F
    h5 = 0x9B05688C
    h6 = 0x1F83D9AB
    h7 = 0x5BE0CD19

    message = md_pad(to_bytes(input), big_endian = True)

    for i in range(len(message) // 64):
        w = words_be(message[i * 64:(i + 1) * 64]) + [0] * 48

        for t in range(16, 64):
            # sigma0 and sigma1; note the plain shifts, not rotates, in their last terms.
            s0 = rotr32(w[t - 15], 7) ^ rotr32(w[t - 15], 18) ^ (w[t - 15] >> 3)
            s1 = rotr32(w[t - 2], 17) ^ rotr32(w[t - 2], 19) ^ (w[t - 2] >> 10)
            w[t] = (w[t - 16] + s0 + w[t - 7] + s1) & 0xFFFFFFFF

        a = h0
        b = h1
        c = h2
        d = h3
        e = h4
        f = h5
        g = h6
        h = h7

        for t in range(64):
            s1 = rotr32(e, 6) ^ rotr32(e, 11) ^ rotr32(e, 25)

            # Ch(e, f, g). ~e is -e - 1, which has every bit above 31 set, but
            # the & with g (< 2^32) discards them.
            ch = (e & f) ^ ((~e) & g)
            temp1 = (h + s1 + ch + _K[t] + w[t]) & 0xFFFFFFFF

            s0 = rotr32(a, 2) ^ rotr32(a, 13) ^ rotr32(a, 22)
            maj = (a & b) ^ (a & c) ^ (b & c)
            temp2 = (s0 + maj) & 0xFFFFFFFF

            h = g
            g = f
            f = e
            e = (d + temp1) & 0xFFFFFFFF
            d = c
            c = b
            b = a
            a = (temp1 + temp2) & 0xFFFFFFFF

        h0 = (h0 + a) & 0xFFFFFFFF
        h1 = (h1 + b) & 0xFFFFFFFF
        h2 = (h2 + c) & 0xFFFFFFFF
        h3 = (h3 + d) & 0xFFFFFFFF
        h4 = (h4 + e) & 0xFFFFFFFF
        h5 = (h5 + f) & 0xFFFFFFFF
        h6 = (h6 + g) & 0xFFFFFFFF
        h7 = (h7 + h) & 0xFFFFFFFF

    return hex_words_be([h0, h1, h2, h3, h4, h5, h6, h7])
