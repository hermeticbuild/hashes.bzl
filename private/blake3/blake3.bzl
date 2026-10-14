"""BLAKE3 implemented in pure Starlark for portability.

Only the default unkeyed hash mode with the default 32-byte output is provided.
"""

load("//private:bits.bzl", "rotr32")
load("//private:bytes.bzl", "to_bytes", "words_le")
load("//private:hex.bzl", "hex_words_le")

# --- BLAKE3 Constants ---
_BLOCK_LEN = 64
_CHUNK_LEN = 1024

# Domain separation flags.
_CHUNK_START = 1 << 0
_CHUNK_END = 1 << 1
_PARENT = 1 << 2
_ROOT = 1 << 3

# The SHA-256 initial hash values.
_IV = [
    0x6A09E667,
    0xBB67AE85,
    0x3C6EF372,
    0xA54FF53A,
    0x510E527F,
    0x9B05688C,
    0x1F83D9AB,
    0x5BE0CD19,
]

_MSG_PERMUTATION = [2, 6, 3, 10, 7, 0, 4, 13, 1, 11, 12, 5, 9, 14, 15, 8]

def _g(v, a, b, c, d, mx, my):
    """The quarter-round, mixing two message words into four state words in place.

    Args:
        v: The 16-word state, updated in place.
        a: Index of the first state word.
        b: Index of the second state word.
        c: Index of the third state word.
        d: Index of the fourth state word.
        mx: The first message word.
        my: The second message word.
    """
    v[a] = (v[a] + v[b] + mx) & 0xFFFFFFFF
    v[d] = rotr32(v[d] ^ v[a], 16)
    v[c] = (v[c] + v[d]) & 0xFFFFFFFF
    v[b] = rotr32(v[b] ^ v[c], 12)
    v[a] = (v[a] + v[b] + my) & 0xFFFFFFFF
    v[d] = rotr32(v[d] ^ v[a], 8)
    v[c] = (v[c] + v[d]) & 0xFFFFFFFF
    v[b] = rotr32(v[b] ^ v[c], 7)

def _compress(cv, m, counter, block_len, flags):
    """The BLAKE3 compression function.

    Args:
        cv: The 8-word input chaining value.
        m: The 16-word message block.
        counter: The 64-bit block counter (chunk index; 0 for parents).
        block_len: The number of message bytes in the block.
        flags: The domain separation flags.

    Returns:
        The first 8 words of the output, which are both the chaining value and
        (with ROOT set) the 32-byte default hash.
    """
    v = cv + _IV[0:4] + [
        counter & 0xFFFFFFFF,
        (counter >> 32) & 0xFFFFFFFF,
        block_len,
        flags,
    ]

    for r in range(7):
        # Columns.
        _g(v, 0, 4, 8, 12, m[0], m[1])
        _g(v, 1, 5, 9, 13, m[2], m[3])
        _g(v, 2, 6, 10, 14, m[4], m[5])
        _g(v, 3, 7, 11, 15, m[6], m[7])

        # Diagonals.
        _g(v, 0, 5, 10, 15, m[8], m[9])
        _g(v, 1, 6, 11, 12, m[10], m[11])
        _g(v, 2, 7, 8, 13, m[12], m[13])
        _g(v, 3, 4, 9, 14, m[14], m[15])

        if r < 6:
            m = [m[p] for p in _MSG_PERMUTATION]

    return [v[i] ^ v[i + 8] for i in range(8)]

def _block_words(block):
    """Reads up to 64 bytes as 16 little-endian words, zero padding the tail."""
    return words_le(block + [0] * (_BLOCK_LEN - len(block)))

def _chunk_output(chunk, counter):
    """Compresses all but the last block of a chunk.

    Args:
        chunk: Up to 1024 bytes; empty only when the whole input is.
        counter: The index of this chunk in the input.

    Returns:
        The (cv, words, counter, block_len, flags) of the chunk's last block,
        uncompressed because it may yet need the ROOT flag.
    """
    num_blocks = max(1, (len(chunk) + _BLOCK_LEN - 1) // _BLOCK_LEN)

    cv = _IV
    flags = _CHUNK_START
    for i in range(num_blocks - 1):
        block = chunk[i * _BLOCK_LEN:(i + 1) * _BLOCK_LEN]
        cv = _compress(cv, _block_words(block), counter, _BLOCK_LEN, flags)
        flags = 0

    block = chunk[(num_blocks - 1) * _BLOCK_LEN:]
    return (cv, _block_words(block), counter, len(block), flags | _CHUNK_END)

def _parent_output(left_cv, right_cv):
    """The uncompressed output of a parent node over two child chaining values."""
    return (_IV, left_cv + right_cv, 0, _BLOCK_LEN, _PARENT)

def _chaining_value(output):
    """Compresses a non-root output into its chaining value."""
    cv, words, counter, block_len, flags = output
    return _compress(cv, words, counter, block_len, flags)

def blake3(input):
    """Computes the BLAKE3 digest of a byte string.

    Args:
        input: The byte string to hash; see hashes.bzl.

    Returns:
        The default 32-byte digest as 64 lowercase hex characters.
    """

    message_bytes_list = to_bytes(input)

    num_chunks = max(1, (len(message_bytes_list) + _CHUNK_LEN - 1) // _CHUNK_LEN)

    # Chaining values of complete subtrees, largest (leftmost) first. Every
    # chunk but the last is known not to be the root, so each is merged with
    # its left neighbours as soon as it completes a subtree: chunk n completes
    # one subtree for each trailing zero bit of n + 1.
    cv_stack = []
    for i in range(num_chunks - 1):
        chunk = message_bytes_list[i * _CHUNK_LEN:(i + 1) * _CHUNK_LEN]
        cv = _chaining_value(_chunk_output(chunk, i))

        total_chunks = i + 1
        for _ in range(64):
            if total_chunks & 1:
                break
            cv = _chaining_value(_parent_output(cv_stack.pop(), cv))
            total_chunks = total_chunks >> 1

        cv_stack.append(cv)

    # The last chunk, which may be partial, is folded into the stack from the
    # right, leaving the root node's output uncompressed.
    last = num_chunks - 1
    output = _chunk_output(message_bytes_list[last * _CHUNK_LEN:], last)
    for left_cv in reversed(cv_stack):
        output = _parent_output(left_cv, _chaining_value(output))

    cv, words, counter, block_len, flags = output
    h = _compress(cv, words, counter, block_len, flags | _ROOT)

    return hex_words_le(h)
