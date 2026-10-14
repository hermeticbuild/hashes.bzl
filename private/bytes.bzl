"""Byte-level helpers shared by the hash implementations."""

load("@bazel_lib//lib:strings.bzl", "ord")

def to_bytes(input):
    """Converts a byte string to a list of byte values.

    Bazel represents bytes as strings of characters U+0000 to U+00FF (file
    contents and BUILD/.bzl literals are read as Latin-1), as bazel_lib's
    `base64` does. Anything else isn't a byte.

    Args:
       input (string): The byte string

    Returns:
       A list of ints, 0 to 255
    """
    result = []
    for char in input.elems():
        byte = ord(char)
        if byte == None:
            fail("hash input must be a byte string, but contains {}".format(repr(char)))
        result.append(byte)
    return result

def words_be(data):
    """Packs bytes into 32-bit words, most significant byte first.

    Args:
       data (list[int]): The bytes; a multiple of 4 long

    Returns:
       A list of words
    """
    return [
        (data[i] << 24) | (data[i + 1] << 16) | (data[i + 2] << 8) | data[i + 3]
        for i in range(0, len(data), 4)
    ]

def words_le(data):
    """Packs bytes into 32-bit words, least significant byte first.

    Args:
       data (list[int]): The bytes; a multiple of 4 long

    Returns:
       A list of words
    """
    return [
        data[i] | (data[i + 1] << 8) | (data[i + 2] << 16) | (data[i + 3] << 24)
        for i in range(0, len(data), 4)
    ]

def md_pad(data, big_endian):
    """Applies Merkle-Damgard padding for 64-byte blocks, as MD5 and SHA-1/2 do.

    Appends a 1 bit, then zeros up to 8 bytes short of a block boundary, then
    the message length in bits as a 64-bit integer.

    Args:
       data (list[int]): The message bytes
       big_endian (bool): Whether to append the length most significant byte
           first (SHA) rather than least (MD5)

    Returns:
       The padded bytes; a multiple of 64 long
    """
    length = [((len(data) * 8) >> (8 * i)) & 0xFF for i in range(8)]
    if big_endian:
        length = length[::-1]
    return data + [0x80] + [0] * ((55 - len(data)) % 64) + length
