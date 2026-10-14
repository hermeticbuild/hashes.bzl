"""Property tests of the Starlark crc32 against zlib."""

import zlib

import pytest
from hypothesis import given, strategies as st

from private.crc32.crc32 import crc32
from private.crc32.vectors import VECTORS


def starlark_crc32(data: bytes) -> str:
    # Bazel strings are byte strings wearing a Latin-1 disguise.
    return crc32(data.decode("latin-1"))


def reference(data: bytes) -> str:
    return "%08x" % zlib.crc32(data)


@pytest.mark.parametrize(("message", "digest"), VECTORS)
def test_known_answers(message, digest):
    assert crc32(message) == digest


@pytest.mark.parametrize(("message", "digest"), VECTORS)
def test_known_answers_match_reference(message, digest):
    assert reference(message.encode("latin-1")) == digest


# CRC-32 has no blocks; cover every length up to a few 32-bit words, and every
# byte value.
@pytest.mark.parametrize("length", range(4 * 4 + 1))
def test_lengths(length):
    data = bytes(range(256)) * (length // 256 + 1)
    data = data[:length]
    assert starlark_crc32(data) == reference(data)


@pytest.mark.parametrize("byte", range(256))
def test_single_bytes(byte):
    data = bytes([byte])
    assert starlark_crc32(data) == reference(data)


@given(st.binary(max_size=1024))
def test_binary(data):
    assert starlark_crc32(data) == reference(data)


@given(st.text())
def test_text(text):
    # What Bazel sees for a UTF-8 string literal.
    data = text.encode("utf-8")
    assert starlark_crc32(data) == reference(data)
