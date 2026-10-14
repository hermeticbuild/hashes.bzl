"""The Keccak sponge behind SHA-3 (FIPS 202), implemented in pure Starlark for portability."""

load("//private:bytes.bzl", "words64_le")
load("//private:hex.bzl", "hex_words_le")

_MASK64 = 0xFFFFFFFFFFFFFFFF

# The state is 25 64-bit lanes; lane (x, y) is at index x + 5 * y.

# --- Keccak-f[1600] Round Constants ---
# FIPS 202 3.2.5; the output of an LFSR, one per round.
_RC = [
    0x0000000000000001,
    0x0000000000008082,
    0x800000000000808A,
    0x8000000080008000,
    0x000000000000808B,
    0x0000000080000001,
    0x8000000080008081,
    0x8000000000008009,
    0x000000000000008A,
    0x0000000000000088,
    0x0000000080008009,
    0x000000008000000A,
    0x000000008000808B,
    0x800000000000008B,
    0x8000000000008089,
    0x8000000000008003,
    0x8000000000008002,
    0x8000000000000080,
    0x000000000000800A,
    0x800000008000000A,
    0x8000000080008081,
    0x8000000000008080,
    0x0000000080000001,
    0x8000000080008008,
]

# rho's rotation of each lane; FIPS 202 3.2.2, Table 2.
_RHO = [
    0,
    1,
    62,
    28,
    27,
    36,
    44,
    6,
    55,
    20,
    3,
    10,
    43,
    25,
    39,
    41,
    45,
    15,
    21,
    8,
    18,
    2,
    61,
    56,
    14,
]

# pi moves lane (x, y) to (y, 2x + 3y).
_PI = [i // 5 + 5 * ((2 * (i % 5) + 3 * (i // 5)) % 5) for i in range(25)]

# chi combines each lane with the next two in its row.
_CHI1 = [(i + 1) % 5 + 5 * (i // 5) for i in range(25)]
_CHI2 = [(i + 2) % 5 + 5 * (i // 5) for i in range(25)]

def _keccak_f1600(a):
    """Applies the Keccak-f[1600] permutation.

    Args:
        a (list[int]): The 25 lanes

    Returns:
        The permuted lanes
    """
    for rc in _RC:
        # theta: xor each lane with the parities of two neighbouring columns.
        c = [a[x] ^ a[x + 5] ^ a[x + 10] ^ a[x + 15] ^ a[x + 20] for x in range(5)]
        d = [
            c[(x + 4) % 5] ^ (((c[(x + 1) % 5] << 1) | (c[(x + 1) % 5] >> 63)) & _MASK64)
            for x in range(5)
        ]

        # rho and pi: rotate each lane, then move it.
        b = [0] * 25
        for i in range(25):
            v = a[i] ^ d[i % 5]
            n = _RHO[i]
            b[_PI[i]] = ((v << n) | (v >> (64 - n))) & _MASK64

        # chi, the only nonlinear step. As in SHA-256's Ch, ~ sets every bit
        # above 63, and the & discards them.
        a = [b[i] ^ ((~b[_CHI1[i]]) & b[_CHI2[i]]) for i in range(25)]

        # iota
        a[0] ^= rc

    return a

def sha3_hex(data, length):
    """Computes a SHA-3 digest.

    Args:
        data (list[int]): The message bytes, as from to_bytes
        length (int): The digest length in bytes: 28, 32, 48 or 64

    Returns:
        The digest as lowercase hex
    """

    # The capacity is twice the digest length; the rest of the 200-byte state
    # is the rate, the bytes absorbed per permutation.
    rate = 200 - 2 * length

    # The 01 domain separation bits for SHA-3, then pad10*1: a 1 bit, zeros,
    # and a 1 bit ending the block. When only one byte is left, the first and
    # last 1 bits share it.
    message = data + [0x06] + [0] * ((-len(data) - 1) % rate)
    message[-1] |= 0x80

    lanes = words64_le(message)
    rate_lanes = rate // 8

    state = [0] * 25
    for i in range(0, len(lanes), rate_lanes):
        for j in range(rate_lanes):
            state[j] ^= lanes[i + j]
        state = _keccak_f1600(state)

    # Every SHA-3 digest is shorter than the rate, so one squeeze suffices.
    words = [word for lane in state for word in [lane & 0xFFFFFFFF, lane >> 32]]
    return hex_words_le(words[:length // 4])
