#!/usr/bin/python3
# vim: ts=4 sw=4 et
import sys


class Terminal:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'
    ITALIC = '\033[3m'

    output = sys.stdout

    def __init__(self, output=None):
        if output:
            self.output = output

    def __put(self, text, line=None):
        self.output.write(text)
        if line:
            self.output.write(line)

    def print(self, text):
        self.__put(text)

    def color(self, color, text=None):
        self.__put(color, text)
        return self

    def blue(self, text=None):
        self.__put(self.OKBLUE, text)
        return self

    def green(self, text=None):
        self.__put(self.OKGREEN, text)
        return self

    def warn(self, text=None):
        self.__put(self.WARNING, text)
        return self

    def fail(self, text=None):
        self.__put(self.FAIL, text)
        return self

    def end(self, text=None):
        return self.newline(text)

    def newline(self, text=None):
        add = ""
        if text:
            add = text
        return self.default(add + '\n')

    def default(self, text=None):
        self.__put(self.ENDC, text)
        return self

    def header(self, text=None):
        self.__put(self.HEADER, text)
        return self

    def bold(self, text=None):
        self.__put(self.BOLD, text)
        return self

    def underline(self, text=None):
        self.__put(self.UNDERLINE, text)
        return self

    def italic(self, text=None):
        self.__put(self.ITALIC, text)
        return self


class NoColor(Terminal):
    HEADER = ''
    OKBLUE = ''
    OKGREEN = ''
    WARNING = ''
    FAIL = ''
    ENDC = ''
    BOLD = ''
    UNDERLINE = ''
    ITALIC = ''
