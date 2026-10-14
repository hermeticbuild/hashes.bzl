"""SHA-384 (FIPS 180-4) implemented in pure Starlark for portability."""

load("//private:bytes.bzl", "to_bytes")
load("//private:hex.bzl", "hex_words64_be")
load("//private/sha512:sha512.bzl", "sha512_words")

# --- SHA-384 Initial Hash Values ---
# First 64 bits of the fractional parts of the square roots of the 9th through
# 16th primes.
_IV = [
    0xCBBB9D5DC1059ED8,
    0x629A292A367CD507,
    0x9159015A3070DD17,
    0x152FECD8F70E5939,
    0x67332667FFC00B31,
    0x8EB44A8768581511,
    0xDB0C2E0D64F98FA7,
    0x47B5481DBEFA4FA4,
]

def sha384(input):
    """Computes the SHA-384 digest of a byte string.

    Args:
        input: The byte string to hash; see hashes.bzl.

    Returns:
        The digest as 96 lowercase hex characters.
    """

    # SHA-512 with its own initial hash values, truncated to the first 6 words.
    return hex_words64_be(sha512_words(to_bytes(input), _IV)[:6])
