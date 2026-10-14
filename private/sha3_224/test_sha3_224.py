"""Property tests of the Starlark sha3_224 against hashlib."""

import hashlib

import pytest
from hypothesis import given, strategies as st

from private.sha3_224.sha3_224 import sha3_224
from private.sha3_224.vectors import VECTORS


def starlark_sha3_224(data: bytes) -> str:
    # Bazel strings are byte strings wearing a Latin-1 disguise.
    return sha3_224(data.decode("latin-1"))


def reference(data: bytes) -> str:
    return hashlib.sha3_224(data).hexdigest()


@pytest.mark.parametrize(("message", "digest"), VECTORS)
def test_known_answers(message, digest):
    assert sha3_224(message) == digest


@pytest.mark.parametrize(("message", "digest"), VECTORS)
def test_known_answers_match_reference(message, digest):
    assert reference(message.encode("latin-1")) == digest


# Every length across the padding boundaries of the first three blocks.
@pytest.mark.parametrize("length", range(3 * 144 + 1))
def test_lengths(length):
    data = bytes(range(256)) * (length // 256 + 1)
    data = data[:length]
    assert starlark_sha3_224(data) == reference(data)


@given(st.binary(max_size=1024))
def test_binary(data):
    assert starlark_sha3_224(data) == reference(data)


@given(st.text())
def test_text(text):
    # What Bazel sees for a UTF-8 string literal.
    data = text.encode("utf-8")
    assert starlark_sha3_224(data) == reference(data)
