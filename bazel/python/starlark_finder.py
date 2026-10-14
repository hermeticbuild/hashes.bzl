"""Import Starlark `.bzl` files as if they were Python modules.

Starlark is very nearly a syntactic subset of Python, so most `.bzl` files will
parse and evaluate as Python given a little help. Once `install()`-ed, this
finder lets tests write

    from private.sha1.sha1 import sha1

and get the function defined in `private/sha1/sha1.bzl`.

The help consists of:

- A per-module `load()` builtin. Labels in this repository (`//pkg:file.bzl`,
  `:file.bzl`) are imported recursively through this same finder. Labels in
  other repositories are satisfied from `EXTERNAL_SYMBOLS`, a table of Python
  shims mimicking the Starlark originals.

- The Starlark builtins Python lacks (`fail`, `struct`).

- An AST rewrite of Starlark-only methods, which can't be monkeypatched onto
  Python's `str`. `s.elems()` becomes `__starlark_elems__(s)`.

This is a test harness, not a Starlark interpreter. It will happily run code
Bazel would reject (`while`, recursion, mutating frozen values, ...), so every
`.bzl` tested this way should also have a known-answer test run by Bazel.
"""

import ast
import builtins
import importlib
import importlib.abc
import importlib.util
import os
import sys
import types


class StarlarkFail(Exception):
    """Raised by the `fail()` builtin."""


def _fail(*args, sep=" ", attr=None):
    msg = sep.join(str(arg) for arg in args)
    if attr is not None:
        msg = "attribute {}: {}".format(attr, msg)
    raise StarlarkFail(msg)


def _struct(**kwargs):
    return types.SimpleNamespace(**kwargs)


def _elems(s):
    return list(s)


# Starlark methods with no Python equivalent, rewritten to calls of these.
_METHODS = {
    "elems": _elems,
}

_BUILTINS = {
    "fail": _fail,
    "struct": _struct,
} | {"__starlark_{}__".format(name): fn for name, fn in _METHODS.items()}


def _bazel_lib_ord(c):
    # @bazel_lib's ord() is a lookup in a 256-entry table, so anything outside
    # Latin-1 comes back None rather than as a codepoint.
    if len(c) != 1:
        _fail("expected a string with a single character")
    n = ord(c)
    return n if n < 256 else None


# Symbols exported by .bzl files in other repositories, keyed by load() label.
EXTERNAL_SYMBOLS = {
    "@bazel_lib//lib:strings.bzl": {
        "ord": _bazel_lib_ord,
    },
}


def _module_for_label(label, loading_module):
    """Map a label in this repository to a Python module name."""

    if label.startswith(":"):
        package = loading_module.rpartition(".")[0].replace(".", "/")
        target = label[1:]
    elif label.startswith("//"):
        package, _, target = label[2:].partition(":")
        if not target:
            target = package.rpartition("/")[2]
    else:
        _fail("cannot load {!r}: not a label in this repository".format(label))

    path = "/".join([p for p in [package, target] if p])
    if not path.endswith(".bzl"):
        _fail("cannot load {!r}: not a .bzl file".format(label))
    return path[: -len(".bzl")].replace("/", ".")


def _make_load(namespace):
    def load(label, *symbols, **aliases):
        if label.startswith("@") and not label.startswith("@//"):
            if label not in EXTERNAL_SYMBOLS:
                _fail("cannot load {!r}: no shim in EXTERNAL_SYMBOLS".format(label))
            exports = EXTERNAL_SYMBOLS[label]
        else:
            module_name = _module_for_label(label.removeprefix("@"), namespace["__name__"])
            exports = vars(importlib.import_module(module_name))

        for local, name in [(s, s) for s in symbols] + list(aliases.items()):
            if name.startswith("_"):
                _fail("cannot load private symbol {!r} from {!r}".format(name, label))
            if name not in exports:
                _fail("{!r} does not export {!r}".format(label, name))
            namespace[local] = exports[name]

    return load


class _StarlarkTransformer(ast.NodeTransformer):
    def visit_Call(self, node):
        self.generic_visit(node)
        func = node.func
        if isinstance(func, ast.Attribute) and func.attr in _METHODS:
            return ast.copy_location(
                ast.Call(
                    func=ast.Name(id="__starlark_{}__".format(func.attr), ctx=ast.Load()),
                    args=[func.value] + node.args,
                    keywords=node.keywords,
                ),
                node,
            )
        return node


class BzlLoader(importlib.abc.Loader):
    def __init__(self, path):
        self.path = path

    def exec_module(self, module):
        # Bazel reads .bzl files as Latin-1; so do we.
        with open(self.path, encoding="latin-1") as f:
            source = f.read()
        tree = _StarlarkTransformer().visit(ast.parse(source, self.path))
        code = compile(ast.fix_missing_locations(tree), self.path, "exec")

        # Starlark builtins go in the module's __builtins__ rather than its
        # globals, so that they aren't mistaken for symbols the module exports.
        namespace = vars(module)
        namespace["__builtins__"] = vars(builtins) | _BUILTINS | {"load": _make_load(namespace)}
        exec(code, namespace)


class BzlFinder(importlib.abc.MetaPathFinder):
    """Resolves module `a.b.c` to the first `a/b/c.bzl` on the import path."""

    def find_spec(self, fullname, path, target=None):
        stem = fullname.rpartition(".")[2]
        for entry in sys.path if path is None else path:
            candidate = os.path.join(entry or ".", stem + ".bzl")
            if os.path.isfile(candidate):
                return importlib.util.spec_from_file_location(
                    fullname, candidate, loader=BzlLoader(candidate)
                )
        return None


def install():
    """Install the finder, after the standard ones so real .py files win."""

    if not any(isinstance(f, BzlFinder) for f in sys.meta_path):
        sys.meta_path.append(BzlFinder())


def pytest_configure(config):
    """Lets this module double as a pytest plugin: `-p bazel.python.starlark_finder`."""

    install()
