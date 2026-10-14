"""MD5 (RFC 1321) implemented in pure Starlark for portability."""

load("//private:bits.bzl", "rotl32")
load("//private:bytes.bzl", "md_pad", "to_bytes", "words_le")
load("//private:hex.bzl", "hex_words_le")

# Per-step constants: _K[i] = floor(abs(sin(i + 1)) * 2^32).
_K = [
    0xD76AA478,
    0xE8C7B756,
    0x242070DB,
    0xC1BDCEEE,
    0xF57C0FAF,
    0x4787C62A,
    0xA8304613,
    0xFD469501,
    0x698098D8,
    0x8B44F7AF,
    0xFFFF5BB1,
    0x895CD7BE,
    0x6B901122,
    0xFD987193,
    0xA679438E,
    0x49B40821,
    0xF61E2562,
    0xC040B340,
    0x265E5A51,
    0xE9B6C7AA,
    0xD62F105D,
    0x02441453,
    0xD8A1E681,
    0xE7D3FBC8,
    0x21E1CDE6,
    0xC33707D6,
    0xF4D50D87,
    0x455A14ED,
    0xA9E3E905,
    0xFCEFA3F8,
    0x676F02D9,
    0x8D2A4C8A,
    0xFFFA3942,
    0x8771F681,
    0x6D9D6122,
    0xFDE5380C,
    0xA4BEEA44,
    0x4BDECFA9,
    0xF6BB4B60,
    0xBEBFBC70,
    0x289B7EC6,
    0xEAA127FA,
    0xD4EF3085,
    0x04881D05,
    0xD9D4D039,
    0xE6DB99E5,
    0x1FA27CF8,
    0xC4AC5665,
    0xF4292244,
    0x432AFF97,
    0xAB9423A7,
    0xFC93A039,
    0x655B59C3,
    0x8F0CCC92,
    0xFFEFF47D,
    0x85845DD1,
    0x6FA87E4F,
    0xFE2CE6E0,
    0xA3014314,
    0x4E0811A1,
    0xF7537E82,
    0xBD3AF235,
    0x2AD7D2BB,
    0xEB86D391,
]

# Per-step left-rotation amounts; one row per round of 16 steps, cycling
# through its four entries.
_S = [
    [7, 12, 17, 22],
    [5, 9, 14, 20],
    [4, 11, 16, 23],
    [6, 10, 15, 21],
]

def md5(input):
    """Computes the MD5 digest of a byte string.

    Args:
        input: The byte string to hash; see hashes.bzl.

    Returns:
        The digest as 32 lowercase hex characters.
    """

    # --- MD5 Initial Hash Values ---
    h0 = 0x67452301
    h1 = 0xEFCDAB89
    h2 = 0x98BADCFE
    h3 = 0x10325476

    # Unlike SHA, MD5 is little-endian throughout: the appended length, the
    # message words and the digest.
    message = md_pad(to_bytes(input), big_endian = False)

    for i in range(len(message) // 64):
        m = words_le(message[i * 64:(i + 1) * 64])

        a = h0
        b = h1
        c = h2
        d = h3

        for t in range(64):
            if t <= 15:
                f = (b & c) | ((~b) & d)
                g = t
            elif t <= 31:
                f = (d & b) | ((~d) & c)
                g = (5 * t + 1) % 16
            elif t <= 47:
                f = b ^ c ^ d
                g = (3 * t + 5) % 16
            else:
                # ~d is negative; mask it back to 32 bits before the xor.
                f = c ^ (b | ((~d) & 0xFFFFFFFF))
                g = (7 * t) % 16

            temp = (a + f + _K[t] + m[g]) & 0xFFFFFFFF

            a = d
            d = c
            c = b
            b = (b + rotl32(temp, _S[t // 16][t % 4])) & 0xFFFFFFFF

        h0 = (h0 + a) & 0xFFFFFFFF
        h1 = (h1 + b) & 0xFFFFFFFF
        h2 = (h2 + c) & 0xFFFFFFFF
        h3 = (h3 + d) & 0xFFFFFFFF

    return hex_words_le([h0, h1, h2, h3])
