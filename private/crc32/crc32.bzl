"""CRC-32 (ISO-HDLC, as in zlib, gzip and PNG) implemented in pure Starlark for portability."""

load("//private:bytes.bzl", "to_bytes")
load("//private:hex.bzl", "hex_words_be")

# The reflected form of the polynomial 0x04C11DB7: bits are processed least
# significant first.
_POLY = 0xEDB88320

def _make_table():
    # The CRC of each single byte; .bzl files can't loop at top level.
    table = []
    for n in range(256):
        c = n
        for _ in range(8):
            if c & 1:
                c = _POLY ^ (c >> 1)
            else:
                c = c >> 1
        table.append(c)
    return table

_TABLE = _make_table()

def crc32(input):
    """Computes the CRC-32 checksum of a byte string.

    Args:
        input: The byte string to checksum; see hashes.bzl.

    Returns:
        The checksum as 8 lowercase hex characters, most significant first.
    """
    crc = 0xFFFFFFFF
    for byte in to_bytes(input):
        # crc only ever shifts right, so it never grows past 32 bits.
        crc = _TABLE[(crc ^ byte) & 0xFF] ^ (crc >> 8)
    return hex_words_be([crc ^ 0xFFFFFFFF])
