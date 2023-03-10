#!/usr/bin/python3
# vim: ts=4 sw=4 et
import argparse
import os
from urllib.parse import urlparse


def expand_path(path):
    return os.path.abspath(os.path.expanduser(
        os.path.expandvars(path)))


def is_dir(dirname):
    dirname = expand_path(dirname)
    """Checks if a path is an actual directory"""
    if not os.path.isdir(dirname):
        msg = "{0} is not a directory".format(dirname)
        raise argparse.ArgumentTypeError(msg)
    else:
        return dirname


def can_create_dir(path):
    parts = os.path.split(path)
    if os.path.exists(parts[0]):
        return True
    else:
        if not parts[1] == '':
            return can_create_dir(parts[0])
        else:
            return False


def is_searchable_file(path):
    path = expand_path(path)
    if os.path.isfile(path) and is_readable(path):
        return path
    raise argparse.ArgumentTypeError(
        "Config file {0} doesnt exists!".format(path))


def path_exists(path):
    path = expand_path(path)
    if os.path.exists(path):
        return path
    raise argparse.ArgumentTypeError(
        "{0} is not a valid file/dir!".format(path))


def is_valid_file(path):
    path = expand_path(path)
    if os.path.isfile(path) and is_readable(path):
        return path
    raise argparse.ArgumentTypeError(
        "Config file {0} doesnt exists!".format(path))


def is_valid_dir(path):
    path = expand_path(path)
    if is_dir(path):
        return path
    else:
        # is not a directory, verify file
        if not os.path.exists(path):
            # path dont exist, check if can be create
            if can_create_dir(path):
                return path
    raise argparse.ArgumentTypeError(
        "{0} is not a valid directory path".format(path))


def is_url(url):
    try:
        result = urlparse(url)
        if all([result.scheme, result.netloc]):
            return url
    except ValueError:
        pass
    raise argparse.ArgumentTypeError("{0} is not a valid url".format(url))


def is_executable(path):
    return os.access(path, os.X_OK)


def is_readable(path):
    return os.access(path, os.R_OK)


class FullPaths(argparse.Action):
    """Expand user- and relative-paths"""

    def __call__(self, parser, namespace, values, option_string=None):
        setattr(namespace, self.dest, os.path.abspath(
            os.path.expanduser(values)))


class FileFinder:
    COMMENTS = ('#', ";", "//")

    def __init__(self, fname):
        self.fname = fname
        self._load_paths()

    def _load_paths(self):
        paths = []
        self.fname = expand_path(self.fname)
        if os.path.isfile(self.fname) and is_readable(self.fname):
            with open(self.fname) as fp:
                for line in fp:
                    if line.strip() == "":
                        continue
                    elif any(map(lambda x: line.strip().startswith(x), FileFinder.COMMENTS)):
                        continue  # is a comment, ignore line
                    else:
                        path = os.path.abspath(os.path.expanduser(
                            os.path.expandvars(line.strip())))
                        if os.path.isdir(path):
                            paths.append(path)
        self.paths = tuple(paths)

    def file_exists(self, path):
        return self.get_file_path(path) is not False

    def get_file_path(self, path):
        if os.path.isabs(path):
            if os.path.isfile(path) and is_readable(path):
                return path
        for path_prefix in self.paths:
            fullpath = os.path.join(path_prefix, path)
            if os.path.isfile(fullpath) and is_readable(fullpath):
                return fullpath
        return False


class ExtendAction(argparse.Action):
    def __init__(self,
                 option_strings,
                 dest,
                 nargs=None,
                 const=None,
                 default=None,
                 type=None,
                 choices=None,
                 required=False,
                 help=None,
                 metavar=None,
                 separator=None,
                 unique=True):
        self.separator = separator
        self.unique = unique
        super(ExtendAction, self).__init__(
            option_strings=option_strings,
            dest=dest,
            nargs=nargs,
            const=const,
            default=default,
            type=type,
            choices=choices,
            required=required,
            help=help,
            metavar=metavar)

    def __call__(self, parser, namespace, values, option_string=None):
        actual = getattr(namespace, self.dest, self.default)
        if values and actual is self.default:
            items = []
        else:
            items = actual
        items = self._copy_items(items)
        items.extend(values.split(self.separator))
        if self.unique:
            items = list(set(items))
        setattr(namespace, self.dest, items)

    def _copy_items(self, items):
        if items is None:
            return []
        # The copy module is used only in the 'append' and 'append_const'
        # actions, and it is needed only when the default value isn't a list.
        # Delay its import for speeding up the common case.
        if type(items) is list:
            return items[:]
        import copy
        return copy.copy(items)
