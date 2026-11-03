"""Python test macros wrapping aspect_rules_py."""

load("@aspect_rules_py//py/unstable:defs.bzl", "py_venv_test")

def py_pytest(
        # type: str
        name,
        # type: list[str | Label]
        srcs,
        # type: Collection[str | Label]
        deps = [],
        # type: list[str]
        args = [],
        # type: object
        **kwargs):
    # type: (...) -> None
    """A py_venv_test which runs `srcs` with pytest.

    Args:
        name: Name of the test target.
        srcs: Test files; pytest runs exactly these.
        deps: Additional Python dependencies.
        args: Additional arguments to pytest.
        **kwargs: Passed through to py_venv_test.
    """
    shim = Label("//bazel/python:pytest_shim.py")

    py_venv_test(
        name = name,
        srcs = [shim] + srcs,
        main = shim,
        args = args + ["$(rootpath {})".format(src) for src in srcs],
        deps = depset([Label("@pypi//pytest")] + [native.package_relative_label(dep) for dep in deps]).to_list(),
        **kwargs
    )

def starlark_pytest(
        # type: str
        name,
        # type: list[str | Label]
        srcs,
        # type: list[str | Label]
        bzl_srcs,
        # type: list[str | Label]
        deps = [],
        # type: list[str]
        args = [],
        *,
        # type: list[str | Label]
        data = [],
        # type: object
        **kwargs):
    # type: (...) -> None
    """A pytest test of Starlark code, imported as Python by starlark_finder.

    Test files import `.bzl` files as modules named for their path, e.g.
    `from private.sha1.sha1 import sha1` for `//private/sha1:sha1.bzl`.

    Args:
        name: Name of the test target.
        srcs: Test files.
        bzl_srcs: `.bzl` files under test, and any they `load()` from this repository.
        deps: Additional Python dependencies.
        args: Additional arguments to pytest.
        data: Additional runtime files for the test.
        **kwargs: Passed through to py_venv_test.
    """
    py_pytest(
        name = name,
        srcs = srcs,
        args = ["-p", "bazel.python.starlark_finder"] + args,
        data = bzl_srcs + data,
        deps = [
            Label("//bazel/python:starlark_finder"),
            Label("@pypi//hypothesis"),
        ] + deps,
        **kwargs
    )
