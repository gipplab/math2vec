import re


def print_symbols_in_goldi(data):
    symbols = set()

    regex = r'[A-Za-z]'
    pattern = re.compile(regex)

    for element in data:
        keys = element['definitions'].keys()
        for k in keys:
            if not pattern.fullmatch(k):
                symbols.add(k)

    regex2 = r'\\?([A-Za-z]*?)\s*_.*'
    pattern2 = re.compile(regex2)

    for s in symbols:
        match = pattern2.fullmatch(s)
        if match:
            print("'%s': 'math-%s'," % (s, match.group(1).lower()))
        else:
            print("'%s': ''," % s)
