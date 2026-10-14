"""SHA-512 (FIPS 180-4) implemented in pure Starlark for portability."""

load("//private:bits.bzl", "rotr64")
load("//private:bytes.bzl", "md_pad", "to_bytes", "words64_be")
load("//private:hex.bzl", "hex_words64_be")

_MASK64 = 0xFFFFFFFFFFFFFFFF

# --- SHA-512 Round Constants ---
# First 64 bits of the fractional parts of the cube roots of the first 80 primes.
_K = [
    0x428A2F98D728AE22,
    0x7137449123EF65CD,
    0xB5C0FBCFEC4D3B2F,
    0xE9B5DBA58189DBBC,
    0x3956C25BF348B538,
    0x59F111F1B605D019,
    0x923F82A4AF194F9B,
    0xAB1C5ED5DA6D8118,
    0xD807AA98A3030242,
    0x12835B0145706FBE,
    0x243185BE4EE4B28C,
    0x550C7DC3D5FFB4E2,
    0x72BE5D74F27B896F,
    0x80DEB1FE3B1696B1,
    0x9BDC06A725C71235,
    0xC19BF174CF692694,
    0xE49B69C19EF14AD2,
    0xEFBE4786384F25E3,
    0x0FC19DC68B8CD5B5,
    0x240CA1CC77AC9C65,
    0x2DE92C6F592B0275,
    0x4A7484AA6EA6E483,
    0x5CB0A9DCBD41FBD4,
    0x76F988DA831153B5,
    0x983E5152EE66DFAB,
    0xA831C66D2DB43210,
    0xB00327C898FB213F,
    0xBF597FC7BEEF0EE4,
    0xC6E00BF33DA88FC2,
    0xD5A79147930AA725,
    0x06CA6351E003826F,
    0x142929670A0E6E70,
    0x27B70A8546D22FFC,
    0x2E1B21385C26C926,
    0x4D2C6DFC5AC42AED,
    0x53380D139D95B3DF,
    0x650A73548BAF63DE,
    0x766A0ABB3C77B2A8,
    0x81C2C92E47EDAEE6,
    0x92722C851482353B,
    0xA2BFE8A14CF10364,
    0xA81A664BBC423001,
    0xC24B8B70D0F89791,
    0xC76C51A30654BE30,
    0xD192E819D6EF5218,
    0xD69906245565A910,
    0xF40E35855771202A,
    0x106AA07032BBD1B8,
    0x19A4C116B8D2D0C8,
    0x1E376C085141AB53,
    0x2748774CDF8EEB99,
    0x34B0BCB5E19B48A8,
    0x391C0CB3C5C95A63,
    0x4ED8AA4AE3418ACB,
    0x5B9CCA4F7763E373,
    0x682E6FF3D6B2B8A3,
    0x748F82EE5DEFB2FC,
    0x78A5636F43172F60,
    0x84C87814A1F0AB72,
    0x8CC702081A6439EC,
    0x90BEFFFA23631E28,
    0xA4506CEBDE82BDE9,
    0xBEF9A3F7B2C67915,
    0xC67178F2E372532B,
    0xCA273ECEEA26619C,
    0xD186B8C721C0C207,
    0xEADA7DD6CDE0EB1E,
    0xF57D4F7FEE6ED178,
    0x06F067AA72176FBA,
    0x0A637DC5A2C898A6,
    0x113F9804BEF90DAE,
    0x1B710B35131C471B,
    0x28DB77F523047D84,
    0x32CAAB7B40C72493,
    0x3C9EBE0A15C9BEBC,
    0x431D67C49C100D4C,
    0x4CC5D4BECB3E42B6,
    0x597F299CFC657E2A,
    0x5FCB6FAB3AD6FAEC,
    0x6C44198C4A475817,
]

# --- SHA-512 Initial Hash Values ---
# First 64 bits of the fractional parts of the square roots of the first 8 primes.
_IV = [
    0x6A09E667F3BCC908,
    0xBB67AE8584CAA73B,
    0x3C6EF372FE94F82B,
    0xA54FF53A5F1D36F1,
    0x510E527FADE682D1,
    0x9B05688C2B3E6C1F,
    0x1F83D9ABFB41BD6B,
    0x5BE0CD19137E2179,
]

def sha512_words(data, iv):
    """Runs the SHA-512 compression function over a message.

    The core shared by the SHA-512 family. SHA-384, SHA-512/224 and
    SHA-512/256 differ from SHA-512 only in their initial hash values and in
    how much of the result they keep, so each is
    `sha512_words(to_bytes(input), <its IV>)`, truncated and formatted, e.g.
    with `hex_words64_be(words[:6])` for SHA-384. For SHA-512/224, whose 224
    bits end mid-word, format the first 4 words and drop the last 8 hex
    characters.

    Args:
        data (list[int]): The message bytes, unpadded, as `to_bytes` returns;
            this pads them (FIPS 180-4 5.1.2).
        iv (list[int]): The 8 initial 64-bit hash values H(0).

    Returns:
        The 8 final 64-bit hash words H(N), each 0 to 0xFFFFFFFFFFFFFFFF.
    """
    h0, h1, h2, h3, h4, h5, h6, h7 = iv

    message = md_pad(data, big_endian = True, block_size = 128)

    for i in range(len(message) // 128):
        w = words64_be(message[i * 128:(i + 1) * 128]) + [0] * 64

        for t in range(16, 80):
            # sigma0 and sigma1; note the plain shifts, not rotates, in their last terms.
            s0 = rotr64(w[t - 15], 1) ^ rotr64(w[t - 15], 8) ^ (w[t - 15] >> 7)
            s1 = rotr64(w[t - 2], 19) ^ rotr64(w[t - 2], 61) ^ (w[t - 2] >> 6)
            w[t] = (w[t - 16] + s0 + w[t - 7] + s1) & _MASK64

        a = h0
        b = h1
        c = h2
        d = h3
        e = h4
        f = h5
        g = h6
        h = h7

        for t in range(80):
            s1 = rotr64(e, 14) ^ rotr64(e, 18) ^ rotr64(e, 41)

            # Ch(e, f, g). ~e is -e - 1, which has every bit above 63 set, but
            # the & with g (< 2^64) discards them.
            ch = (e & f) ^ ((~e) & g)
            temp1 = (h + s1 + ch + _K[t] + w[t]) & _MASK64

            s0 = rotr64(a, 28) ^ rotr64(a, 34) ^ rotr64(a, 39)
            maj = (a & b) ^ (a & c) ^ (b & c)
            temp2 = (s0 + maj) & _MASK64

            h = g
            g = f
            f = e
            e = (d + temp1) & _MASK64
            d = c
            c = b
            b = a
            a = (temp1 + temp2) & _MASK64

        h0 = (h0 + a) & _MASK64
        h1 = (h1 + b) & _MASK64
        h2 = (h2 + c) & _MASK64
        h3 = (h3 + d) & _MASK64
        h4 = (h4 + e) & _MASK64
        h5 = (h5 + f) & _MASK64
        h6 = (h6 + g) & _MASK64
        h7 = (h7 + h) & _MASK64

    return [h0, h1, h2, h3, h4, h5, h6, h7]

def sha512(input):
    """Computes the SHA-512 digest of a byte string.

    Args:
        input: The byte string to hash; see hashes.bzl.

    Returns:
        The digest as 128 lowercase hex characters.
    """
    return hex_words64_be(sha512_words(to_bytes(input), _IV))
