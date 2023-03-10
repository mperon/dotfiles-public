import locale
import shlex
import subprocess

from collections import UserList

class Output(UserList):

    def __init__(self, alist, exit_code=0):
        super().__init__(alist)
        self._exit_code = exit_code

    @property
    def exit_code(self):
        return self._exit_code

    def is_error(self):
        return self._exit_code != 0

    def lines(self):
        return len(self)

    def get(self, index, default=None):
        try:
            ret = self[index]
        except IndexError:
            ret = default
        return ret

    def is_empty(self):
        return len(self) == 0

    def contains(self, *filters, action=all):
        return not self.filter_by(*filters, action=action).is_empty()

    def filter_by(self, *filters, action=all, check=None):
        def _check(f, value):
            if hasattr(f, 'match'): #is regex
                return f.search(value)
            elif hasattr(f, 'strip'): #is string
                return f in value
            else:
                return f == value

        def _apply(el):
            return action(map(lambda f: check(f, el), filters))

        if check is None:
            check = _check
        return Output(filter(_apply, self.data))

    def print(self, *args, **kwargs):
        for line in self.data:
            print(line, *args, **kwargs)


def run(args, **kwargs):
    args = _prepare(args)
    ret = subprocess.run(args, **kwargs)
    return ret.returncode


def output(args, as_bytes=False, as_list=True, **kwargs):
    args = _prepare(args)
    options = dict(stderr=subprocess.STDOUT)
    options.update(**kwargs)
    exit_code = 0
    try:
        data = subprocess.check_output(args, **options)
    except subprocess.CalledProcessError as grepexc:
        data = grepexc.output
        exit_code = grepexc.returncode
    return _process_data(data, as_bytes=as_bytes, as_list=as_list, exit_code=exit_code)


def _prepare(args):
    if isinstance(args, str):
        args = shlex.split(args)
    return args


def _process_data(data, as_bytes=False, as_list=True, exit_code=0, **kwargs):
    if as_bytes:
        return data
    encoding = kwargs.get('encoding', locale.getpreferredencoding(do_setlocale=True))
    data = data.decode(encoding)
    if as_list:
        return Output(data.rstrip().split('\n'), exit_code=exit_code)
