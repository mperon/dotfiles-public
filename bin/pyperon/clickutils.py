import click

import os


def expand_path(path):
    return os.path.abspath(os.path.expanduser(
        os.path.expandvars(path)))


def is_valid_file(path, expand=True):
    path = expand_path(path)
    return os.path.isfile(path) and is_readable(path)


def is_executable(path):
    return os.access(path, os.X_OK)


def is_readable(path):
    return os.access(path, os.R_OK)
