#!/bin/env python3

import random
import re
import sys
from pathlib import Path

FILTERS = (
    'These records are provided',
    'Download results of your legal',
    'Service',
    'Account Identifier',
    'Account Type',
    'Generated',
    'Date Range',
    'Message Log'
)

data = {}


def main():
    if len(sys.argv) <= 1:
        print('Erro! Informe o arquivo!')
        exit(1)

    file_in = Path(sys.argv[1])
    if not file_in.exists():
        print(f"Arquivo/diretório {file_in} doesnt exists!!")
        exit(1)

    process_dir(file_in)


def process_dir(file_in):
    if file_in.is_dir():
        for f_input in file_in.rglob("*.html"):
            if f_input.is_dir():
                process_dir(f_input)
            else:
                process(f_input)
    else:
        process(file_in)


def process(file_in):
    file_out = file_in.with_suffix('.out.html')
    write_to(scramble(filter_prefixes(read_from(file_in), FILTERS, 11)), file_out)
    if file_out.exists():
        file_in.unlink()
        file_out.rename(file_in)


def filter_prefixes(lines, filters, ignore_lines=0):
    for line_no, line in enumerate(lines):
        if line_no <= ignore_lines:
            yield line
        else:
            if not line.startswith(filters):
                yield line


def read_from(filename):
    with Path(filename).open('r') as fp:
        for line in fp:
            yield line.rstrip()


def write_to(lines, filename):
    with Path(filename).open('w') as fp:
        for line in lines:
            fp.write(line.rstrip() + '\n')


def scramble(lines):
    for line in lines:
        numbers = re.findall("[0-9]{8,}", line)
        for number in numbers:
            new_num = data.get(number, random_num(number))
            data[number] = new_num
            line = line.replace(number, new_num)
        yield line


def random_num(current):
    rnd = random.randrange(0000, 9999)
    rnd_str = "{:04}".format(rnd)
    new = current[:-4] + rnd_str
    return new


if __name__ == '__main__':
    main()