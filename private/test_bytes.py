"""Tests of the byte-string input contract shared by every hash."""

import pytest
from hypothesis import given, strategies as st

from bazel.python.starlark_finder import StarlarkFail
from private.bytes import md_pad, to_bytes, words64_be
from private.ord import ord as ord_bzl


@given(st.binary())
def test_bytes_round_trip(data):
    assert to_bytes(data.decode("latin-1")) == list(data)


@given(st.characters(min_codepoint=0x100))
def test_rejects_non_bytes(char):
    with pytest.raises(StarlarkFail, match="must be a byte string"):
        to_bytes("abc" + char)


def test_ord_covers_every_byte():
    assert [ord_bzl(chr(i)) for i in range(256)] == list(range(256))


@given(st.characters(min_codepoint=0x100))
def test_ord_rejects_non_bytes(char):
    assert ord_bzl(char) is None


def test_ord_rejects_strings():
    with pytest.raises(StarlarkFail, match="single character"):
        ord_bzl("ab")


@given(st.binary(max_size=300), st.sampled_from([64, 128]), st.booleans())
def test_md_pad(data, block_size, big_endian):
    padded = md_pad(list(data), big_endian, block_size)
    length_size = block_size // 8
    length = (len(data) * 8).to_bytes(length_size, "big" if big_endian else "little")
    assert len(padded) % block_size == 0
    assert padded[: len(data) + 1] == list(data) + [0x80]
    assert padded[-length_size:] == list(length)
    assert set(padded[len(data) + 1 : -length_size]) <= {0}
    # Minimal: the padding never spills into a block it didn't need.
    assert len(padded) - len(data) <= block_size + length_size


@given(st.binary(min_size=8, max_size=64).map(lambda b: b[: len(b) // 8 * 8]))
def test_words64_be(data):
    assert words64_be(list(data)) == [int.from_bytes(data[i : i + 8], "big") for i in range(0, len(data), 8)]
