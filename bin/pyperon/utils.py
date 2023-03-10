#!/usr/bin/env python3
# vim: ts=4 sw=4 et

def str_escape_split(str_to_escape, delimiter=',', escape='\\'):
    """Splits an string using delimiter and escape chars

    Args:
        str_to_escape ([type]): The text to be splitted
        delimiter (str, optional): Delimiter used. Defaults to ','.
        escape (str, optional): The escape char. Defaults to '\'.

    Yields:
        [type]: a list of string to be escaped
    """
    if len(delimiter) > 1 or len(escape) > 1:
        raise ValueError(
            "Either delimiter or escape must be an one char value")
    token = ''
    escaped = False
    for c in str_to_escape:
        if c == escape:
            if escaped:
                token += escape
                escaped = False
            else:
                escaped = True
            continue
        if c == delimiter:
            if not escaped:
                yield token
                token = ''
            else:
                token += c
                escaped = False
        else:
            if escaped:
                token += escape
                escaped = False
            token += c
    yield token
