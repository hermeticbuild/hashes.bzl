"""SHA3-256 (FIPS 202) implemented in pure Starlark for portability."""

load("//private:bytes.bzl", "to_bytes")
load("//private/keccak:keccak.bzl", "sha3_hex")

def sha3_256(input):
    """Computes the SHA3-256 digest of a byte string.

    Args:
        input: The byte string to hash; see hashes.bzl.

    Returns:
        The digest as 64 lowercase hex characters.
    """
    return sha3_hex(to_bytes(input), 32)
