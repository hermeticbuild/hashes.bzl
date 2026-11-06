"""Bazel-side tests of Starlark code, complementing starlark_pytest.

starlark_pytest evaluates .bzl files as Python, which accepts things Bazel
won't. These run the same code under Bazel's own interpreter.
"""

load("@bazel_skylib//rules:diff_test.bzl", "diff_test")
load("@bazel_skylib//rules:write_file.bzl", "write_file")

def _describe(message):
    # type: (str) -> str
    if len(message) > 32:
        message = message[:32] + "..."
    return repr(message)

def hash_kat_test(
        # type: str
        name,
        # type: Callable[[str], str]
        hash,
        # type: Collection[tuple[str, str]]
        vectors,
        # TODO(https://github.com/bazelbuild/bazel/issues/32343): Use a Bazel
        # annotation when it can express diff_test's remaining keywords.
        # type: Unpack[KeywordArgs[diff_test, "name", "file1", "file2"]]
        **kwargs):
    # type: (...) -> None
    """Checks `hash(message) == digest` for each `(message, digest)` in `vectors`.

    The hash runs while this macro is evaluated, so a Starlark error in it
    fails the build outright; a wrong digest fails the test with a diff.

    Args:
        name: Name of the test target.
        hash: The hash function under test.
        vectors: A list of (message, hex digest) pairs.
        **kwargs: Passed through to diff_test.
    """

    write_file(
        name = name + "_expected",
        out = name + ".expected.txt",
        content = ["{} {}".format(digest, _describe(message)) for message, digest in vectors] + [""],
    )
    write_file(
        name = name + "_actual",
        out = name + ".actual.txt",
        content = ["{} {}".format(hash(message), _describe(message)) for message, _ in vectors] + [""],
    )
    diff_test(
        name = name,
        file1 = name + "_expected",
        file2 = name + "_actual",
        **kwargs
    )
