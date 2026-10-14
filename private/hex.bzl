"""Hex formatting of digest words, shared by the hash implementations."""

_HEX_CHARS = "0123456789abcdef"

def hex_words_be(words):
    """Formats 32-bit words as hex, each most significant byte first (SHA).

    Args:
       words (list[int]): The digest words

    Returns:
       The hex digest, 8 characters per word
    """
    return "".join([
        _HEX_CHARS[(word >> shift) & 0xF]
        for word in words
        for shift in [28, 24, 20, 16, 12, 8, 4, 0]
    ])

def hex_words_le(words):
    """Formats 32-bit words as hex, each least significant byte first (MD5, BLAKE3).

    Args:
       words (list[int]): The digest words

    Returns:
       The hex digest, 8 characters per word
    """
    return "".join([
        _HEX_CHARS[(word >> shift) & 0xF]
        for word in words
        for shift in [4, 0, 12, 8, 20, 16, 28, 24]
    ])

def hex_words64_be(words):
    """Formats 64-bit words as hex, each most significant byte first (SHA-512).

    Args:
       words (list[int]): The digest words

    Returns:
       The hex digest, 16 characters per word
    """
    return hex_words_be([(word >> shift) & 0xFFFFFFFF for word in words for shift in [32, 0]])
