#!/usr/bin/env python3
import argparse
import pathlib
import re
import textwrap
import sys

ALIAS_PATTERN = re.compile(r'if \[ "\$OS_FAMILY" = "macos" \]; then\n(?P<mac>.+?)\nelse\n(?P<other>.+?)\nfi', re.S)
LS_PATTERN = re.compile(r'if \[\[ "\$OS_FAMILY" == "macos" \|\| "\$OS_FAMILY" == "darwin" \]\]; then\n(?P<mac>.+?)\nelse\n(?P<other>.+?)\nfi', re.S)
CASE_PATTERN = re.compile(r'case "\$OS_FAMILY" in\n(?P<body>.+?)\n\s*esac', re.S)

OS_SYNONYMS = {
    "macos": {"macos", "darwin"},
    "debian": {"debian", "ubuntu", "pop", "elementary", "linuxmint", "neon", "debian-based"},
    "fedora": {"fedora"},
}

DEFAULT_SYNONYMS = {"macos": "macos", "debian": "debian", "fedora": "fedora"}

def _choose_block(match, target):
    block = match.group('mac') if target == 'macos' else match.group('other')
    block = textwrap.dedent(block)
    return block.rstrip('\n') + '\n'

def trim_zshrc(path, target):
    data = path.read_text()
    data_new = ALIAS_PATTERN.sub(lambda m: _choose_block(m, target), data)
    data_new = LS_PATTERN.sub(lambda m: _choose_block(m, target), data_new)
    path.write_text(data_new.rstrip('\n') + '\n')

def _select_case_branch(body, target):
    segments = [seg for seg in body.split(';;') if seg.strip()]
    selected = None
    default_branch = None
    for seg in segments:
        lines = seg.strip('\n').split('\n')
        if not lines:
            continue
        label_line = lines[0].strip()
        label = label_line.rstrip(')').strip()
        content = textwrap.dedent('\n'.join(lines[1:])).strip('\n')
        tokens = {token.strip() for token in label.split('|') if token.strip()}
        if label == '*':
            default_branch = content
            continue
        synonyms = OS_SYNONYMS.get(target, set())
        if tokens & synonyms:
            selected = content
            break
    if selected is None:
        selected = default_branch
    return (selected or '').strip('\n')

def trim_update_script(path, target):
    text = path.read_text()
    def repl(match):
        body = match.group('body')
        branch = _select_case_branch(body, target)
        if not branch:
            return ''
        lines = branch.split('\n')
        indented = '\n'.join(('  ' + line if line else '') for line in lines)
        return indented + '\n'
    new_text = CASE_PATTERN.sub(repl, text)
    path.write_text(new_text.rstrip('\n') + '\n')

def main():
    parser = argparse.ArgumentParser(description="Render OS-specific files")
    parser.add_argument('--os', required=True, choices=['macos', 'debian', 'fedora'])
    parser.add_argument('--zshrc')
    parser.add_argument('--update')
    args = parser.parse_args()

    if args.zshrc:
        trim_zshrc(pathlib.Path(args.zshrc), args.os)
    if args.update:
        trim_update_script(pathlib.Path(args.update), args.os)

if __name__ == '__main__':
    main()
