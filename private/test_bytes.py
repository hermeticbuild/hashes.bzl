"""Tests of the byte-string input contract shared by every hash."""

import pytest
from hypothesis import given, strategies as st

from bazel.python.starlark_finder import StarlarkFail
from private.bytes import to_bytes


@given(st.binary())
def test_bytes_round_trip(data):
    assert to_bytes(data.decode("latin-1")) == list(data)


@given(st.characters(min_codepoint=0x100))
def test_rejects_non_bytes(char):
    with pytest.raises(StarlarkFail, match="must be a byte string"):
        to_bytes("abc" + char)
