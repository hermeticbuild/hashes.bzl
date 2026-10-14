"""SHA-224 (FIPS 180-4) implemented in pure Starlark for portability."""

load("//private:bytes.bzl", "to_bytes")
load("//private:hex.bzl", "hex_words_be")
load("//private/sha256:sha256.bzl", "sha256_words")

# --- SHA-224 Initial Hash Values ---
# The second 32 bits of the fractional parts of the square roots of the 9th
# through 16th primes.
_IV = [
    0xC1059ED8,
    0x367CD507,
    0x3070DD17,
    0xF70E5939,
    0xFFC00B31,
    0x68581511,
    0x64F98FA7,
    0xBEFA4FA4,
]

def sha224(input):
    """Computes the SHA-224 digest of a byte string.

    Args:
        input: The byte string to hash; see hashes.bzl.

    Returns:
        The digest as 56 lowercase hex characters.
    """

    # SHA-256 with its own initial hash values, truncated to the first 7 words.
    return hex_words_be(sha256_words(to_bytes(input), _IV)[:7])
