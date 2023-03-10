#!/usr/bin/env python3
# vim: ts=4 sw=4 et ft=python

import argparse
import collections
import importlib.util
import pathlib
import re
import sys
import unicodedata
from pprint import pprint

from pyperon import argutils
from pyperon.utils import str_escape_split

VERSION = '0.0.9'

RULE_SEPARATOR = ('/', '|',)

_DEFAULT_IGNORE = ('__pycache__', '.git', '.hg', '.svn')


class NFContext(collections.UserDict):
    """Simple object for storing attributes.
    Implements equality by attribute names and values, and provides a simple
    string representation.
    """

    def __getattr__(self, name):
        return self.data.get(name, None)

    def __setattr__(self, name, value):
        if name == "data":
            self.__dict__[name] = value
        else:
            self.__dict__['data'][name] = value


class Aliases:
    _registry = dict()

    def __init_subclass__(cls):
        Aliases._registry.update(Aliases._get_fields(cls))

    @staticmethod
    def _get_fields(clazz):
        return {n: v for n, v in vars(clazz).items() if n[0] != '_' and not callable(v)}

    def get_aliases(self):
        return dict(self._registry)


class DefaultAliases(Aliases):
    strip_nonsense = ['r/(([0-9])\\s+-\\s+([0-9]))/\\g<2>\\g<3>/g']
    strip_spaces = ['r/\\s+/ /g', r'r/\\.$//g']
    only_ascii = ['u///g']
    strip_symbols = [
        's/(/[/g',
        's/)/]/g',
        'r/(\\.)\\1+/\\1/g',
        'r/(?<=\\d) +(?=\\d)/./g'
    ]
    strip_invalid = [
        's/`\',+=@!$%^<&>:"\\|?*//c'
    ]


# do something here
DEFAULT_RULES = (
    'only_ascii', 'strip_invalid',
    'strip_nonsense', 'strip_spaces',
    'strip_symbols',
)


class NFInput():

    def __init__(self, name, suffix=None):
        self._name = name
        self._suffix = suffix if suffix else ''
        self._orig_name = name
        self._orig_suffix = suffix

    @property
    def name(self):
        return self._name

    @name.setter
    def name(self, new_name):
        self._name = new_name

    @property
    def suffix(self):
        return self._suffix

    @suffix.setter
    def suffix(self, new_suffix):
        self._suffix = new_suffix

    @property
    def full_name(self):
        return self.name.strip() + self.suffix.strip()

    @property
    def original_name(self):
        return self.name.strip() + self.suffix.strip()

    def is_changed(self):
        return self._name != self._orig_name or self._suffix != self._orig_suffix

    def __str__(self):
        return f"{self._name}{self._suffix}"

    def __repr__(self):
        return f"{self.__class__.__name__}('{self._name}', '{self._suffix}')"


class NFText(NFInput):

    def __init__(self, name, suffix=None):
        super().__init__(name, suffix)


class NFFile(NFInput):

    def __init__(self, file_path):
        super().__init__(file_path.stem, file_path.suffix)
        self.file = file_path


class Rule:
    RULE_ID = None
    ACCEPTS = None
    _REPR = []
    _registry = set()

    def __init__(self, *args, **kwargs):
        pass

    def __repr__(self):
        _repr = self._REPR or []
        nm_class = self.__class__.__name__
        fields = [f + "= '" + getattr(self, f, '') + "'" for f in _repr]
        fields_str = ", ".join(fields)
        return f"{nm_class}({fields_str})"

    @staticmethod
    def register(cls):
        if issubclass(cls, Rule):
            Rule._registry.add(cls)
        return cls

    @staticmethod
    def get_registered_types():
        return set(Rule._registry)

    def accepts(self, input_instance):
        accepts = self.ACCEPTS
        # if accepts is not none, process
        if accepts:
            if not isinstance(self.ACCEPTS, (tuple, list)):
                accepts = (self.ACCEPTS,)
            for input_clz in accepts:
                if not issubclass(input_clz, NFInput):
                    raise ValueError(
                        f"Class {self.__class__.__name__} attribute ACCEPTS must be a subclass of NFInput")
                else:
                    if isinstance(input_instance, input_clz):
                        return True
            return False
        # if accepts is None, allow all types
        return True


class SearchReplaceRule(Rule):
    RULE_ID = None
    _REPR = ["search", "replace", "mods"]
    COUNT_RANGE = ('1', '2', '3', '4', '5', '6', '7', '8', '9')

    def __init__(self, search, replace="", mods=None, *args, **kwargs):
        super().__init__(*args, **kwargs)
        if not search:
            raise ValueError(f"The rule need an search value.")
        self.search = search
        self.replace = replace if replace else ""
        self.flags = 0
        self.count = None
        self.mods = mods if mods else "g"  # just ignoreit. is not required
        self._init(*args)

    def _init(self, *args):
        pass


@Rule.register
class RegExRule(SearchReplaceRule):
    RULE_ID = 'r'
    RE_FLAGS = {
        'i': re.IGNORECASE,
        's': re.DOTALL,
        'm': re.MULTILINE,
        'x': re.VERBOSE
    }

    def _init(self, *args):
        # define flags
        self.count = 0
        for f in self.mods:
            if f in self.RE_FLAGS:
                self.flags = self.flags | self.RE_FLAGS[f]
            elif f == "g":
                self.count = 0
            elif f in self.COUNT_RANGE:
                self.count = int(f)
        self.regex = re.compile(self.search, self.flags)

    def process(self, fobj):
        fobj.name = self.regex.sub(self.replace, fobj.name, self.count)


@Rule.register
class StrReplaceRule(SearchReplaceRule):
    RULE_ID = 's'

    def _init(self, *args):
        self.by_char = False
        self.count = -1
        # Process modifiers
        for f in self.mods:
            if f == "g":
                self.count = -1
            if f == "c":
                self.by_char = True
            elif f in self.COUNT_RANGE:
                self.count = int(f)

    def process(self, fobj):
        if self.by_char:
            for c in self.search:
                fobj.name = fobj.name.replace(c, self.replace, self.count)
        else:
            fobj.name = fobj.name.replace(
                self.search, self.replace, self.count)


@Rule.register
class UnicodeNormRule(Rule):
    RULE_ID = 'u'
    _REPR = ["form", "encoding", "mods"]

    def __init__(self, form, encoding, mods=None, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.form = form if form else "NFKD"
        self.encoding = encoding if encoding else "ascii"
        self.mods = mods if mods else "g"

    def process(self, fobj):
        normalized = unicodedata.normalize(
            'NFKD', fobj.name).encode('ascii', 'ignore')
        fobj.name = normalized.decode('ascii')


@Rule.register
class TextTransformRule(Rule):
    RULE_ID = 't'
    _REPR = ["action", "options", "mods"]
    VALID_ACTIONS = {
        "capitalize": str.capitalize,
        "casefold": str.casefold,
        "lower": str.lower,
        "lstrip": str.lstrip,
        "rstrip": str.rstrip,
        "strip": str.strip,
        "swapcase": str.swapcase,
        "title": str.title,
        "upper": str.upper
    }

    def __init__(self, action, options="", *args, **kwargs):
        super().__init__(*args, **kwargs)
        if not action:
            raise ValueError(f"The rule need an action value.")
        self.action = action
        self.options = options if options else "eg"

    def process(self, fobj):
        if 'e' in self.options:
            fobj.suffix = self._do_action(fobj.suffix)
        if 'g' in self.options:
            fobj.name = self._do_action(fobj.name)

    def _do_action(self, part):
        action = str(self.action).lower().strip()
        if action in self.VALID_ACTIONS:
            return self.VALID_ACTIONS[action](part)
        else:
            raise ValueError(f"Action {action} is not an valid action")


class NFProcessor():

    def __init__(self, context):
        self.ctx = context
        self.rules_types = {}
        self.rules_alias = {}
        self.rules = []
        self._load_rules_types()
        self.rules_alias.update(Aliases().get_aliases())
        self.rules_alias.update(self.ctx.get('rules_alias', {}))
        # add all rules
        self.add_rule(self.ctx.get('rules_list', []))

    def _load_rules_types(self):
        extra_types = self.ctx.get('extra_types', ())
        if not isinstance(extra_types, (tuple, list)):
            raise ValueError('Extra rules types must be an tuple or list')
        all_types = Rule.get_registered_types().union(set(extra_types))
        for r_clz in all_types:
            rid = getattr(r_clz, 'RULE_ID', None)
            if rid:
                if isinstance(rid, (tuple, list)):
                    self.rules_types.update({x: r_clz for x in rid})
                else:
                    self.rules_types[str(rid)] = r_clz

    def add_rule(self, rule):
        if isinstance(rule, str):
            # check if rule is a named rule/group
            if rule.lower() in self.rules_alias:
                return self.add_rule(self.rules_alias[rule.lower()])
            else:
                # its a string rule. parses it
                newrule = self._parse_rule(rule)
                if newrule:
                    self.rules.append(newrule)
                else:
                    return False
        elif isinstance(rule, Rule):
            self.rules.append(rule)
        elif isinstance(rule, (tuple, list)):
            for r in rule:
                self.add_rule(r)
        else:
            raise ValueError(f'Unsupported rule type: {rule}')
        return True

    def process(self):
        pass

    def process_object(self, target):
        if isinstance(target, NFInput):
            fobj = target
        elif isinstance(target, pathlib.PurePath):
            fobj = NFFile(target)
        elif isinstance(target, (tuple, list)):
            fobj = NFText(target[0], target[1] if len(target) > 1 else None)
        elif isinstance(target, str):
            fobj = NFText(target)
        else:
            raise ValueError("Cannot process this variable type!")
        # process stuff
        for rule in self.rules:
            if rule.accepts(fobj):
                rule.process(fobj)

        return fobj

    def _parse_rule(self, rule_string):
        rtype = rule_string[0]
        rclass = self.rules_types.get(rtype, None)
        # type is invalid
        if rclass is None:
            raise ValueError(f"{rtype} is an invalid type rule.")
        # split using delimiters
        rdelimiter = rule_string[1]
        parts = str_escape_split(rule_string[2:], rdelimiter)
        pp = list(parts)
        try:
            ret = rclass(*pp)
        except TypeError as e:
            raise ValueError(f"Invalid rule: '{rule_string}'") from e
        except ValueError as e:
            raise ValueError(
                f"'{rule_string}': Invalid: {e}") from e
        return ret


class FileTreeProcessor(NFProcessor):

    def __init__(self, context, *args, **kwargs):
        super().__init__(context, *args, **kwargs)

    def _is_ignored(self, path):
        # check excludes
        patterns = self.ctx.exclude_list or []
        return any(map(path.match, patterns))

    def process_tree(self, start):
        for path in pathlib.Path(start).glob('*'):
            if self._is_ignored(path):
                continue
            if path.is_dir() and not self.ctx['shallow']:
                # first run files from this particular folder
                self.process_tree(path)
            # now process
            if path.is_dir() and self.ctx['ignore_dirs']:
                continue
            if path.is_file() and self.ctx['ignore_files']:
                continue
            self.process_item(path)

    def process_item(self, path):
        fobj = self.process_object(path)
        if fobj.is_changed():
            if self.ctx['rename']:
                print(f"Renaming: {path} to {fobj.full_name}.")
                path.rename(fobj.full_name)
            else:
                print(
                    f"Rename: {fobj.original_name} to {fobj.full_name}. Run with --rename")

    def process(self):
        for f in self.ctx['FILE']:
            self.process_tree(pathlib.Path(f))


def load_plugins(ctx):
    ctx.plugins = {}
    for path in pathlib.Path(ctx.config_dir).glob('*.py'):
        if not path.stem in ctx.plugins:
            # loads
            ret = import_pyfile(path, parent_module='pyperon.namefix.plugins')
            ctx.plugins[path.stem] = ret


def load_config(ctx):
    pass


def import_pyfile(pyfile, module_name=None, parent_module=None):
    pyf = pathlib.Path(pyfile)
    if parent_module is None:
        parent_module = ''
    if module_name is None:
        module_name = pyf.stem
    full_module = join_safe('.', parent_module, module_name)
    spec = importlib.util.spec_from_file_location(full_module, str(pyf))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def join_safe(glue, *args):
    return str(glue).join([a for a in args if a])


def parse_arguments():
    parser = argparse.ArgumentParser(
        prog='namefix',
        description='Rename files the way must be')
    parser.add_argument('-C',
                        '--no-default-rules',
                        action='store_true',
                        default=False,
                        help='Disable built-in rules to normalize file names')
    parser.add_argument('-N',
                        '--no-default-excludes',
                        action='store_true',
                        default=False,
                        help='Disable built-in excluded files and folders')
    parser.add_argument('-S',
                        '--shallow',
                        action='store_true',
                        default=False,
                        help='Process files only in first folder (no recurse)')
    parser.add_argument('--version',
                        action='version',
                        version='%(prog)s '+VERSION)
    # ignores files or directories
    parser.add_argument('-X',
                        '--rename',
                        action='store_true',
                        default=False,
                        help='Renames all files. If not set, just print will occur')
    # ignores files or directories
    ignore = parser.add_mutually_exclusive_group(required=False)
    ignore.add_argument('-D',
                        '--ignore-dirs',
                        action='store_true',
                        default=False,
                        help='Ignore renaming directories')
    ignore.add_argument('-A',
                        '--ignore-files',
                        action='store_true',
                        default=False,
                        help='Ignore renaming files')
    # define ignored directories
    parser.add_argument('-e', '--exclude',
                        metavar='PATTERN',
                        nargs='?',
                        action="append",
                        help='An Path pattern to exclude from action')
    # add rules and files
    parser.add_argument('-r', '--rule',
                        metavar='RULE',
                        nargs='?',
                        action="append",
                        help='An string rule')
    parser.add_argument('FILE',
                        nargs='+',
                        type=argutils.path_exists,
                        help='An directory or file to process.')
    # process and return
    config = NFContext(vars(parser.parse_args()))
    # define plugin dir
    if not config.config_dir:
        config.config_dir = pathlib.Path.home() / '.config' / 'namefix'

    # define config file
    if not config.config_file:
        config.config_file = pathlib.Path(config.config_dir) / 'namefix.conf'
    # load plugins
    load_plugins(config)

    # load configs
    load_config(config)

    config.rules_list = []
    config.exclude_list = []
    # configuring rules
    if not config.no_default_rules:
        config.rules_list.extend(DEFAULT_RULES)
    config.rules_list.extend(config.rule or [])
    # if nas no rules, trow error
    if not config.rules_list:
        parser.error(
            'you disabled default rules and not added individual rules.')

    # ignore stuff
    if not config.no_default_excludes:
        config.exclude_list.extend(_DEFAULT_IGNORE)
    config.exclude_list.extend(config.exclude or [])
    # return config
    return config


def main():
    config = parse_arguments()
    processor = FileTreeProcessor(context=config)
    processor.process()


if __name__ == "__main__":
    main()
