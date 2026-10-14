"""Byte-level helpers shared by the hash implementations."""

load("//private:ord.bzl", "ord")

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
            fail(
                "hash input must be a byte string (characters U+0000 to U+00FF), " +
                "but contains {}; before Bazel 8.2, json.decode produces such ".format(repr(char)) +
                "characters for \\u escapes",
            )
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

def words64_be(data):
    """Packs bytes into 64-bit words, most significant byte first.

    Args:
       data (list[int]): The bytes; a multiple of 8 long

    Returns:
       A list of words
    """
    words = words_be(data)
    return [(hi << 32) | lo for hi, lo in zip(words[0::2], words[1::2])]

def words64_le(data):
    """Packs bytes into 64-bit words, least significant byte first.

    Args:
       data (list[int]): The bytes; a multiple of 8 long

    Returns:
       A list of words
    """
    words = words_le(data)
    return [(hi << 32) | lo for lo, hi in zip(words[0::2], words[1::2])]

def md_pad(data, big_endian, block_size = 64):
    """Applies Merkle-Damgard padding, as MD5 and SHA-1/2 do.

    Appends a 1 bit, then zeros up to a length field short of a block boundary,
    then the message length in bits. The length field is 8 bytes for 64-byte
    blocks (MD5, SHA-1, SHA-224/256) and 16 for 128-byte blocks (SHA-384/512).

    Args:
       data (list[int]): The message bytes
       big_endian (bool): Whether to append the length most significant byte
           first (SHA) rather than least (MD5)
       block_size (int): The block size in bytes, 64 or 128

    Returns:
       The padded bytes; a multiple of block_size long
    """
    length_size = block_size // 8
    length = [((len(data) * 8) >> (8 * i)) & 0xFF for i in range(length_size)]
    if big_endian:
        length = length[::-1]
    zeros = (block_size - 1 - length_size - len(data)) % block_size
    return data + [0x80] + [0] * zeros + length
