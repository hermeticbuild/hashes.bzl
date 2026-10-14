"""Tests of hashing UTF-8 text, as Bazel's interpreter and the harness see it."""

import json
import os

import pytest

from private.references import REFERENCES
from private.utf8 import cases


def reference_lines():
    # The harness reads cases.bzl as Latin-1, as Bazel does; undo that to get
    # the JSON text back, and let Python decode it independently of Bazel.
    lines = []
    for case in json.loads(cases.CASES_JSON.encode("latin-1").decode("utf-8")):
        message = b"a" * case.get("pad", 0) + case["text"].encode("utf-8", "surrogatepass") * case.get("repeat", 1)
        for algorithm in cases.ALGORITHMS:
            digest = REFERENCES[algorithm](message)
            lines.append("{} {} {} {}".format(case["name"], len(message), algorithm, digest))
    return lines


def test_bazel_digests():
    """What Bazel's interpreter computed and wrote while loading the package."""
    with open(os.environ["STARLARK_DIGESTS"], encoding="ascii") as f:
        assert f.read().splitlines() == reference_lines()


def test_harness_digests():
    assert cases.digest_lines() == reference_lines()


def test_raw_and_escaped_agree():
    decoded = dict(cases.utf8_cases())
    assert decoded["cjk-raw"] == decoded["cjk"]


@pytest.mark.parametrize(("name", "length"), [("first-2-byte", 2), ("first-3-byte", 3), ("emoji", 4)])
def test_escapes_decode_to_utf8_bytes(name, length):
    assert len(dict(cases.utf8_cases())[name]) == length


def test_covers_every_algorithm():
    assert sorted(cases.ALGORITHMS) == sorted(REFERENCES)


def test_cases_reach_bazel_through_escapes():
    # Every case but the -raw ones must spell non-ASCII text as JSON escapes,
    # or this stops testing how json.decode handles them. Tools that helpfully
    # unescape them would otherwise go unnoticed: the digests stay the same.
    escape = chr(92) + "u"
    for line in cases.CASES_JSON.splitlines():
        if '"name"' not in line or '-raw"' in line:
            continue
        assert line.isascii(), line
    assert cases.CASES_JSON.count(escape) >= 20
