"""Property tests of the Starlark blake3 against the reference blake3 package."""

import pytest
from blake3 import blake3 as reference_blake3
from hypothesis import given, strategies as st

from private.blake3.blake3 import blake3
from private.blake3.vectors import VECTORS


def starlark_blake3(data: bytes) -> str:
    # Bazel strings are byte strings wearing a Latin-1 disguise.
    return blake3(data.decode("latin-1"))


def reference(data: bytes) -> str:
    return reference_blake3(data).hexdigest()


@pytest.mark.parametrize(("message", "digest"), VECTORS)
def test_known_answers(message, digest):
    assert blake3(message) == digest


@pytest.mark.parametrize(("message", "digest"), VECTORS)
def test_known_answers_match_reference(message, digest):
    assert reference(message.encode("latin-1")) == digest


# Every length across the block boundaries of the first chunk and into the
# second, where the tree first appears.
@pytest.mark.parametrize("length", range(1024 + 2 * 64 + 1))
def test_lengths(length):
    data = bytes(range(256)) * (length // 256 + 1)
    data = data[:length]
    assert starlark_blake3(data) == reference(data)


# Chunk boundaries of trees of up to 9 chunks: each power of two is a perfect
# tree, and every other count leaves a stack of subtrees to merge at the root.
@pytest.mark.parametrize("chunks", range(1, 10))
@pytest.mark.parametrize("delta", [-1, 0, 1])
def test_chunk_boundaries(chunks, delta):
    data = bytes(range(256)) * (4 * chunks + 1)
    data = data[: chunks * 1024 + delta]
    assert starlark_blake3(data) == reference(data)


@given(st.binary(max_size=1024))
def test_binary(data):
    assert starlark_blake3(data) == reference(data)


@given(st.binary(min_size=1025, max_size=8 * 1024))
def test_binary_multichunk(data):
    assert starlark_blake3(data) == reference(data)


@given(st.text())
def test_text(text):
    # What Bazel sees for a UTF-8 string literal.
    data = text.encode("utf-8")
    assert starlark_blake3(data) == reference(data)
