#!/usr/bin/env python3
"""Generate an xvlog file list for the processor RTL.

    gen_rtl_f.py <rtl_dir> <overrides_file> <output.f>

Collects every *.v under rtl_dir except testbenches (*_tb.v) and board/skeleton wrappers
(Wrapper*.v) - the UVM env instantiates `processor` directly, and Wrapper_timing.v pulls in
Vivado IP that isn't in the repo.

The alu/multdiv/regfile submodules each carry their own copies of shared modules. Copies are
grouped by filename (this assumes one module per file, named after the file):
  - identical copies: the module's home directory (regfile/regfile.v) or else the shallowest
    path is used, silently
  - differing copies: the overrides file must name which one to use, or this exits with an
    error. A note is printed on every build while an override is choosing between differing
    copies, so an edit to the ignored copy can't go unnoticed.

Overrides file format, one per line:  <filename> <path relative to rtl_dir>
"""
import hashlib
import os
import sys
from collections import defaultdict


def read_overrides(path):
    overrides = {}
    if not os.path.exists(path):
        return overrides
    with open(path) as f:
        for lineno, line in enumerate(f, 1):
            line = line.split('#', 1)[0].strip()
            if not line:
                continue
            parts = line.split()
            if len(parts) != 2:
                sys.exit(f"{path}:{lineno}: expected '<filename> <relative path>', got: {line}")
            overrides[parts[0]] = parts[1]
    return overrides


def digest(path):
    with open(path, 'rb') as f:
        return hashlib.md5(f.read()).hexdigest()


def main():
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    rtl_dir, overrides_path, out_path = sys.argv[1:]
    rtl_dir = os.path.abspath(rtl_dir)
    if not os.path.isdir(rtl_dir):
        sys.exit(f"RTL_DIR does not exist: {rtl_dir}")
    overrides = read_overrides(overrides_path)

    copies = defaultdict(list)
    for root, dirs, files in os.walk(rtl_dir):
        dirs[:] = [d for d in dirs if not d.startswith('.') and 'banned' not in d]
        for name in files:
            if name.endswith('.v') and not name.endswith('_tb.v') and not name.startswith('Wrapper'):
                copies[name].append(os.path.join(root, name))

    chosen = []
    errors = []
    for name in sorted(copies, key=str.lower):
        # Prefer a module's home directory (regfile/regfile.v), then the shallowest copy.
        stem = name[:-2]
        paths = sorted(copies[name], key=lambda p: (os.path.basename(os.path.dirname(p)) != stem,
                                                    p.count(os.sep), p))
        distinct = len({digest(p) for p in paths}) > 1
        if name in overrides:
            pick = os.path.join(rtl_dir, overrides[name])
            if pick not in paths:
                errors.append(f"override for {name} points at {overrides[name]}, which is not one of: "
                              + ", ".join(os.path.relpath(p, rtl_dir) for p in paths))
                continue
            if distinct:
                print(f"note: {name} has differing copies; using {overrides[name]} per "
                      f"{os.path.basename(overrides_path)}", file=sys.stderr)
            chosen.append(pick)
        elif distinct:
            errors.append(f"{name} has differing copies, add an override choosing one: "
                          + ", ".join(os.path.relpath(p, rtl_dir) for p in paths))
        else:
            chosen.append(paths[0])

    if errors:
        sys.exit("gen_rtl_f: " + "\ngen_rtl_f: ".join(errors))

    with open(out_path, 'w') as f:
        f.write('\n'.join(chosen) + '\n')


if __name__ == '__main__':
    main()
