"""Property tests of the Starlark sha1 against hashlib."""

import hashlib

import pytest
from hypothesis import given, strategies as st

from private.sha1.sha1 import sha1
from private.sha1.vectors import VECTORS


def starlark_sha1(data: bytes) -> str:
    # Bazel strings are byte strings wearing a Latin-1 disguise.
    return sha1(data.decode("latin-1"))


@pytest.mark.parametrize(("message", "digest"), VECTORS)
def test_known_answers(message, digest):
    assert sha1(message) == digest


# Every length across the padding boundaries of the first three blocks.
@pytest.mark.parametrize("length", range(3 * 64 + 1))
def test_lengths(length):
    data = bytes(range(length))
    assert starlark_sha1(data) == hashlib.sha1(data).hexdigest()


@given(st.binary(max_size=1024))
def test_binary(data):
    assert starlark_sha1(data) == hashlib.sha1(data).hexdigest()


@given(st.text())
def test_text(text):
    # What Bazel sees for a UTF-8 string literal.
    data = text.encode("utf-8")
    assert starlark_sha1(data) == hashlib.sha1(data).hexdigest()
