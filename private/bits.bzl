"""Bit twiddling shared by the hash implementations.

Starlark ints are arbitrary precision, so there is no overflow to lean on:
every result is masked back to the word size.
"""

def rotl32(x, n):
    """Rotates a 32-bit word left.

    Args:
       x (int): The word, 0 to 0xFFFFFFFF
       n (int): The number of bits to rotate by, 1 to 31

    Returns:
       The rotated word
    """
    return ((x << n) | (x >> (32 - n))) & 0xFFFFFFFF

def rotr32(x, n):
    """Rotates a 32-bit word right.

    Args:
       x (int): The word, 0 to 0xFFFFFFFF
       n (int): The number of bits to rotate by, 1 to 31

    Returns:
       The rotated word
    """
    return ((x >> n) | (x << (32 - n))) & 0xFFFFFFFF

def rotr64(x, n):
    """Rotates a 64-bit word right.

    Args:
       x (int): The word, 0 to 0xFFFFFFFFFFFFFFFF
       n (int): The number of bits to rotate by, 1 to 63

    Returns:
       The rotated word
    """
    return ((x >> n) | (x << (64 - n))) & 0xFFFFFFFFFFFFFFFF
