"""A pytest entrypoint for `py_venv_test`.

Runs pytest over exactly the files given as arguments, without letting it
write caches into the runfiles tree, and reports results to Bazel.
"""

import os
import sys

import pytest


class BazelPlugin:
    def pytest_configure(self, config):
        # Deferred to here so pytest can assertion-rewrite hypothesis's plugin.
        try:
            from hypothesis import settings
        except ImportError:
            return

        # A Bazel test result should be a function of its inputs, so draw the
        # same examples every run rather than flaking on a lucky one. Don't keep
        # an example database in the runfiles tree, and don't fail slow
        # examples: timing under Bazel is noisy.
        settings.register_profile(
            "bazel",
            database=None,
            deadline=None,
            derandomize=True,
            print_blob=True,
        )
        settings.load_profile("bazel")


def main(argv):
    args = [
        "-p", "no:cacheprovider",
        "--import-mode=importlib",
    ]

    if xml_output := os.environ.get("XML_OUTPUT_FILE"):
        args.append("--junitxml=" + xml_output)

    # Honor `bazel test --test_filter=...` as a pytest -k expression.
    if test_filter := os.environ.get("TESTBRIDGE_TEST_ONLY"):
        args.extend(["-k", test_filter])

    return pytest.main(args + argv, plugins=[BazelPlugin()])


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
