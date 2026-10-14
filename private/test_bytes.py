"""Tests of the byte-string input contract shared by every hash."""

import pytest
from hypothesis import given, strategies as st

from bazel.python.starlark_finder import StarlarkFail
from private.bytes import to_bytes
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
