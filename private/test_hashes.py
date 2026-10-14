"""Tests of the public `hashes` struct against reference implementations."""

import pytest
from hypothesis import given, strategies as st

from hashes import hashes
from private.references import REFERENCES


def test_exports_exactly_the_references():
    assert sorted(vars(hashes)) == sorted(REFERENCES)


@pytest.mark.parametrize("name", sorted(REFERENCES))
@given(data=st.binary(max_size=256))
def test_matches_reference(name, data):
    digest = getattr(hashes, name)(data.decode("latin-1"))
    assert digest == REFERENCES[name](data)
